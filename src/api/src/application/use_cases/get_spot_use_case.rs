use std::sync::Arc;

use crate::{
    application::use_cases::spot_repository::SdzSpotRepository, domain::models::SdzSpot,
    presentation::error::SdzApiError,
};

pub struct SdzGetSpotUseCase;

impl SdzGetSpotUseCase {
    pub fn new() -> Self {
        Self
    }

    pub async fn execute(
        &self,
        repo: Arc<dyn SdzSpotRepository>,
        spot_id: String,
    ) -> Result<SdzSpot, SdzApiError> {
        repo.find_by_id(&spot_id)
            .await?
            .ok_or(SdzApiError::NotFound)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        domain::models::{SdzSpot, SdzSpotLocation},
        infrastructure::in_memory_spot_repository::SdzInMemorySpotRepository,
    };

    #[tokio::test]
    async fn get_spot_not_found() {
        let repo = Arc::new(SdzInMemorySpotRepository::default());
        let use_case = SdzGetSpotUseCase::new();
        let err = use_case.execute(repo, "missing".into()).await.unwrap_err();
        matches!(err, SdzApiError::NotFound);
    }
}
