use async_trait::async_trait;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map};

use crate::{
    application::use_cases::spot_repository::SdzSpotRepository,
    domain::models::{
        SdzSpot, SdzSpotApprovalStatus, SdzSpotBusinessHours, SdzSpotBusinessScheduleType,
        SdzSpotLocation, SdzSpotParkAttributes, SdzSpotTimeRange, SdzStreetAttributes,
        SdzStreetSection, SdzStreetSurfaceCondition,
    },
    presentation::error::SdzApiError,
};

pub struct SdzFirestoreSpotRepository {
    project_id: String,
    bearer_token: Option<String>,
    http: Client,
}

impl SdzFirestoreSpotRepository {
    pub fn new(project_id: String, bearer_token: Option<String>) -> Result<Self, SdzApiError> {
        let http = Client::builder().build().map_err(|e| {
            tracing::error!("Failed to build reqwest client: {:?}", e);
            SdzApiError::Internal
        })?;
        Ok(Self {
            project_id,
            bearer_token,
            http,
        })
    }

    async fn upsert_document(&self, spot: &SdzSpot) -> Result<(), SdzApiError> {
        let url = format!(
            "https://firestore.googleapis.com/v1/projects/{}/databases/(default)/documents/spots/{}",
            self.project_id, spot.sdz_spot_id
        );

        let body = build_firestore_doc(spot)?;
        let token = self.resolve_token().await?;

        let resp = self
            .http
            .patch(url)
            .bearer_auth(token)
            .json(&body)
            .send()
            .await
            .map_err(|e| {
                tracing::error!("Firestore request error: {:?}", e);
                SdzApiError::Internal
            })?;

        map_status(resp.status(), resp.text().await).map(|_| ())
    }

    async fn get_document(&self, spot_id: &str) -> Result<Option<FirestoreSpotDoc>, SdzApiError> {
        let url = format!(
            "https://firestore.googleapis.com/v1/projects/{}/databases/(default)/documents/spots/{}",
            self.project_id, spot_id
        );
        let token = self.resolve_token().await?;
        let resp = self
            .http
            .get(url)
            .bearer_auth(token)
            .send()
            .await
            .map_err(|e| {
                tracing::error!("Firestore request error: {:?}", e);
                SdzApiError::Internal
            })?;

        match resp.status() {
            reqwest::StatusCode::OK => {
                let doc = resp.json::<FirestoreSpotDoc>().await.map_err(|e| {
                    tracing::error!("Failed to parse Firestore response: {:?}", e);
                    SdzApiError::Internal
                })?;
                Ok(Some(doc))
            }
            reqwest::StatusCode::NOT_FOUND => Ok(None),
            code => {
                let body = resp.text().await.unwrap_or_default();
                tracing::error!("Firestore unexpected status: {} body: {}", code, body);
                Err(SdzApiError::Internal)
            }
        }
    }

    async fn list_by_user(&self, user_id: &str) -> Result<Vec<SdzSpot>, SdzApiError> {
        let url = format!(
            "https://firestore.googleapis.com/v1/projects/{}/databases/(default)/documents:runQuery",
            self.project_id
        );

        let body = json!({
            "structuredQuery": {
                "from": [{ "collectionId": "spots" }],
                "where": {
                    "fieldFilter": {
                        "field": { "fieldPath": "userId" },
                        "op": "EQUAL",
                        "value": { "stringValue": user_id }
                    }
                }
            }
        });

        let token = self.resolve_token().await?;
        let resp = self
            .http
            .post(url)
            .bearer_auth(token)
            .json(&body)
            .send()
            .await
            .map_err(|e| {
                tracing::error!("Firestore runQuery request error: {:?}", e);
                SdzApiError::Internal
            })?;

        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            tracing::error!(
                "Firestore runQuery unexpected status {} body: {}",
                status,
                text
            );
            return Err(SdzApiError::Internal);
        }

        let rows = resp
            .json::<Vec<FirestoreRunQueryResponse>>()
            .await
            .map_err(|e| {
                tracing::error!("Failed to parse Firestore runQuery response: {:?}", e);
                SdzApiError::Internal
            })?;

        let mut spots = Vec::new();
        for row in rows {
            if let Some(doc) = row.document {
                if let Some(spot_id) = extract_doc_id(&doc.name) {
                    spots.push(doc.into_spot(spot_id));
                }
            }
        }
        Ok(spots)
    }

    async fn resolve_token(&self) -> Result<String, SdzApiError> {
        if let Some(token) = self
            .bearer_token
            .as_ref()
            .filter(|token| !token.trim().is_empty())
        {
            return Ok(token.to_string());
        }
        if let Ok(token) = std::env::var("SDZ_FIRESTORE_TOKEN") {
            if !token.trim().is_empty() {
                return Ok(token);
            }
        }
        self.fetch_metadata_token().await
    }

    async fn fetch_metadata_token(&self) -> Result<String, SdzApiError> {
        let metadata_url = "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token";
        let resp = self
            .http
            .get(metadata_url)
            .header("Metadata-Flavor", "Google")
            .send()
            .await
            .map_err(|e| {
                tracing::error!("Failed to fetch metadata token: {:?}", e);
                SdzApiError::Internal
            })?;

        if !resp.status().is_success() {
            let body = resp.text().await.unwrap_or_default();
            tracing::error!("Metadata token error: {}", body);
            return Err(SdzApiError::Internal);
        }

        let token = resp.json::<SdzMetadataToken>().await.map_err(|e| {
            tracing::error!("Failed to parse metadata token: {:?}", e);
            SdzApiError::Internal
        })?;

        Ok(token.access_token)
    }
}

#[async_trait]
impl SdzSpotRepository for SdzFirestoreSpotRepository {
    async fn create(&self, spot: SdzSpot) -> Result<SdzSpot, SdzApiError> {
        self.upsert_document(&spot).await?;
        Ok(spot)
    }

    async fn find_by_id(&self, spot_id: &str) -> Result<Option<SdzSpot>, SdzApiError> {
        let Some(doc) = self.get_document(spot_id).await? else {
            return Ok(None);
        };

        Ok(Some(doc.into_spot(spot_id.to_string())))
    }

    async fn list_recent(&self, _limit: usize) -> Result<Vec<SdzSpot>, SdzApiError> {
        let limit = _limit.min(100) as i32;
        let url = format!(
            "https://firestore.googleapis.com/v1/projects/{}/databases/(default)/documents:runQuery",
            self.project_id
        );

        let body = json!({
            "structuredQuery": {
                "from": [{ "collectionId": "spots" }],
                "orderBy": [{
                    "field": { "fieldPath": "createdAt" },
                    "direction": "DESCENDING"
                }],
                "limit": limit
            }
        });

        let token = self.resolve_token().await?;
        let resp = self
            .http
            .post(url)
            .bearer_auth(token)
            .json(&body)
            .send()
            .await
            .map_err(|e| {
                tracing::error!("Firestore runQuery request error: {:?}", e);
                SdzApiError::Internal
            })?;

        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            tracing::error!(
                "Firestore runQuery unexpected status {} body: {}",
                status,
                text
            );
            return Err(SdzApiError::Internal);
        }

        let rows = resp
            .json::<Vec<FirestoreRunQueryResponse>>()
            .await
            .map_err(|e| {
                tracing::error!("Failed to parse Firestore runQuery response: {:?}", e);
                SdzApiError::Internal
            })?;

        let mut spots = Vec::new();
        for row in rows {
            if let Some(doc) = row.document {
                if let Some(spot_id) = extract_doc_id(&doc.name) {
                    spots.push(doc.into_spot(spot_id));
                }
            }
        }
        Ok(spots)
    }

    async fn count_image_spots_by_user(&self, user_id: &str) -> Result<usize, SdzApiError> {
        let spots = self.list_by_user(user_id).await?;
        Ok(spots
            .into_iter()
            .filter(|spot| !spot.images.is_empty())
            .count())
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreSpotDoc {
    fields: FirestoreSpotFields,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreSpotFields {
    name: Option<StringField>,
    description: Option<StringField>,
    #[serde(rename = "userId")]
    user_id: Option<StringField>,
    tags: Option<ArrayField>,
    images: Option<ArrayField>,
    #[serde(rename = "approvalStatus")]
    approval_status: Option<StringField>,
    #[serde(rename = "trustLevel")]
    legacy_trust_level: Option<StringField>,
    #[serde(rename = "parkAttributes")]
    park_attributes: Option<FirestoreParkAttributesField>,
    #[serde(rename = "streetAttributes")]
    street_attributes: Option<FirestoreStreetAttributesField>,
    #[serde(rename = "instagramTag")]
    instagram_tag: Option<StringField>,
    location: Option<MapField>,
    #[serde(rename = "createdAt")]
    created_at: Option<TimestampField>,
    #[serde(rename = "updatedAt")]
    updated_at: Option<TimestampField>,
}

#[derive(Debug, Serialize, Deserialize)]
struct StringField {
    #[serde(rename = "stringValue")]
    string_value: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct DoubleField {
    #[serde(rename = "doubleValue")]
    double_value: f64,
}

#[derive(Debug, Serialize, Deserialize)]
struct BooleanField {
    #[serde(rename = "booleanValue")]
    boolean_value: bool,
}

#[derive(Debug, Serialize, Deserialize)]
struct IntegerField {
    #[serde(rename = "integerValue")]
    integer_value: String,
}

#[derive(Debug, Deserialize)]
struct SdzMetadataToken {
    #[serde(rename = "access_token")]
    access_token: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct ArrayField {
    #[serde(rename = "arrayValue")]
    array_value: ArrayValue,
}

#[derive(Debug, Serialize, Deserialize)]
struct ArrayValue {
    values: Option<Vec<StringField>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct MapField {
    #[serde(rename = "mapValue")]
    map_value: MapValue,
}

#[derive(Debug, Serialize, Deserialize)]
struct MapValue {
    fields: Option<FirestoreLocationFields>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreLocationFields {
    lat: Option<DoubleField>,
    lng: Option<DoubleField>,
}

#[derive(Debug, Serialize, Deserialize)]
struct TimestampField {
    #[serde(rename = "timestampValue")]
    timestamp_value: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreParkAttributesField {
    #[serde(rename = "mapValue")]
    map_value: FirestoreParkAttributesMap,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreParkAttributesMap {
    fields: Option<FirestoreParkAttributesFields>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreParkAttributesFields {
    #[serde(rename = "officialUrl")]
    official_url: Option<StringField>,
    #[serde(rename = "businessHours")]
    business_hours: Option<FirestoreBusinessHoursField>,
    #[serde(rename = "accessInfo")]
    access_info: Option<StringField>,
    #[serde(rename = "phoneNumber")]
    phone_number: Option<StringField>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreBusinessHoursField {
    #[serde(rename = "mapValue")]
    map_value: FirestoreBusinessHoursMap,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreBusinessHoursMap {
    fields: Option<FirestoreBusinessHoursFields>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreBusinessHoursFields {
    #[serde(rename = "scheduleType")]
    schedule_type: Option<StringField>,
    #[serde(rename = "is24Hours")]
    is_24_hours: Option<BooleanField>,
    #[serde(rename = "sameAsWeekday")]
    same_as_weekday: Option<BooleanField>,
    weekday: Option<FirestoreTimeRangeField>,
    weekend: Option<FirestoreTimeRangeField>,
    note: Option<StringField>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreTimeRangeField {
    #[serde(rename = "mapValue")]
    map_value: FirestoreTimeRangeMap,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreTimeRangeMap {
    fields: Option<FirestoreTimeRangeFields>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreTimeRangeFields {
    #[serde(rename = "startMinutes")]
    start_minutes: Option<IntegerField>,
    #[serde(rename = "endMinutes")]
    end_minutes: Option<IntegerField>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetAttributesField {
    #[serde(rename = "mapValue")]
    map_value: FirestoreStreetAttributesMap,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetAttributesMap {
    fields: Option<FirestoreStreetAttributesFields>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetAttributesFields {
    #[serde(rename = "surfaceMaterial")]
    surface_material: Option<StringField>,
    #[serde(rename = "surfaceCondition")]
    surface_condition: Option<FirestoreStreetSurfaceConditionField>,
    sections: Option<FirestoreStreetSectionsField>,
    difficulty: Option<StringField>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetSurfaceConditionField {
    #[serde(rename = "mapValue")]
    map_value: FirestoreStreetSurfaceConditionMap,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetSurfaceConditionMap {
    fields: Option<FirestoreStreetSurfaceConditionFields>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetSurfaceConditionFields {
    roughness: Option<StringField>,
    crack: Option<StringField>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetSectionsField {
    #[serde(rename = "arrayValue")]
    array_value: FirestoreStreetSectionsArray,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetSectionsArray {
    values: Option<Vec<FirestoreStreetSectionField>>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetSectionField {
    #[serde(rename = "mapValue")]
    map_value: FirestoreStreetSectionMap,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetSectionMap {
    fields: Option<FirestoreStreetSectionFields>,
}

#[derive(Debug, Serialize, Deserialize)]
struct FirestoreStreetSectionFields {
    #[serde(rename = "type")]
    section_type: Option<StringField>,
    count: Option<IntegerField>,
    #[serde(rename = "heightCm")]
    height_cm: Option<IntegerField>,
    #[serde(rename = "widthCm")]
    width_cm: Option<IntegerField>,
    notes: Option<StringField>,
}

impl FirestoreSpotDoc {
    fn into_spot(self, spot_id: String) -> SdzSpot {
        let fields = self.fields;
        let tags = fields
            .tags
            .and_then(|f| f.array_value.values)
            .unwrap_or_default()
            .into_iter()
            .map(|v| v.string_value)
            .collect();
        let images = fields
            .images
            .and_then(|f| f.array_value.values)
            .unwrap_or_default()
            .into_iter()
            .map(|v| v.string_value)
            .collect();
        let location = fields.location.and_then(|loc| {
            let mv = loc.map_value.fields?;
            let lat = mv.lat?.double_value;
            let lng = mv.lng?.double_value;
            Some(SdzSpotLocation { lat, lng })
        });
        let created_at = parse_timestamp(fields.created_at.map(|t| t.timestamp_value))
            .unwrap_or_else(|| chrono::Utc::now().into());
        let updated_at = parse_timestamp(fields.updated_at.map(|t| t.timestamp_value))
            .unwrap_or_else(|| chrono::Utc::now().into());

        SdzSpot {
            sdz_spot_id: spot_id,
            name: fields
                .name
                .map(|s| s.string_value)
                .unwrap_or_else(|| "unknown".into()),
            description: fields.description.map(|s| s.string_value),
            location,
            tags,
            images,
            sdz_approval_status: parse_approval_status(
                fields.approval_status.map(|s| s.string_value),
                fields.legacy_trust_level.map(|s| s.string_value),
            ),
            sdz_park_attributes: fields
                .park_attributes
                .and_then(|attrs| attrs.into_attributes()),
            sdz_street_attributes: fields
                .street_attributes
                .and_then(|attrs| attrs.into_attributes()),
            sdz_instagram_tag: fields.instagram_tag.map(|s| s.string_value),
            sdz_user_id: fields.user_id.map(|s| s.string_value).unwrap_or_default(),
            created_at,
            updated_at,
        }
    }
}

impl FirestoreParkAttributesField {
    fn into_attributes(self) -> Option<SdzSpotParkAttributes> {
        let fields = self.map_value.fields?;
        let official_url = fields.official_url.map(|f| f.string_value);
        let business_hours = fields
            .business_hours
            .and_then(|hours| hours.into_business_hours());
        let access_info = fields.access_info.map(|f| f.string_value);
        let phone_number = fields.phone_number.map(|f| f.string_value);

        if official_url.is_none()
            && business_hours.is_none()
            && access_info.is_none()
            && phone_number.is_none()
        {
            return None;
        }

        Some(SdzSpotParkAttributes {
            official_url,
            business_hours,
            access_info,
            phone_number,
        })
    }
}

impl FirestoreBusinessHoursField {
    fn into_business_hours(self) -> Option<SdzSpotBusinessHours> {
        let fields = self.map_value.fields?;
        let schedule_type = fields
            .schedule_type
            .and_then(|field| parse_schedule_type(field.string_value));
        let note = fields.note.map(|field| field.string_value);
        let has_any = fields.is_24_hours.is_some()
            || fields.same_as_weekday.is_some()
            || fields.weekday.is_some()
            || fields.weekend.is_some()
            || schedule_type.is_some()
            || note.is_some();
        let is_24_hours = fields
            .is_24_hours
            .map(|field| field.boolean_value)
            .unwrap_or(false);
        let same_as_weekday = fields
            .same_as_weekday
            .map(|field| field.boolean_value)
            .unwrap_or(true);
        let weekday = fields.weekday.and_then(|range| range.into_time_range());
        let weekend = fields.weekend.and_then(|range| range.into_time_range());

        if !has_any {
            return None;
        }

        Some(SdzSpotBusinessHours {
            schedule_type,
            is_24_hours,
            same_as_weekday,
            weekday,
            weekend,
            note,
        })
    }
}

impl FirestoreTimeRangeField {
    fn into_time_range(self) -> Option<SdzSpotTimeRange> {
        let fields = self.map_value.fields?;
        let start_minutes = parse_integer(fields.start_minutes)?;
        let end_minutes = parse_integer(fields.end_minutes)?;
        Some(SdzSpotTimeRange {
            start_minutes,
            end_minutes,
        })
    }
}

impl FirestoreStreetAttributesField {
    fn into_attributes(self) -> Option<SdzStreetAttributes> {
        let fields = self.map_value.fields?;
        let surface_material = fields.surface_material.map(|f| f.string_value);
        let surface_condition = fields
            .surface_condition
            .and_then(|condition| condition.into_condition());
        let sections = fields
            .sections
            .and_then(|sections| sections.into_sections());
        let difficulty = fields.difficulty.map(|f| f.string_value);

        if surface_material.is_none()
            && surface_condition.is_none()
            && sections.is_none()
            && difficulty.is_none()
        {
            return None;
        }

        Some(SdzStreetAttributes {
            surface_material,
            surface_condition,
            sections,
            difficulty,
        })
    }
}

impl FirestoreStreetSurfaceConditionField {
    fn into_condition(self) -> Option<SdzStreetSurfaceCondition> {
        let fields = self.map_value.fields?;
        let roughness = fields.roughness.map(|f| f.string_value);
        let crack = fields.crack.map(|f| f.string_value);

        if roughness.is_none() && crack.is_none() {
            return None;
        }

        Some(SdzStreetSurfaceCondition { roughness, crack })
    }
}

impl FirestoreStreetSectionsField {
    fn into_sections(self) -> Option<Vec<SdzStreetSection>> {
        let values = self.array_value.values?;
        let sections: Vec<SdzStreetSection> = values
            .into_iter()
            .filter_map(|value| value.into_section())
            .collect();
        if sections.is_empty() {
            return None;
        }
        Some(sections)
    }
}

impl FirestoreStreetSectionField {
    fn into_section(self) -> Option<SdzStreetSection> {
        let fields = self.map_value.fields?;
        let section_type = fields.section_type.map(|f| f.string_value)?;
        Some(SdzStreetSection {
            section_type,
            count: parse_integer(fields.count),
            height_cm: parse_integer(fields.height_cm),
            width_cm: parse_integer(fields.width_cm),
            notes: fields.notes.map(|f| f.string_value),
        })
    }
}

fn parse_integer(field: Option<IntegerField>) -> Option<u16> {
    field.and_then(|f| f.integer_value.parse::<u16>().ok())
}

fn build_firestore_doc(spot: &SdzSpot) -> Result<serde_json::Value, SdzApiError> {
    let tags_values: Vec<serde_json::Value> = spot
        .tags
        .iter()
        .map(|t| json!({ "stringValue": t }))
        .collect();
    let images_values: Vec<serde_json::Value> = spot
        .images
        .iter()
        .map(|i| json!({ "stringValue": i }))
        .collect();

    let mut fields = Map::new();
    fields.insert("name".into(), json!({ "stringValue": spot.name.clone() }));
    if let Some(desc) = &spot.description {
        fields.insert("description".into(), json!({ "stringValue": desc }));
    }
    fields.insert(
        "userId".into(),
        json!({ "stringValue": spot.sdz_user_id.clone() }),
    );
    if !tags_values.is_empty() {
        fields.insert(
            "tags".into(),
            json!({ "arrayValue": { "values": tags_values } }),
        );
    }
    if !images_values.is_empty() {
        fields.insert(
            "images".into(),
            json!({ "arrayValue": { "values": images_values } }),
        );
    }
    if let Some(status) = &spot.sdz_approval_status {
        fields.insert(
            "approvalStatus".into(),
            json!({ "stringValue": approval_status_as_str(status) }),
        );
    }
    if let Some(attrs) = &spot.sdz_park_attributes {
        if let Some(value) = build_park_attributes(attrs) {
            fields.insert("parkAttributes".into(), value);
        }
    }
    if let Some(attrs) = &spot.sdz_street_attributes {
        if let Some(value) = build_street_attributes(attrs) {
            fields.insert("streetAttributes".into(), value);
        }
    }
    if let Some(tag) = &spot.sdz_instagram_tag {
        fields.insert("instagramTag".into(), json!({ "stringValue": tag }));
    }
    if let Some(loc) = &spot.location {
        fields.insert(
            "location".into(),
            json!({
                "mapValue": {
                    "fields": {
                        "lat": { "doubleValue": loc.lat },
                        "lng": { "doubleValue": loc.lng }
                    }
                }
            }),
        );
    }
    fields.insert(
        "createdAt".into(),
        json!({ "timestampValue": spot.created_at.to_rfc3339() }),
    );
    fields.insert(
        "updatedAt".into(),
        json!({ "timestampValue": spot.updated_at.to_rfc3339() }),
    );

    Ok(json!({ "fields": fields }))
}

fn build_park_attributes(attrs: &SdzSpotParkAttributes) -> Option<serde_json::Value> {
    let mut fields = Map::new();
    if let Some(url) = &attrs.official_url {
        fields.insert("officialUrl".into(), string_value(url));
    }
    if let Some(hours) = &attrs.business_hours {
        fields.insert("businessHours".into(), build_business_hours(hours));
    }
    if let Some(access_info) = &attrs.access_info {
        fields.insert("accessInfo".into(), string_value(access_info));
    }
    if let Some(phone) = &attrs.phone_number {
        fields.insert("phoneNumber".into(), string_value(phone));
    }
    if fields.is_empty() {
        return None;
    }
    Some(map_value(fields))
}

fn build_business_hours(hours: &SdzSpotBusinessHours) -> serde_json::Value {
    let mut fields = Map::new();
    if let Some(schedule_type) = &hours.schedule_type {
        fields.insert(
            "scheduleType".into(),
            string_value(schedule_type_as_str(schedule_type)),
        );
    }
    fields.insert("is24Hours".into(), bool_value(hours.is_24_hours));
    fields.insert("sameAsWeekday".into(), bool_value(hours.same_as_weekday));
    if let Some(weekday) = &hours.weekday {
        fields.insert("weekday".into(), build_time_range(weekday));
    }
    if let Some(weekend) = &hours.weekend {
        fields.insert("weekend".into(), build_time_range(weekend));
    }
    if let Some(note) = &hours.note {
        fields.insert("note".into(), string_value(note));
    }
    map_value(fields)
}

fn build_time_range(range: &SdzSpotTimeRange) -> serde_json::Value {
    let mut fields = Map::new();
    fields.insert("startMinutes".into(), integer_value(range.start_minutes));
    fields.insert("endMinutes".into(), integer_value(range.end_minutes));
    map_value(fields)
}

fn build_street_attributes(attrs: &SdzStreetAttributes) -> Option<serde_json::Value> {
    let mut fields = Map::new();
    if let Some(surface_material) = &attrs.surface_material {
        fields.insert("surfaceMaterial".into(), string_value(surface_material));
    }
    if let Some(condition) = &attrs.surface_condition {
        if let Some(value) = build_surface_condition(condition) {
            fields.insert("surfaceCondition".into(), value);
        }
    }
    if let Some(sections) = &attrs.sections {
        if let Some(value) = build_sections(sections) {
            fields.insert("sections".into(), value);
        }
    }
    if let Some(difficulty) = &attrs.difficulty {
        fields.insert("difficulty".into(), string_value(difficulty));
    }
    if fields.is_empty() {
        return None;
    }
    Some(map_value(fields))
}

fn build_surface_condition(condition: &SdzStreetSurfaceCondition) -> Option<serde_json::Value> {
    let mut fields = Map::new();
    if let Some(roughness) = &condition.roughness {
        fields.insert("roughness".into(), string_value(roughness));
    }
    if let Some(crack) = &condition.crack {
        fields.insert("crack".into(), string_value(crack));
    }
    if fields.is_empty() {
        return None;
    }
    Some(map_value(fields))
}

fn build_sections(sections: &[SdzStreetSection]) -> Option<serde_json::Value> {
    let values: Vec<serde_json::Value> = sections.iter().filter_map(build_section).collect();
    if values.is_empty() {
        return None;
    }
    Some(json!({ "arrayValue": { "values": values } }))
}

fn build_section(section: &SdzStreetSection) -> Option<serde_json::Value> {
    if section.section_type.trim().is_empty() {
        return None;
    }
    let mut fields = Map::new();
    fields.insert("type".into(), string_value(&section.section_type));
    if let Some(count) = section.count {
        fields.insert("count".into(), integer_value(count));
    }
    if let Some(height) = section.height_cm {
        fields.insert("heightCm".into(), integer_value(height));
    }
    if let Some(width) = section.width_cm {
        fields.insert("widthCm".into(), integer_value(width));
    }
    if let Some(notes) = &section.notes {
        fields.insert("notes".into(), string_value(notes));
    }
    Some(map_value(fields))
}

fn map_value(fields: Map<String, serde_json::Value>) -> serde_json::Value {
    json!({ "mapValue": { "fields": fields } })
}

fn string_value(value: &str) -> serde_json::Value {
    json!({ "stringValue": value })
}

fn bool_value(value: bool) -> serde_json::Value {
    json!({ "booleanValue": value })
}

fn integer_value(value: u16) -> serde_json::Value {
    json!({ "integerValue": value.to_string() })
}

fn parse_timestamp(ts: Option<String>) -> Option<chrono::DateTime<chrono::FixedOffset>> {
    ts.and_then(|s| chrono::DateTime::parse_from_rfc3339(&s).ok())
}

fn parse_approval_status(
    approval_status: Option<String>,
    legacy_trust_level: Option<String>,
) -> Option<SdzSpotApprovalStatus> {
    if let Some(value) = approval_status {
        return match value.as_str() {
            "pending" => Some(SdzSpotApprovalStatus::Pending),
            "approved" => Some(SdzSpotApprovalStatus::Approved),
            "rejected" => Some(SdzSpotApprovalStatus::Rejected),
            _ => None,
        };
    }
    match legacy_trust_level.as_deref() {
        Some("verified") => Some(SdzSpotApprovalStatus::Approved),
        _ => None,
    }
}

fn parse_schedule_type(value: String) -> Option<SdzSpotBusinessScheduleType> {
    match value.as_str() {
        "regular" => Some(SdzSpotBusinessScheduleType::Regular),
        "weekdayOnly" => Some(SdzSpotBusinessScheduleType::WeekdayOnly),
        "weekendOnly" => Some(SdzSpotBusinessScheduleType::WeekendOnly),
        "irregular" => Some(SdzSpotBusinessScheduleType::Irregular),
        "schoolOnly" => Some(SdzSpotBusinessScheduleType::SchoolOnly),
        _ => None,
    }
}

fn approval_status_as_str(status: &SdzSpotApprovalStatus) -> &'static str {
    match status {
        SdzSpotApprovalStatus::Pending => "pending",
        SdzSpotApprovalStatus::Approved => "approved",
        SdzSpotApprovalStatus::Rejected => "rejected",
    }
}

fn schedule_type_as_str(schedule_type: &SdzSpotBusinessScheduleType) -> &'static str {
    match schedule_type {
        SdzSpotBusinessScheduleType::Regular => "regular",
        SdzSpotBusinessScheduleType::WeekdayOnly => "weekdayOnly",
        SdzSpotBusinessScheduleType::WeekendOnly => "weekendOnly",
        SdzSpotBusinessScheduleType::Irregular => "irregular",
        SdzSpotBusinessScheduleType::SchoolOnly => "schoolOnly",
    }
}

fn map_status(
    status: reqwest::StatusCode,
    body: Result<String, reqwest::Error>,
) -> Result<(), SdzApiError> {
    match status {
        reqwest::StatusCode::OK | reqwest::StatusCode::CREATED => Ok(()),
        reqwest::StatusCode::BAD_REQUEST => {
            tracing::error!("Firestore returned 400: {:?}", body);
            Err(SdzApiError::BadRequest("invalid data for Firestore".into()))
        }
        reqwest::StatusCode::UNAUTHORIZED | reqwest::StatusCode::FORBIDDEN => {
            tracing::error!("Firestore returned auth error: {:?}", body);
            Err(SdzApiError::Unauthorized)
        }
        reqwest::StatusCode::NOT_FOUND => Err(SdzApiError::NotFound),
        code => {
            let text = body.unwrap_or_default();
            tracing::error!("Firestore unexpected status {} body: {}", code, text);
            Err(SdzApiError::Internal)
        }
    }
}

#[derive(Debug, Deserialize)]
struct FirestoreRunQueryResponse {
    document: Option<FirestoreSpotDocWithName>,
}

#[derive(Debug, Deserialize)]
struct FirestoreSpotDocWithName {
    name: String,
    fields: FirestoreSpotFields,
}

impl FirestoreSpotDocWithName {
    fn into_spot(self, spot_id: String) -> SdzSpot {
        let doc = FirestoreSpotDoc {
            fields: self.fields,
        };
        doc.into_spot(spot_id)
    }
}

fn extract_doc_id(name: &str) -> Option<String> {
    name.split('/').next_back().map(|s| s.to_owned())
}
