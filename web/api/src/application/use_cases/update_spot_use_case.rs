use std::sync::Arc;

use crate::{
    application::use_cases::spot_repository::SdzSpotRepository,
    domain::models::{SdzSpot, SdzSpotApprovalStatus, SdzSpotLocation, SdzSpotValidationError},
    presentation::error::SdzApiError,
    presentation::middleware::auth::SdzAuthUser,
};

pub struct SdzUpdateSpotUseCase;

impl SdzUpdateSpotUseCase {
    pub fn new() -> Self {
        Self
    }

    pub async fn execute(
        &self,
        repo: Arc<dyn SdzSpotRepository>,
        auth_user: SdzAuthUser,
        spot_id: String,
        input: UpdateSpotInput,
    ) -> Result<SdzSpot, SdzApiError> {
        let existing = repo
            .find_by_id(&spot_id)
            .await?
            .ok_or(SdzApiError::NotFound)?;

        if existing.sdz_user_id != auth_user.sdz_user_id {
            return Err(SdzApiError::Forbidden("spot owner mismatch".to_string()));
        }

        let location = input
            .location
            .map(|loc| SdzSpotLocation {
                lat: loc.lat,
                lng: loc.lng,
            })
            .or(existing.location.clone());
        let tags = input.tags.unwrap_or_else(|| existing.tags.clone());
        let images = input.images.unwrap_or_else(|| existing.images.clone());
        let description = if input.description.is_some() {
            input.description
        } else {
            existing.description.clone()
        };
        let park_attributes = if input.park_attributes.is_some() {
            input.park_attributes
        } else {
            existing.sdz_park_attributes.clone()
        };
        let street_attributes = if input.street_attributes.is_some() {
            input.street_attributes
        } else {
            existing.sdz_street_attributes.clone()
        };
        let instagram_tag = if input.instagram_tag.is_some() {
            input.instagram_tag
        } else {
            existing.sdz_instagram_tag.clone()
        };
        let instagram_location_url = if input.instagram_location_url.is_some() {
            input.instagram_location_url
        } else {
            existing.sdz_instagram_location_url.clone()
        };
        let instagram_profile_url = if input.instagram_profile_url.is_some() {
            input.instagram_profile_url
        } else {
            existing.sdz_instagram_profile_url.clone()
        };
        let approval_status =
            resolve_approval_status(existing.sdz_approval_status.clone(), input.approval_status)?;

        let updated = existing
            .update(
                input.name,
                description,
                location,
                tags,
                images,
                approval_status,
                park_attributes,
                street_attributes,
                instagram_tag,
                instagram_location_url,
                instagram_profile_url,
            )
            .map_err(map_validation_error)?;

        repo.create(updated.clone()).await?;

        Ok(updated)
    }
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct UpdateSpotInput {
    pub name: String,
    pub description: Option<String>,
    pub location: Option<UpdateSpotLocation>,
    pub tags: Option<Vec<String>>,
    pub images: Option<Vec<String>>,
    #[serde(rename = "approvalStatus")]
    pub approval_status: Option<SdzSpotApprovalStatus>,
    #[serde(rename = "parkAttributes")]
    pub park_attributes: Option<crate::domain::models::SdzSpotParkAttributes>,
    #[serde(rename = "streetAttributes")]
    pub street_attributes: Option<crate::domain::models::SdzStreetAttributes>,
    #[serde(rename = "instagramTag")]
    pub instagram_tag: Option<String>,
    #[serde(rename = "instagramLocationUrl")]
    pub instagram_location_url: Option<String>,
    #[serde(rename = "instagramProfileUrl")]
    pub instagram_profile_url: Option<String>,
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct UpdateSpotLocation {
    pub lat: f64,
    pub lng: f64,
}

fn map_validation_error(err: SdzSpotValidationError) -> SdzApiError {
    SdzApiError::BadRequest(err.to_string())
}

fn resolve_approval_status(
    current: Option<SdzSpotApprovalStatus>,
    requested: Option<SdzSpotApprovalStatus>,
) -> Result<Option<SdzSpotApprovalStatus>, SdzApiError> {
    match requested {
        None => Ok(current),
        Some(SdzSpotApprovalStatus::Pending) => match current {
            None | Some(SdzSpotApprovalStatus::Rejected) => {
                Ok(Some(SdzSpotApprovalStatus::Pending))
            }
            Some(SdzSpotApprovalStatus::Pending) | Some(SdzSpotApprovalStatus::Approved) => Err(
                SdzApiError::Forbidden("approval status update not allowed".to_string()),
            ),
        },
        Some(_) => Err(SdzApiError::Forbidden(
            "approval status update not allowed".to_string(),
        )),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        domain::models::{SdzSpot, SdzSpotApprovalStatus, SdzStreetAttributes},
        infrastructure::in_memory_spot_repository::SdzInMemorySpotRepository,
    };

    fn build_spot(user_id: &str) -> SdzSpot {
        SdzSpot::new_with_id(
            "spot-1".to_string(),
            "origin".to_string(),
            Some("desc".to_string()),
            Some(SdzSpotLocation {
                lat: 35.0,
                lng: 139.0,
            }),
            vec!["park".to_string()],
            vec![],
            None,
            None,
            None,
            None,
            None,
            user_id.to_string(),
        )
        .expect("valid spot")
    }

    fn build_input() -> UpdateSpotInput {
        UpdateSpotInput {
            name: "updated".to_string(),
            description: Some("new desc".to_string()),
            location: Some(UpdateSpotLocation {
                lat: 35.1,
                lng: 139.1,
            }),
            tags: Some(vec!["street".to_string()]),
            images: Some(vec![]),
            approval_status: None,
            park_attributes: None,
            street_attributes: None,
            instagram_tag: None,
            instagram_location_url: None,
            instagram_profile_url: None,
        }
    }

    fn build_street_attributes() -> SdzStreetAttributes {
        SdzStreetAttributes {
            surface_material: Some("asphalt".to_string()),
            surface_condition: None,
            sections: None,
            difficulty: Some("beginner".to_string()),
            notes: None,
        }
    }

    #[tokio::test]
    async fn update_spot_success() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let spot = build_spot("user-1");
        repo.create(spot.clone()).await.unwrap();
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".into(),
        };
        let mut input = build_input();
        input.instagram_location_url =
            Some("https://www.instagram.com/explore/locations/271647589/".to_string());

        let use_case = SdzUpdateSpotUseCase::new();
        let result = use_case
            .execute(repo.clone(), auth, spot.sdz_spot_id.clone(), input)
            .await
            .unwrap();

        assert_eq!(result.sdz_spot_id, spot.sdz_spot_id);
        assert_eq!(result.name, "updated");
        assert_eq!(result.sdz_user_id, "user-1");
        assert!(result.sdz_approval_status.is_none());
        assert_eq!(
            result.sdz_instagram_location_url.as_deref(),
            Some("https://www.instagram.com/explore/locations/271647589/")
        );
    }

    #[tokio::test]
    async fn update_spot_can_request_approval_when_empty() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let spot = build_spot("user-1");
        repo.create(spot.clone()).await.unwrap();
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".into(),
        };

        let mut input = build_input();
        input.approval_status = Some(SdzSpotApprovalStatus::Pending);

        let use_case = SdzUpdateSpotUseCase::new();
        let result = use_case
            .execute(repo, auth, spot.sdz_spot_id.clone(), input)
            .await
            .unwrap();

        assert!(matches!(
            result.sdz_approval_status,
            Some(SdzSpotApprovalStatus::Pending)
        ));
    }

    #[tokio::test]
    async fn update_spot_rejects_too_many_images() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let spot = build_spot("user-1");
        repo.create(spot.clone()).await.unwrap();
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".into(),
        };

        let mut input = build_input();
        input.images = Some(vec!["a".into(), "b".into(), "c".into(), "d".into()]);

        let use_case = SdzUpdateSpotUseCase::new();
        let err = use_case
            .execute(repo, auth, spot.sdz_spot_id.clone(), input)
            .await
            .unwrap_err();

        match err {
            SdzApiError::BadRequest(msg) => assert!(msg.contains("images must be <=")),
            _ => panic!("expected bad request"),
        }
    }

    #[tokio::test]
    async fn update_spot_persists_street_attributes() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let spot = build_spot("user-1");
        repo.create(spot.clone()).await.unwrap();
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".into(),
        };

        let mut input = build_input();
        input.street_attributes = Some(build_street_attributes());

        let use_case = SdzUpdateSpotUseCase::new();
        let result = use_case
            .execute(repo.clone(), auth, spot.sdz_spot_id.clone(), input)
            .await
            .unwrap();

        let attrs = result
            .sdz_street_attributes
            .expect("street attributes should be set");
        assert_eq!(attrs.surface_material.as_deref(), Some("asphalt"));

        let persisted = repo
            .find_by_id(&spot.sdz_spot_id)
            .await
            .unwrap()
            .expect("spot should exist");
        assert_eq!(
            persisted
                .sdz_street_attributes
                .and_then(|data| data.surface_material),
            Some("asphalt".to_string())
        );
    }

    #[tokio::test]
    async fn update_spot_rejects_illegal_approval_status() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let mut spot = build_spot("user-1");
        spot.sdz_approval_status = Some(SdzSpotApprovalStatus::Approved);
        repo.create(spot.clone()).await.unwrap();
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".into(),
        };

        let mut input = build_input();
        input.approval_status = Some(SdzSpotApprovalStatus::Pending);

        let use_case = SdzUpdateSpotUseCase::new();
        let err = use_case
            .execute(repo, auth, spot.sdz_spot_id.clone(), input)
            .await
            .unwrap_err();

        match err {
            SdzApiError::Forbidden(_) => {}
            _ => panic!("expected forbidden"),
        }
    }

    #[tokio::test]
    async fn update_spot_forbidden_when_owner_mismatch() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let spot = build_spot("user-1");
        repo.create(spot.clone()).await.unwrap();
        let auth = SdzAuthUser {
            sdz_user_id: "user-2".into(),
        };

        let use_case = SdzUpdateSpotUseCase::new();
        let err = use_case
            .execute(repo, auth, spot.sdz_spot_id, build_input())
            .await
            .unwrap_err();

        match err {
            SdzApiError::Forbidden(_) => {}
            _ => panic!("expected forbidden"),
        }
    }

    #[tokio::test]
    async fn update_spot_not_found() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".into(),
        };

        let use_case = SdzUpdateSpotUseCase::new();
        let err = use_case
            .execute(repo, auth, "missing".into(), build_input())
            .await
            .unwrap_err();

        match err {
            SdzApiError::NotFound => {}
            _ => panic!("expected not found"),
        }
    }
}
