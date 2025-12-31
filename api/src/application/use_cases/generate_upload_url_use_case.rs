use std::sync::Arc;

use serde::Deserialize;
use uuid::Uuid;

use crate::{
    application::use_cases::storage_repository::{
        SdzStorageRepository, SdzUploadUrlRequest, SdzUploadUrlResult,
    },
    presentation::{error::SdzApiError, middleware::auth::SdzAuthUser},
};

pub struct SdzGenerateUploadUrlUseCase;

impl SdzGenerateUploadUrlUseCase {
    pub fn new() -> Self {
        Self
    }

    pub async fn execute(
        &self,
        repo: Arc<dyn SdzStorageRepository>,
        auth_user: SdzAuthUser,
        input: SdzGenerateUploadUrlInput,
    ) -> Result<SdzUploadUrlResult, SdzApiError> {
        let content_type = input.sdz_content_type.trim().to_lowercase();
        let extension = sdz_extension_from_content_type(&content_type)
            .ok_or_else(|| SdzApiError::BadRequest("unsupported contentType".into()))?;

        let object_name = format!(
            "spots/{}/{}.{}",
            auth_user.sdz_user_id,
            Uuid::new_v4(),
            extension
        );

        let request = SdzUploadUrlRequest {
            sdz_object_name: object_name,
            sdz_content_type: content_type,
        };

        repo.create_upload_url(request).await
    }
}

#[derive(Debug, Clone, Deserialize)]
pub struct SdzGenerateUploadUrlInput {
    #[serde(rename = "contentType")]
    pub sdz_content_type: String,
}

fn sdz_extension_from_content_type(content_type: &str) -> Option<&'static str> {
    match content_type {
        "image/jpeg" | "image/jpg" => Some("jpg"),
        "image/png" => Some("png"),
        "image/webp" => Some("webp"),
        "image/gif" => Some("gif"),
        "image/heic" => Some("heic"),
        "image/heif" => Some("heif"),
        _ => None,
    }
}
