use std::sync::Arc;

use uuid::Uuid;

use crate::{
    application::use_cases::spot_repository::SdzSpotRepository,
    domain::models::{SdzSpot, SdzSpotLocation, SdzSpotValidationError},
    presentation::error::SdzApiError,
    presentation::middleware::auth::SdzAuthUser,
};

pub struct SdzCreateSpotUseCase;

impl SdzCreateSpotUseCase {
    pub fn new() -> Self {
        Self
    }

    pub async fn execute(
        &self,
        repo: Arc<dyn SdzSpotRepository>,
        auth_user: SdzAuthUser,
        input: CreateSpotInput,
    ) -> Result<SdzSpot, SdzApiError> {
        let spot = SdzSpot::new_with_id(
            Uuid::new_v4().to_string(),
            input.name,
            input.description,
            input.location.map(|loc| SdzSpotLocation {
                lat: loc.lat,
                lng: loc.lng,
            }),
            input.tags.unwrap_or_default(),
            input.images.unwrap_or_default(),
            auth_user.sdz_user_id,
        )
        .map_err(map_validation_error)?;

        repo.create(spot.clone()).await?;

        Ok(spot)
    }
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct CreateSpotInput {
    pub name: String,
    pub description: Option<String>,
    pub location: Option<CreateSpotLocation>,
    pub tags: Option<Vec<String>>,
    pub images: Option<Vec<String>>,
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct CreateSpotLocation {
    pub lat: f64,
    pub lng: f64,
}

fn map_validation_error(err: SdzSpotValidationError) -> SdzApiError {
    SdzApiError::BadRequest(err.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        domain::models::SdzSpotTrustLevel,
        infrastructure::in_memory_spot_repository::SdzInMemorySpotRepository,
    };

    fn build_input() -> CreateSpotInput {
        CreateSpotInput {
            name: "test spot".into(),
            description: Some("desc".into()),
            location: Some(CreateSpotLocation {
                lat: 35.0,
                lng: 139.0,
            }),
            tags: Some(vec!["park".into()]),
            images: Some(vec![]),
        }
    }

    #[tokio::test]
    async fn create_spot_success() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".into(),
        };
        let input = build_input();
        let use_case = SdzCreateSpotUseCase::new();

        let result = use_case.execute(repo.clone(), auth, input).await.unwrap();

        assert_eq!(result.name, "test spot");
        assert_eq!(result.sdz_user_id, "user-1");
        assert!(!result.sdz_spot_id.is_empty());
        assert_eq!(result.tags.len(), 1);
        assert!(matches!(
            result.sdz_trust_level,
            SdzSpotTrustLevel::Unverified
        ));
        assert!(result.sdz_trust_sources.is_empty());
        assert!(repo
            .find_by_id(&result.sdz_spot_id)
            .await
            .unwrap()
            .is_some());
    }

    #[tokio::test]
    async fn create_spot_invalid_lat() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".into(),
        };
        let mut input = build_input();
        input.location = Some(CreateSpotLocation {
            lat: 100.0,
            lng: 139.0,
        });
        let use_case = SdzCreateSpotUseCase::new();

        let err = use_case.execute(repo, auth, input).await.unwrap_err();
        match err {
            SdzApiError::BadRequest(msg) => assert!(msg.contains("lat")),
            _ => panic!("expected bad request"),
        }
    }
}
