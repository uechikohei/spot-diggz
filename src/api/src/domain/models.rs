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

use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
pub struct SdzUser {
    #[serde(rename = "userId")]
    pub sdz_user_id: String,
    #[serde(rename = "displayName")]
    pub sdz_display_name: String,
    #[serde(rename = "email")]
    pub sdz_email: Option<String>,
}
