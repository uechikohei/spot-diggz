use std::sync::Arc;

use crate::{
    application::use_cases::user_repository::SdzUserRepository, domain::models::SdzUser,
    presentation::error::SdzApiError, presentation::middleware::auth::SdzAuthUser,
};

pub struct SdzGetCurrentUserUseCase;

impl SdzGetCurrentUserUseCase {
    pub fn new(_repo: Arc<dyn SdzUserRepository>) -> Self {
        Self
    }

    pub async fn execute(
        &self,
        repo: Arc<dyn SdzUserRepository>,
        auth_user: SdzAuthUser,
    ) -> Result<SdzUser, SdzApiError> {
        let user = repo
            .find_by_id(&auth_user.sdz_user_id)
            .await
            .ok_or(SdzApiError::NotFound)?;
        Ok(user)
    }
}
