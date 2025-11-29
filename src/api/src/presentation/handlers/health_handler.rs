use std::convert::Infallible;

use hyper::{Body, Response, StatusCode};
use serde::Serialize;

use crate::application::use_cases::health_check_use_case::HealthCheckUseCase;

#[derive(Serialize)]
struct HealthResponse {
    status: &'static str,
    message: &'static str,
}

pub async fn handle_health() -> Result<Response<Body>, Infallible> {
    let use_case = HealthCheckUseCase::new();
    let status = use_case.execute().await;

    let response = HealthResponse {
        status: status.as_str(),
        message: "spot-diggz api is running",
    };

    let body = serde_json::to_string(&response).unwrap_or_else(|_| "{\"status\":\"error\"}".into());

    Ok(Response::builder()
        .status(StatusCode::OK)
        .header("content-type", "application/json")
        .body(Body::from(body))
        .unwrap())
}
