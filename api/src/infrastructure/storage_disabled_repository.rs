use async_trait::async_trait;

use crate::{
    application::use_cases::storage_repository::{SdzStorageRepository, SdzUploadUrlRequest, SdzUploadUrlResult},
    presentation::error::SdzApiError,
};

#[derive(Debug, Default)]
pub struct SdzDisabledStorageRepository;

#[async_trait]
impl SdzStorageRepository for SdzDisabledStorageRepository {
    async fn create_upload_url(
        &self,
        _request: SdzUploadUrlRequest,
    ) -> Result<SdzUploadUrlResult, SdzApiError> {
        Err(SdzApiError::Internal)
    }
}
