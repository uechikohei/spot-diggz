use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};

use crate::{
    application::use_cases::get_current_user_use_case::SdzGetCurrentUserUseCase,
    presentation::middleware::auth::SdzAuthUser, presentation::router::SdzAppState,
};

pub async fn handle_get_me(
    State(state): State<SdzAppState>,
    auth_user: SdzAuthUser,
) -> impl IntoResponse {
    let use_case = SdzGetCurrentUserUseCase::new(state.user_repo.clone());
    let user = use_case.execute(state.user_repo.clone(), auth_user).await?;
    Ok::<_, crate::presentation::error::SdzApiError>((StatusCode::OK, Json(user)))
}
