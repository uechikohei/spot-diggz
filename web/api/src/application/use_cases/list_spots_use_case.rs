use std::sync::Arc;

use crate::{
    application::use_cases::spot_repository::SdzSpotRepository, domain::models::SdzSpot,
    presentation::error::SdzApiError,
};

pub struct SdzListSpotsUseCase;

impl SdzListSpotsUseCase {
    pub fn new() -> Self {
        Self
    }

    pub async fn execute(
        &self,
        repo: Arc<dyn SdzSpotRepository>,
        limit: usize,
        viewer_user_id: Option<String>,
    ) -> Result<Vec<SdzSpot>, SdzApiError> {
        let capped = limit.min(100); // 念のため上限
        let mut spots = repo.list_recent(capped).await?;
        if let Some(user_id) = viewer_user_id {
            spots.retain(|spot| spot.is_approved() || spot.sdz_user_id == user_id);
        } else {
            spots.retain(|spot| spot.is_approved());
        }
        Ok(spots)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        domain::models::SdzSpotApprovalStatus,
        infrastructure::in_memory_spot_repository::SdzInMemorySpotRepository,
    };
    use chrono::{FixedOffset, TimeZone};

    #[tokio::test]
    async fn list_spots_returns_empty() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let use_case = SdzListSpotsUseCase::new();
        let list = use_case.execute(repo, 10, None).await.unwrap();
        assert!(list.is_empty());
    }

    #[tokio::test]
    async fn list_spots_orders_recent() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let tz = FixedOffset::east_opt(9 * 3600).unwrap();
        // 1件だけ入れて確認
        repo.create(crate::domain::models::SdzSpot {
            sdz_spot_id: "spot-1".into(),
            name: "A".into(),
            description: None,
            location: None,
            tags: vec![],
            images: vec![],
            sdz_approval_status: Some(SdzSpotApprovalStatus::Approved),
            sdz_park_attributes: None,
            sdz_street_attributes: None,
            sdz_instagram_tag: None,
            sdz_user_id: "user".into(),
            created_at: tz.with_ymd_and_hms(2024, 1, 1, 0, 0, 0).unwrap(),
            updated_at: tz.with_ymd_and_hms(2024, 1, 1, 0, 0, 0).unwrap(),
        })
        .await
        .unwrap();

        let use_case = SdzListSpotsUseCase::new();
        let list = use_case.execute(repo, 10, None).await.unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0].sdz_spot_id, "spot-1");
    }

    #[tokio::test]
    async fn list_spots_includes_owner_unapproved() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let tz = FixedOffset::east_opt(9 * 3600).unwrap();
        repo.create(crate::domain::models::SdzSpot {
            sdz_spot_id: "spot-owner".into(),
            name: "Owner".into(),
            description: None,
            location: None,
            tags: vec![],
            images: vec![],
            sdz_approval_status: None,
            sdz_park_attributes: None,
            sdz_street_attributes: None,
            sdz_instagram_tag: None,
            sdz_user_id: "user-1".into(),
            created_at: tz.with_ymd_and_hms(2024, 1, 2, 0, 0, 0).unwrap(),
            updated_at: tz.with_ymd_and_hms(2024, 1, 2, 0, 0, 0).unwrap(),
        })
        .await
        .unwrap();
        repo.create(crate::domain::models::SdzSpot {
            sdz_spot_id: "spot-other".into(),
            name: "Other".into(),
            description: None,
            location: None,
            tags: vec![],
            images: vec![],
            sdz_approval_status: None,
            sdz_park_attributes: None,
            sdz_street_attributes: None,
            sdz_instagram_tag: None,
            sdz_user_id: "user-2".into(),
            created_at: tz.with_ymd_and_hms(2024, 1, 3, 0, 0, 0).unwrap(),
            updated_at: tz.with_ymd_and_hms(2024, 1, 3, 0, 0, 0).unwrap(),
        })
        .await
        .unwrap();

        let use_case = SdzListSpotsUseCase::new();
        let list = use_case
            .execute(repo, 10, Some("user-1".into()))
            .await
            .unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0].sdz_spot_id, "spot-owner");
    }
}
