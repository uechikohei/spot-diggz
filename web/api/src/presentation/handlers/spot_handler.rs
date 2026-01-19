use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};

use crate::{
    application::use_cases::{
        create_spot_use_case::{CreateSpotInput, SdzCreateSpotUseCase},
        generate_upload_url_use_case::{SdzGenerateUploadUrlInput, SdzGenerateUploadUrlUseCase},
        get_spot_use_case::SdzGetSpotUseCase,
        list_spots_use_case::SdzListSpotsUseCase,
        update_spot_use_case::{SdzUpdateSpotUseCase, UpdateSpotInput},
    },
    presentation::{
        error::SdzApiError,
        middleware::{
            auth::{SdzAuthUser, SdzOptionalAuthUser},
            client::SdzClientApp,
        },
        router::SdzAppState,
    },
};

pub async fn handle_create_spot(
    State(state): State<SdzAppState>,
    auth_user: SdzAuthUser,
    client_app: SdzClientApp,
    Json(payload): Json<CreateSpotInput>,
) -> impl IntoResponse {
    if !client_app.is_mobile() {
        return Err(SdzApiError::Forbidden("mobile client required".to_string()));
    }
    tracing::info!(
        event_code = "SDZ-API-2001",
        component = "presentation",
        user_id = %auth_user.sdz_user_id,
        has_location = payload.location.is_some(),
        tags_len = payload.tags.as_ref().map(|t| t.len()).unwrap_or(0),
        images_len = payload.images.as_ref().map(|i| i.len()).unwrap_or(0),
        "create spot requested"
    );
    let use_case = SdzCreateSpotUseCase::new();
    let spot = use_case
        .execute(state.spot_repo.clone(), auth_user, payload)
        .await?;
    tracing::info!(
        event_code = "SDZ-API-2002",
        component = "presentation",
        spot_id = %spot.sdz_spot_id,
        "spot created"
    );
    Ok::<_, SdzApiError>((StatusCode::OK, Json(spot)))
}

pub async fn handle_create_upload_url(
    State(state): State<SdzAppState>,
    auth_user: SdzAuthUser,
    client_app: SdzClientApp,
    Json(payload): Json<SdzGenerateUploadUrlInput>,
) -> impl IntoResponse {
    if !client_app.is_mobile() {
        return Err(SdzApiError::Forbidden("mobile client required".to_string()));
    }
    tracing::info!(
        event_code = "SDZ-API-2101",
        component = "presentation",
        user_id = %auth_user.sdz_user_id,
        content_type = %payload.sdz_content_type,
        "upload url requested"
    );

    let use_case = SdzGenerateUploadUrlUseCase::new();
    let result = use_case
        .execute(state.storage_repo.clone(), auth_user, payload)
        .await?;

    tracing::info!(
        event_code = "SDZ-API-2102",
        component = "presentation",
        object_name = %result.sdz_object_name,
        "upload url issued"
    );

    Ok::<_, SdzApiError>((StatusCode::OK, Json(result)))
}

pub async fn handle_get_spot(
    State(state): State<SdzAppState>,
    Path(spot_id): Path<String>,
    auth_user: SdzOptionalAuthUser,
) -> impl IntoResponse {
    let use_case = SdzGetSpotUseCase::new();
    let spot = use_case
        .execute(state.spot_repo.clone(), spot_id, auth_user.sdz_user_id)
        .await?;
    Ok::<_, SdzApiError>((StatusCode::OK, Json(spot)))
}

pub async fn handle_list_spots(
    State(state): State<SdzAppState>,
    auth_user: SdzOptionalAuthUser,
) -> impl IntoResponse {
    let use_case = SdzListSpotsUseCase::new();
    let spots = use_case
        .execute(state.spot_repo.clone(), 50, auth_user.sdz_user_id)
        .await?;
    Ok::<_, SdzApiError>((StatusCode::OK, Json(spots)))
}

pub async fn handle_update_spot(
    State(state): State<SdzAppState>,
    Path(spot_id): Path<String>,
    auth_user: SdzAuthUser,
    client_app: SdzClientApp,
    Json(payload): Json<UpdateSpotInput>,
) -> impl IntoResponse {
    if !client_app.is_mobile() {
        return Err(SdzApiError::Forbidden("mobile client required".to_string()));
    }
    tracing::info!(
        event_code = "SDZ-API-2003",
        component = "presentation",
        user_id = %auth_user.sdz_user_id,
        spot_id = %spot_id,
        "update spot requested"
    );
    let use_case = SdzUpdateSpotUseCase::new();
    let spot = use_case
        .execute(state.spot_repo.clone(), auth_user, spot_id, payload)
        .await?;
    tracing::info!(
        event_code = "SDZ-API-2004",
        component = "presentation",
        spot_id = %spot.sdz_spot_id,
        "spot updated"
    );
    Ok::<_, SdzApiError>((StatusCode::OK, Json(spot)))
}
