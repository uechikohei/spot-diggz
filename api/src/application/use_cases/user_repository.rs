use async_trait::async_trait;

use crate::domain::models::SdzUser;

#[async_trait]
pub trait SdzUserRepository: Send + Sync {
    async fn find_by_id(&self, user_id: &str) -> Option<SdzUser>;
}
