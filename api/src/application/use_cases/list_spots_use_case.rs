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
    ) -> Result<Vec<SdzSpot>, SdzApiError> {
        let capped = limit.min(100); // 念のため上限
        repo.list_recent(capped).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        domain::models::SdzSpotTrustLevel,
        infrastructure::in_memory_spot_repository::SdzInMemorySpotRepository,
    };
    use chrono::{FixedOffset, TimeZone};

    #[tokio::test]
    async fn list_spots_returns_empty() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let use_case = SdzListSpotsUseCase::new();
        let list = use_case.execute(repo, 10).await.unwrap();
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
            sdz_trust_level: SdzSpotTrustLevel::Unverified,
            sdz_trust_sources: vec![],
            sdz_user_id: "user".into(),
            created_at: tz.with_ymd_and_hms(2024, 1, 1, 0, 0, 0).unwrap(),
            updated_at: tz.with_ymd_and_hms(2024, 1, 1, 0, 0, 0).unwrap(),
        })
        .await
        .unwrap();

        let use_case = SdzListSpotsUseCase::new();
        let list = use_case.execute(repo, 10).await.unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0].sdz_spot_id, "spot-1");
    }
}
