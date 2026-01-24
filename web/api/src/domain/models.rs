#[allow(dead_code)]
pub enum HealthStatus {
    Healthy,
    Degraded,
}

impl HealthStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Healthy => "healthy",
            Self::Degraded => "degraded",
        }
    }
}

use chrono::{DateTime, FixedOffset};
use serde::Deserialize;
use serde::Serialize;
use thiserror::Error;

#[derive(Debug, Clone, Serialize)]
pub struct SdzUser {
    #[serde(rename = "userId")]
    pub sdz_user_id: String,
    #[serde(rename = "displayName")]
    pub sdz_display_name: String,
    #[serde(rename = "email")]
    pub sdz_email: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SdzSpotLocation {
    pub lat: f64,
    pub lng: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SdzSpotTimeRange {
    #[serde(rename = "startMinutes")]
    pub start_minutes: u16,
    #[serde(rename = "endMinutes")]
    pub end_minutes: u16,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub enum SdzSpotBusinessScheduleType {
    Regular,
    WeekdayOnly,
    WeekendOnly,
    Irregular,
    SchoolOnly,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SdzSpotBusinessHours {
    #[serde(rename = "scheduleType", skip_serializing_if = "Option::is_none")]
    pub schedule_type: Option<SdzSpotBusinessScheduleType>,
    #[serde(rename = "is24Hours")]
    pub is_24_hours: bool,
    #[serde(rename = "sameAsWeekday")]
    pub same_as_weekday: bool,
    pub weekday: Option<SdzSpotTimeRange>,
    pub weekend: Option<SdzSpotTimeRange>,
    pub note: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SdzSpotParkAttributes {
    #[serde(rename = "officialUrl")]
    pub official_url: Option<String>,
    #[serde(rename = "businessHours")]
    pub business_hours: Option<SdzSpotBusinessHours>,
    #[serde(rename = "accessInfo")]
    pub access_info: Option<String>,
    #[serde(rename = "phoneNumber")]
    pub phone_number: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SdzStreetSurfaceCondition {
    pub roughness: Option<String>,
    pub crack: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SdzStreetSection {
    #[serde(rename = "type")]
    pub section_type: String,
    pub count: Option<u16>,
    #[serde(rename = "heightCm")]
    pub height_cm: Option<u16>,
    #[serde(rename = "widthCm")]
    pub width_cm: Option<u16>,
    pub notes: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SdzStreetAttributes {
    #[serde(rename = "surfaceMaterial")]
    pub surface_material: Option<String>,
    #[serde(rename = "surfaceCondition")]
    pub surface_condition: Option<SdzStreetSurfaceCondition>,
    pub sections: Option<Vec<SdzStreetSection>>,
    pub difficulty: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SdzSpot {
    #[serde(rename = "spotId")]
    pub sdz_spot_id: String,
    pub name: String,
    pub description: Option<String>,
    pub location: Option<SdzSpotLocation>,
    pub tags: Vec<String>,
    pub images: Vec<String>,
    #[serde(rename = "approvalStatus", skip_serializing_if = "Option::is_none")]
    pub sdz_approval_status: Option<SdzSpotApprovalStatus>,
    #[serde(rename = "parkAttributes", skip_serializing_if = "Option::is_none")]
    pub sdz_park_attributes: Option<SdzSpotParkAttributes>,
    #[serde(rename = "streetAttributes", skip_serializing_if = "Option::is_none")]
    pub sdz_street_attributes: Option<SdzStreetAttributes>,
    #[serde(rename = "instagramTag", skip_serializing_if = "Option::is_none")]
    pub sdz_instagram_tag: Option<String>,
    #[serde(rename = "userId")]
    pub sdz_user_id: String,
    #[serde(rename = "createdAt")]
    pub created_at: DateTime<FixedOffset>,
    #[serde(rename = "updatedAt")]
    pub updated_at: DateTime<FixedOffset>,
}

#[derive(Debug, Clone)]
pub struct SdzMyListEntry {
    pub sdz_spot_id: String,
    pub created_at: DateTime<FixedOffset>,
}
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum SdzSpotApprovalStatus {
    Pending,
    Approved,
    Rejected,
}

impl SdzSpot {
    #[allow(clippy::too_many_arguments)]
    pub fn new_with_id(
        sdz_spot_id: String,
        name: String,
        description: Option<String>,
        location: Option<SdzSpotLocation>,
        tags: Vec<String>,
        images: Vec<String>,
        park_attributes: Option<SdzSpotParkAttributes>,
        street_attributes: Option<SdzStreetAttributes>,
        instagram_tag: Option<String>,
        sdz_user_id: String,
    ) -> Result<Self, SdzSpotValidationError> {
        validate_spot(
            &name,
            location.as_ref(),
            &tags,
            &images,
            park_attributes.as_ref(),
            street_attributes.as_ref(),
        )?;
        Ok(Self {
            sdz_spot_id,
            name,
            description,
            location,
            tags,
            images,
            sdz_approval_status: None,
            sdz_park_attributes: park_attributes,
            sdz_street_attributes: street_attributes,
            sdz_instagram_tag: instagram_tag,
            sdz_user_id,
            created_at: now_jst(),
            updated_at: now_jst(),
        })
    }

    pub fn is_approved(&self) -> bool {
        matches!(
            self.sdz_approval_status,
            Some(SdzSpotApprovalStatus::Approved)
        )
    }

    #[allow(clippy::too_many_arguments)]
    pub fn update(
        &self,
        name: String,
        description: Option<String>,
        location: Option<SdzSpotLocation>,
        tags: Vec<String>,
        images: Vec<String>,
        approval_status: Option<SdzSpotApprovalStatus>,
        park_attributes: Option<SdzSpotParkAttributes>,
        street_attributes: Option<SdzStreetAttributes>,
        instagram_tag: Option<String>,
    ) -> Result<Self, SdzSpotValidationError> {
        validate_spot(
            &name,
            location.as_ref(),
            &tags,
            &images,
            park_attributes.as_ref(),
            street_attributes.as_ref(),
        )?;
        Ok(Self {
            sdz_spot_id: self.sdz_spot_id.clone(),
            name,
            description,
            location,
            tags,
            images,
            sdz_approval_status: approval_status,
            sdz_park_attributes: park_attributes,
            sdz_street_attributes: street_attributes,
            sdz_instagram_tag: instagram_tag,
            sdz_user_id: self.sdz_user_id.clone(),
            created_at: self.created_at,
            updated_at: now_jst(),
        })
    }
}

fn validate_spot(
    name: &str,
    location: Option<&SdzSpotLocation>,
    tags: &[String],
    images: &[String],
    park_attributes: Option<&SdzSpotParkAttributes>,
    street_attributes: Option<&SdzStreetAttributes>,
) -> Result<(), SdzSpotValidationError> {
    if name.trim().is_empty() {
        return Err(SdzSpotValidationError::NameIsRequired);
    }
    if let Some(loc) = location {
        if !(loc.lat >= -90.0 && loc.lat <= 90.0) {
            return Err(SdzSpotValidationError::InvalidLatitude);
        }
        if !(loc.lng >= -180.0 && loc.lng <= 180.0) {
            return Err(SdzSpotValidationError::InvalidLongitude);
        }
    }
    if tags.len() > 10 {
        return Err(SdzSpotValidationError::TooManyTags);
    }
    if images.len() > SDZ_MAX_IMAGES_PER_SPOT {
        return Err(SdzSpotValidationError::TooManyImages);
    }
    if let Some(attrs) = park_attributes {
        if let Some(hours) = &attrs.business_hours {
            validate_business_hours(hours)?;
        }
    }
    if let Some(attrs) = street_attributes {
        if let Some(sections) = &attrs.sections {
            for section in sections {
                if section.section_type.trim().is_empty() {
                    return Err(SdzSpotValidationError::InvalidStreetSection);
                }
            }
        }
    }
    Ok(())
}

fn now_jst() -> DateTime<FixedOffset> {
    // 日本標準時（UTC+9）でタイムスタンプを付与
    let offset = FixedOffset::east_opt(9 * 3600).expect("valid offset");
    chrono::Utc::now().with_timezone(&offset)
}

#[derive(Debug, Error)]
pub enum SdzSpotValidationError {
    #[error("name is required")]
    NameIsRequired,
    #[error("lat must be between -90 and 90")]
    InvalidLatitude,
    #[error("lng must be between -180 and 180")]
    InvalidLongitude,
    #[error("tags must be <= 10 items")]
    TooManyTags,
    #[error("images must be <= 3 items")]
    TooManyImages,
    #[error("business hours are invalid")]
    InvalidBusinessHours,
    #[error("street section type is required")]
    InvalidStreetSection,
}

const SDZ_MAX_IMAGES_PER_SPOT: usize = 3;

fn validate_business_hours(hours: &SdzSpotBusinessHours) -> Result<(), SdzSpotValidationError> {
    let schedule_type = hours
        .schedule_type
        .clone()
        .unwrap_or(SdzSpotBusinessScheduleType::Regular);

    match schedule_type {
        SdzSpotBusinessScheduleType::Regular => {
            if hours.is_24_hours {
                return Ok(());
            }
            if let Some(weekday) = hours.weekday.as_ref() {
                validate_time_range(weekday)?;
            } else {
                return Err(SdzSpotValidationError::InvalidBusinessHours);
            }
            if !hours.same_as_weekday {
                if let Some(weekend) = hours.weekend.as_ref() {
                    validate_time_range(weekend)?;
                } else {
                    return Err(SdzSpotValidationError::InvalidBusinessHours);
                }
            }
            Ok(())
        }
        SdzSpotBusinessScheduleType::WeekdayOnly => {
            if hours.is_24_hours {
                return Ok(());
            }
            if let Some(weekday) = hours.weekday.as_ref() {
                validate_time_range(weekday)?;
                Ok(())
            } else {
                Err(SdzSpotValidationError::InvalidBusinessHours)
            }
        }
        SdzSpotBusinessScheduleType::WeekendOnly => {
            if hours.is_24_hours {
                return Ok(());
            }
            if let Some(weekend) = hours.weekend.as_ref() {
                validate_time_range(weekend)?;
                Ok(())
            } else {
                Err(SdzSpotValidationError::InvalidBusinessHours)
            }
        }
        SdzSpotBusinessScheduleType::Irregular | SdzSpotBusinessScheduleType::SchoolOnly => {
            if hours
                .note
                .as_ref()
                .map(|note| !note.trim().is_empty())
                .unwrap_or(false)
            {
                Ok(())
            } else {
                Err(SdzSpotValidationError::InvalidBusinessHours)
            }
        }
    }
}

fn validate_time_range(range: &SdzSpotTimeRange) -> Result<(), SdzSpotValidationError> {
    if range.start_minutes >= range.end_minutes {
        return Err(SdzSpotValidationError::InvalidBusinessHours);
    }
    if range.end_minutes > 24 * 60 {
        return Err(SdzSpotValidationError::InvalidBusinessHours);
    }
    Ok(())
}
