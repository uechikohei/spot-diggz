use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use thiserror::Error;

#[derive(Debug, Serialize)]
pub struct SdzErrorBody {
    code: u16,
    #[serde(rename = "errorCode")]
    error_code: &'static str,
    message: String,
}

#[derive(Debug, Error)]
pub enum SdzApiError {
    #[error("Bad Request: {0}")]
    BadRequest(String),
    #[error("Forbidden: {0}")]
    Forbidden(String),
    #[error("Unauthorized")]
    Unauthorized,
    #[error("Not Found")]
    NotFound,
    #[error("Internal Server Error")]
    Internal,
}

impl SdzApiError {
    fn status_code(&self) -> StatusCode {
        match self {
            Self::BadRequest(_) => StatusCode::BAD_REQUEST,
            Self::Forbidden(_) => StatusCode::FORBIDDEN,
            Self::Unauthorized => StatusCode::UNAUTHORIZED,
            Self::NotFound => StatusCode::NOT_FOUND,
            Self::Internal => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }

    fn error_code(&self) -> &'static str {
        match self {
            Self::BadRequest(_) => "SDZ-E-2001",
            Self::Forbidden(_) => "SDZ-E-1002",
            Self::Unauthorized => "SDZ-E-1001",
            Self::NotFound => "SDZ-E-4004",
            Self::Internal => "SDZ-E-9001",
        }
    }

    fn event_code(&self) -> &'static str {
        match self {
            Self::BadRequest(_) => "SDZ-API-4001",
            Self::Forbidden(_) => "SDZ-API-4030",
            Self::Unauthorized => "SDZ-API-4010",
            Self::NotFound => "SDZ-API-4040",
            Self::Internal => "SDZ-API-5000",
        }
    }
}

impl IntoResponse for SdzApiError {
    fn into_response(self) -> Response {
        let status = self.status_code();
        if status == StatusCode::INTERNAL_SERVER_ERROR {
            tracing::error!(
                event_code = self.event_code(),
                component = "presentation",
                error_code = self.error_code(),
                status = status.as_u16(),
                message = %self
            );
        } else {
            tracing::warn!(
                event_code = self.event_code(),
                component = "presentation",
                error_code = self.error_code(),
                status = status.as_u16(),
                message = %self
            );
        }
        let body = SdzErrorBody {
            code: status.as_u16(),
            error_code: self.error_code(),
            message: self.to_string(),
        };
        (status, Json(body)).into_response()
    }
}
