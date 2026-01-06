use async_trait::async_trait;

use crate::{domain::models::SdzSpot, presentation::error::SdzApiError};

#[async_trait]
pub trait SdzSpotRepository: Send + Sync {
    async fn create(&self, spot: SdzSpot) -> Result<SdzSpot, SdzApiError>;
    async fn find_by_id(&self, spot_id: &str) -> Result<Option<SdzSpot>, SdzApiError>;
    async fn list_recent(&self, limit: usize) -> Result<Vec<SdzSpot>, SdzApiError>;
}
