use std::sync::Arc;

use crate::{
    application::use_cases::{
        mylist_repository::SdzMyListRepository, spot_repository::SdzSpotRepository,
    },
    domain::models::SdzSpot,
    presentation::{error::SdzApiError, middleware::auth::SdzAuthUser},
};

pub struct SdzListMyListUseCase;

impl SdzListMyListUseCase {
    pub fn new() -> Self {
        Self
    }

    pub async fn execute(
        &self,
        mylist_repo: Arc<dyn SdzMyListRepository>,
        spot_repo: Arc<dyn SdzSpotRepository>,
        auth_user: SdzAuthUser,
    ) -> Result<Vec<SdzSpot>, SdzApiError> {
        let mut entries = mylist_repo.list_by_user(&auth_user.sdz_user_id).await?;
        entries.sort_by(|a, b| b.created_at.cmp(&a.created_at));

        let mut spots = Vec::new();
        for entry in entries {
            if let Some(spot) = spot_repo.find_by_id(&entry.sdz_spot_id).await? {
                spots.push(spot);
            }
        }
        Ok(spots)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        domain::models::{SdzSpot, SdzSpotLocation},
        infrastructure::{
            in_memory_mylist_repository::SdzInMemoryMyListRepository,
            in_memory_spot_repository::SdzInMemorySpotRepository,
        },
    };

    fn sample_spot(id: &str, user_id: &str) -> SdzSpot {
        SdzSpot::new_with_id(
            id.to_string(),
            format!("spot-{id}"),
            None,
            Some(SdzSpotLocation {
                lat: 35.0,
                lng: 139.0,
            }),
            vec!["park".to_string()],
            vec![],
            None,
            None,
            None,
            user_id.to_string(),
        )
        .expect("valid spot")
    }

    #[tokio::test]
    async fn list_mylist_returns_spots() {
        let mylist_repo = Arc::new(SdzInMemoryMyListRepository::default());
        let spot_repo = Arc::new(SdzInMemorySpotRepository::default());
        spot_repo
            .create(sample_spot("spot-1", "user-1"))
            .await
            .unwrap();
        spot_repo
            .create(sample_spot("spot-2", "user-1"))
            .await
            .unwrap();

        mylist_repo.add("user-1", "spot-1").await.unwrap();
        mylist_repo.add("user-1", "spot-2").await.unwrap();

        let use_case = SdzListMyListUseCase::new();
        let auth = SdzAuthUser {
            sdz_user_id: "user-1".to_string(),
        };
        let list = use_case
            .execute(mylist_repo, spot_repo, auth)
            .await
            .unwrap();

        assert_eq!(list.len(), 2);
        let ids: Vec<_> = list.into_iter().map(|spot| spot.sdz_spot_id).collect();
        assert!(ids.contains(&"spot-1".to_string()));
        assert!(ids.contains(&"spot-2".to_string()));
    }
}
