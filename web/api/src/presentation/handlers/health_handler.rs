use axum::{http::StatusCode, response::IntoResponse, Json};
use serde::Serialize;

use crate::application::use_cases::health_check_use_case::HealthCheckUseCase;

#[derive(Serialize)]
struct HealthResponse {
    status: &'static str,
    message: &'static str,
}

pub async fn handle_health() -> impl IntoResponse {
    let use_case = HealthCheckUseCase::new();
    let status = use_case.execute().await;

    let response = HealthResponse {
        status: status.as_str(),
        message: "spot-diggz api is running",
    };

    (StatusCode::OK, Json(response))
}
