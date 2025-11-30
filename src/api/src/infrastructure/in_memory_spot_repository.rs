use std::collections::HashMap;
use std::sync::Arc;

use async_trait::async_trait;
use tokio::sync::RwLock;

use crate::{
    application::use_cases::spot_repository::SdzSpotRepository, domain::models::SdzSpot,
    presentation::error::SdzApiError,
};

#[derive(Clone, Default)]
pub struct SdzInMemorySpotRepository {
    store: Arc<RwLock<HashMap<String, SdzSpot>>>,
}

#[async_trait]
impl SdzSpotRepository for SdzInMemorySpotRepository {
    async fn create(&self, spot: SdzSpot) -> Result<SdzSpot, SdzApiError> {
        let mut store = self.store.write().await;
        store.insert(spot.sdz_spot_id.clone(), spot.clone());
        Ok(spot)
    }

    async fn find_by_id(&self, spot_id: &str) -> Result<Option<SdzSpot>, SdzApiError> {
        let store = self.store.read().await;
        Ok(store.get(spot_id).cloned())
    }
}
