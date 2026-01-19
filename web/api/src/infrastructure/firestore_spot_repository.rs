use async_trait::async_trait;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use serde_json::{json, Map};

use crate::{
    application::use_cases::spot_repository::SdzSpotRepository,
    domain::models::{SdzSpot, SdzSpotApprovalStatus, SdzSpotLocation},
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
            sdz_user_id: fields.user_id.map(|s| s.string_value).unwrap_or_default(),
            created_at,
            updated_at,
        }
    }
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

fn approval_status_as_str(status: &SdzSpotApprovalStatus) -> &'static str {
    match status {
        SdzSpotApprovalStatus::Pending => "pending",
        SdzSpotApprovalStatus::Approved => "approved",
        SdzSpotApprovalStatus::Rejected => "rejected",
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
