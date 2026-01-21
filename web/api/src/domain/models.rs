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
    pub fn new_with_id(
        sdz_spot_id: String,
        name: String,
        description: Option<String>,
        location: Option<SdzSpotLocation>,
        tags: Vec<String>,
        images: Vec<String>,
        sdz_user_id: String,
    ) -> Result<Self, SdzSpotValidationError> {
        validate_spot(&name, location.as_ref(), &tags, &images)?;
        Ok(Self {
            sdz_spot_id,
            name,
            description,
            location,
            tags,
            images,
            sdz_approval_status: None,
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

    pub fn update(
        &self,
        name: String,
        description: Option<String>,
        location: Option<SdzSpotLocation>,
        tags: Vec<String>,
        images: Vec<String>,
        approval_status: Option<SdzSpotApprovalStatus>,
    ) -> Result<Self, SdzSpotValidationError> {
        validate_spot(&name, location.as_ref(), &tags, &images)?;
        Ok(Self {
            sdz_spot_id: self.sdz_spot_id.clone(),
            name,
            description,
            location,
            tags,
            images,
            sdz_approval_status: approval_status,
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
    if images.len() > 10 {
        return Err(SdzSpotValidationError::TooManyImages);
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
    #[error("images must be <= 10 items")]
    TooManyImages,
}
