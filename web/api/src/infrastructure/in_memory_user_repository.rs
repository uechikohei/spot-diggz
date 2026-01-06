use std::collections::HashMap;
use std::sync::Arc;

use async_trait::async_trait;
use tokio::sync::RwLock;

use crate::application::use_cases::user_repository::SdzUserRepository;
use crate::domain::models::SdzUser;

#[derive(Clone, Default)]
pub struct SdzInMemoryUserRepository {
    store: Arc<RwLock<HashMap<String, SdzUser>>>,
}

impl SdzInMemoryUserRepository {
    pub fn new_with_seed(users: Vec<SdzUser>) -> Self {
        let map = users
            .into_iter()
            .map(|u| (u.sdz_user_id.clone(), u))
            .collect();
        Self {
            store: Arc::new(RwLock::new(map)),
        }
    }
}

#[async_trait]
impl SdzUserRepository for SdzInMemoryUserRepository {
    async fn find_by_id(&self, user_id: &str) -> Option<SdzUser> {
        let store = self.store.read().await;
        store.get(user_id).cloned()
    }
}
