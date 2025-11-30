use axum::{routing::get, Router};
use http::{HeaderValue, Method};
use tower_http::{
    cors::{AllowOrigin, CorsLayer},
    trace::TraceLayer,
};

use std::sync::Arc;

use crate::{
    application::use_cases::{
        spot_repository::SdzSpotRepository, user_repository::SdzUserRepository,
    },
    domain::models::SdzUser,
    infrastructure::{
        firestore_spot_repository::SdzFirestoreSpotRepository,
        firestore_user_repository::SdzFirestoreUserRepository,
        in_memory_spot_repository::SdzInMemorySpotRepository,
        in_memory_user_repository::SdzInMemoryUserRepository,
    },
};

use super::handlers::{health_handler, spot_handler, user_handler};

pub fn sdz_build_router() -> Router {
    let state = build_state();

    Router::new()
        .route("/sdz/health", get(health_handler::handle_health))
        .route("/sdz/users/me", get(user_handler::handle_get_me))
        .route(
            "/sdz/spots",
            axum::routing::post(spot_handler::handle_create_spot),
        )
        .route("/sdz/spots/:spot_id", get(spot_handler::handle_get_spot))
        .with_state(state)
        .layer(cors_layer())
        .layer(TraceLayer::new_for_http())
}

fn cors_layer() -> CorsLayer {
    CorsLayer::new()
        .allow_origin(allowed_origins())
        .allow_methods([Method::GET, Method::POST, Method::PATCH, Method::DELETE])
        .allow_headers(tower_http::cors::Any)
}

fn allowed_origins() -> AllowOrigin {
    // 環境変数SDZ_CORS_ALLOWED_ORIGINSにカンマ区切りで指定。
    // 未設定時はローカル開発用のlocalhostを許可。
    if let Ok(origins) = std::env::var("SDZ_CORS_ALLOWED_ORIGINS") {
        let list: Vec<HeaderValue> = origins
            .split(',')
            .filter_map(|s| {
                let trimmed = s.trim();
                if trimmed.is_empty() {
                    None
                } else {
                    HeaderValue::from_str(trimmed).ok()
                }
            })
            .collect();
        if !list.is_empty() {
            return AllowOrigin::list(list);
        }
    }

    // デフォルトは開発用
    AllowOrigin::list(
        ["http://localhost:3000", "http://127.0.0.1:3000"]
            .iter()
            .filter_map(|o| HeaderValue::from_str(o).ok()),
    )
}

fn build_state() -> SdzAppState {
    // 環境変数が整っていればFirestore実装を採用
    if std::env::var("SDZ_USE_FIRESTORE").ok().as_deref() == Some("1") {
        if let (Ok(project_id), Ok(token)) = (
            std::env::var("SDZ_FIRESTORE_PROJECT_ID")
                .or_else(|_| std::env::var("SDZ_AUTH_PROJECT_ID")),
            std::env::var("SDZ_FIRESTORE_TOKEN"),
        ) {
            if let (Ok(user_repo), Ok(spot_repo)) = (
                SdzFirestoreUserRepository::new(project_id.clone(), token.clone()),
                SdzFirestoreSpotRepository::new(project_id, token),
            ) {
                return SdzAppState {
                    user_repo: Arc::new(user_repo),
                    spot_repo: Arc::new(spot_repo),
                };
            } else {
                tracing::warn!("Failed to init Firestore repo, falling back to in-memory");
            }
        } else {
            tracing::warn!(
                "SDZ_USE_FIRESTORE=1 but project_id/token missing. Falling back to in-memory."
            );
        }
    }

    // デフォルト: ローカル動作用のメモリリポジトリ
    let seed_user = SdzUser {
        sdz_user_id: "zjJuiae1ymc6kqjU88yFsJvAuxG2".to_string(),
        sdz_display_name: "sdz-demo-user".to_string(),
        sdz_email: Some("uechi@321dev.org".to_string()),
    };
    let repo = SdzInMemoryUserRepository::new_with_seed(vec![seed_user]);
    SdzAppState {
        user_repo: Arc::new(repo),
        spot_repo: Arc::new(SdzInMemorySpotRepository::default()),
    }
}

#[derive(Clone)]
pub struct SdzAppState {
    pub user_repo: Arc<dyn SdzUserRepository>,
    pub spot_repo: Arc<dyn SdzSpotRepository>,
}
