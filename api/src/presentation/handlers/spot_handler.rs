use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};

use crate::{
    application::use_cases::{
        create_spot_use_case::{CreateSpotInput, SdzCreateSpotUseCase},
        get_spot_use_case::SdzGetSpotUseCase,
        list_spots_use_case::SdzListSpotsUseCase,
    },
    presentation::{error::SdzApiError, middleware::auth::SdzAuthUser, router::SdzAppState},
};

pub async fn handle_create_spot(
    State(state): State<SdzAppState>,
    auth_user: SdzAuthUser,
    Json(payload): Json<CreateSpotInput>,
) -> impl IntoResponse {
    let use_case = SdzCreateSpotUseCase::new();
    let spot = use_case
        .execute(state.spot_repo.clone(), auth_user, payload)
        .await?;
    Ok::<_, SdzApiError>((StatusCode::OK, Json(spot)))
}

pub async fn handle_get_spot(
    State(state): State<SdzAppState>,
    Path(spot_id): Path<String>,
) -> impl IntoResponse {
    let use_case = SdzGetSpotUseCase::new();
    let spot = use_case.execute(state.spot_repo.clone(), spot_id).await?;
    Ok::<_, SdzApiError>((StatusCode::OK, Json(spot)))
}

pub async fn handle_list_spots(State(state): State<SdzAppState>) -> impl IntoResponse {
    let use_case = SdzListSpotsUseCase::new();
    let spots = use_case.execute(state.spot_repo.clone(), 50).await?;
    Ok::<_, SdzApiError>((StatusCode::OK, Json(spots)))
}
