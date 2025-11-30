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
    message: String,
}

#[derive(Debug, Error)]
pub enum SdzApiError {
    #[error("Bad Request: {0}")]
    BadRequest(String),
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
            Self::Unauthorized => StatusCode::UNAUTHORIZED,
            Self::NotFound => StatusCode::NOT_FOUND,
            Self::Internal => StatusCode::INTERNAL_SERVER_ERROR,
        }
    }
}

impl IntoResponse for SdzApiError {
    fn into_response(self) -> Response {
        let status = self.status_code();
        let body = SdzErrorBody {
            code: status.as_u16(),
            message: self.to_string(),
        };
        (status, Json(body)).into_response()
    }
}
