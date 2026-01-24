use std::sync::Arc;

use uuid::Uuid;

use crate::{
    application::use_cases::spot_repository::SdzSpotRepository,
    domain::models::{SdzSpot, SdzSpotLocation, SdzSpotValidationError},
    presentation::error::SdzApiError,
    presentation::middleware::auth::SdzAuthUser,
};

pub struct SdzCreateSpotUseCase;

const SDZ_MAX_IMAGE_SPOTS_PER_USER: usize = 10;

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
        let CreateSpotInput {
            name,
            description,
            location,
            tags,
            images,
            park_attributes,
            street_attributes,
            instagram_tag,
        } = input;
        let images = images.unwrap_or_default();

        if !images.is_empty() {
            let count = repo
                .count_image_spots_by_user(&auth_user.sdz_user_id)
                .await?;
            if count >= SDZ_MAX_IMAGE_SPOTS_PER_USER {
                return Err(SdzApiError::Forbidden(
                    "image spot limit reached (max 10)".into(),
                ));
            }
        }

        let spot = SdzSpot::new_with_id(
            Uuid::new_v4().to_string(),
            name,
            description,
            location.map(|loc| SdzSpotLocation {
                lat: loc.lat,
                lng: loc.lng,
            }),
            tags.unwrap_or_default(),
            images,
            park_attributes,
            street_attributes,
            instagram_tag,
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
    #[serde(rename = "parkAttributes")]
    pub park_attributes: Option<crate::domain::models::SdzSpotParkAttributes>,
    #[serde(rename = "streetAttributes")]
    pub street_attributes: Option<crate::domain::models::SdzStreetAttributes>,
    #[serde(rename = "instagramTag")]
    pub instagram_tag: Option<String>,
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
    use crate::infrastructure::in_memory_spot_repository::SdzInMemorySpotRepository;

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
            park_attributes: None,
            street_attributes: None,
            instagram_tag: None,
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
        assert!(result.sdz_approval_status.is_none());
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

    #[tokio::test]
    async fn create_spot_rejects_image_limit() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".into(),
        };
        let use_case = SdzCreateSpotUseCase::new();

        for index in 0..SDZ_MAX_IMAGE_SPOTS_PER_USER {
            let spot = SdzSpot::new_with_id(
                format!("seed-{}", index),
                "seed".into(),
                None,
                None,
                vec![],
                vec!["img".into()],
                None,
                None,
                None,
                auth.sdz_user_id.clone(),
            )
            .unwrap();
            repo.create(spot).await.unwrap();
        }

        let input = CreateSpotInput {
            name: "limit".into(),
            description: None,
            location: None,
            tags: None,
            images: Some(vec!["img".into()]),
            park_attributes: None,
            street_attributes: None,
            instagram_tag: None,
        };
        let err = use_case.execute(repo, auth, input).await.unwrap_err();
        match err {
            SdzApiError::Forbidden(msg) => assert!(msg.contains("image spot limit")),
            _ => panic!("expected forbidden"),
        }
    }

    #[tokio::test]
    async fn create_spot_rejects_too_many_images() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".into(),
        };
        let use_case = SdzCreateSpotUseCase::new();

        let input = CreateSpotInput {
            name: "too-many".into(),
            description: None,
            location: None,
            tags: None,
            images: Some(vec!["a".into(), "b".into(), "c".into(), "d".into()]),
            park_attributes: None,
            street_attributes: None,
            instagram_tag: None,
        };

        let err = use_case.execute(repo, auth, input).await.unwrap_err();
        match err {
            SdzApiError::BadRequest(msg) => assert!(msg.contains("images must be <=")),
            _ => panic!("expected bad request"),
        }
    }
}
