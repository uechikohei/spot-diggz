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
        domain::models::{SdzSpot, SdzSpotApprovalStatus},
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

        let use_case = SdzUpdateSpotUseCase::new();
        let result = use_case
            .execute(repo.clone(), auth, spot.sdz_spot_id.clone(), build_input())
            .await
            .unwrap();

        assert_eq!(result.sdz_spot_id, spot.sdz_spot_id);
        assert_eq!(result.name, "updated");
        assert_eq!(result.sdz_user_id, "user-1");
        assert!(result.sdz_approval_status.is_none());
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
