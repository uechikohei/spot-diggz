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
    #[serde(rename = "trustLevel")]
    pub sdz_trust_level: SdzSpotTrustLevel,
    #[serde(rename = "trustSources")]
    pub sdz_trust_sources: Vec<String>,
    #[serde(rename = "spotType", skip_serializing_if = "Option::is_none")]
    pub sdz_spot_type: Option<SdzSpotType>,
    #[serde(rename = "instagramUrl", skip_serializing_if = "Option::is_none")]
    pub sdz_instagram_url: Option<String>,
    #[serde(rename = "officialUrl", skip_serializing_if = "Option::is_none")]
    pub sdz_official_url: Option<String>,
    #[serde(rename = "businessHours", skip_serializing_if = "Option::is_none")]
    pub sdz_business_hours: Option<String>,
    #[serde(rename = "sections", default)]
    pub sdz_sections: Vec<String>,
    #[serde(rename = "userId")]
    pub sdz_user_id: String,
    #[serde(rename = "createdAt")]
    pub created_at: DateTime<FixedOffset>,
    #[serde(rename = "updatedAt")]
    pub updated_at: DateTime<FixedOffset>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SdzSpotTrustLevel {
    Verified,
    Unverified,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SdzSpotType {
    Park,
    Street,
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
            sdz_trust_level: SdzSpotTrustLevel::Unverified,
            sdz_trust_sources: Vec::new(),
            sdz_spot_type: None,
            sdz_instagram_url: None,
            sdz_official_url: None,
            sdz_business_hours: None,
            sdz_sections: Vec::new(),
            sdz_user_id,
            created_at: now_jst(),
            updated_at: now_jst(),
        })
    }

    #[allow(clippy::too_many_arguments)]
    pub fn new_admin(
        sdz_spot_id: String,
        name: String,
        description: Option<String>,
        location: Option<SdzSpotLocation>,
        tags: Vec<String>,
        images: Vec<String>,
        sdz_user_id: String,
        sdz_spot_type: Option<SdzSpotType>,
        sdz_instagram_url: Option<String>,
        sdz_official_url: Option<String>,
        sdz_business_hours: Option<String>,
        sdz_sections: Vec<String>,
    ) -> Result<Self, SdzSpotValidationError> {
        validate_spot(&name, location.as_ref(), &tags, &images)?;
        sdz_validate_urls(sdz_instagram_url.as_deref(), sdz_official_url.as_deref())?;
        Ok(Self {
            sdz_spot_id,
            name,
            description,
            location,
            tags,
            images,
            sdz_trust_level: SdzSpotTrustLevel::Verified,
            sdz_trust_sources: vec!["admin".to_string()],
            sdz_spot_type,
            sdz_instagram_url,
            sdz_official_url,
            sdz_business_hours,
            sdz_sections,
            sdz_user_id,
            created_at: now_jst(),
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

pub fn sdz_validate_urls(
    instagram_url: Option<&str>,
    official_url: Option<&str>,
) -> Result<(), SdzSpotValidationError> {
    if let Some(url) = instagram_url {
        if !url.is_empty() && !url.starts_with("https://") {
            return Err(SdzSpotValidationError::InvalidUrl(
                "instagramUrl must start with https://".into(),
            ));
        }
    }
    if let Some(url) = official_url {
        if !url.is_empty() && !url.starts_with("https://") && !url.starts_with("http://") {
            return Err(SdzSpotValidationError::InvalidUrl(
                "officialUrl must start with http:// or https://".into(),
            ));
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
    #[error("images must be <= 10 items")]
    TooManyImages,
    #[error("invalid url: {0}")]
    InvalidUrl(String),
}
