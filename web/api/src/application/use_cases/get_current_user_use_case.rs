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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::infrastructure::in_memory_user_repository::SdzInMemoryUserRepository;

    fn build_user() -> SdzUser {
        SdzUser {
            sdz_user_id: "user-1".into(),
            sdz_display_name: "test-user".into(),
            sdz_email: Some("test@example.com".into()),
        }
    }

    #[tokio::test]
    async fn get_current_user_success() {
        let user = build_user();
        let repo = Arc::new(SdzInMemoryUserRepository::new_with_seed(vec![user.clone()]));
        let auth = SdzAuthUser {
            sdz_user_id: user.sdz_user_id.clone(),
        };
        let use_case = SdzGetCurrentUserUseCase::new(repo.clone());

        let result = use_case.execute(repo, auth).await.unwrap();

        assert_eq!(result.sdz_user_id, user.sdz_user_id);
        assert_eq!(result.sdz_display_name, user.sdz_display_name);
    }

    #[tokio::test]
    async fn get_current_user_not_found() {
        let repo = Arc::new(SdzInMemoryUserRepository::default());
        let auth = SdzAuthUser {
            sdz_user_id: "missing-user".into(),
        };
        let use_case = SdzGetCurrentUserUseCase::new(repo.clone());

        let err = use_case.execute(repo, auth).await.unwrap_err();
        match err {
            SdzApiError::NotFound => {}
            _ => panic!("expected not found"),
        }
    }
}
