use async_trait::async_trait;
use chrono::{DateTime, FixedOffset};
use serde::Serialize;

use crate::presentation::error::SdzApiError;

#[derive(Debug, Clone)]
pub struct SdzUploadUrlRequest {
    pub sdz_object_name: String,
    pub sdz_content_type: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct SdzUploadUrlResult {
    #[serde(rename = "uploadUrl")]
    pub sdz_upload_url: String,
    #[serde(rename = "objectUrl")]
    pub sdz_object_url: String,
    #[serde(rename = "objectName")]
    pub sdz_object_name: String,
    #[serde(rename = "expiresAt")]
    pub sdz_expires_at: DateTime<FixedOffset>,
}

#[async_trait]
pub trait SdzStorageRepository: Send + Sync {
    async fn create_upload_url(
        &self,
        request: SdzUploadUrlRequest,
    ) -> Result<SdzUploadUrlResult, SdzApiError>;
}
