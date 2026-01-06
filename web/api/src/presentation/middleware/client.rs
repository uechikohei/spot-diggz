use axum::{
    extract::FromRequestParts,
    http::{request::Parts, HeaderMap},
};

use crate::presentation::error::SdzApiError;

#[derive(Debug, Clone, Copy)]
pub enum SdzClientType {
    Ios,
    Android,
}

#[derive(Debug, Clone)]
pub struct SdzClientApp {
    pub sdz_client: SdzClientType,
}

impl SdzClientApp {
    pub fn is_mobile(&self) -> bool {
        matches!(self.sdz_client, SdzClientType::Ios | SdzClientType::Android)
    }
}

impl<S> FromRequestParts<S> for SdzClientApp
where
    S: Send + Sync,
{
    type Rejection = SdzApiError;

    #[allow(clippy::manual_async_fn)]
    fn from_request_parts(
        parts: &mut Parts,
        _state: &S,
    ) -> impl std::future::Future<Output = Result<Self, Self::Rejection>> + Send {
        async move {
            let client = extract_client(&parts.headers)?;
            Ok(SdzClientApp { sdz_client: client })
        }
    }
}

fn extract_client(headers: &HeaderMap) -> Result<SdzClientType, SdzApiError> {
    let value = headers
        .get("x-sdz-client")
        .and_then(|v| v.to_str().ok())
        .map(|v| v.trim().to_lowercase())
        .ok_or_else(|| SdzApiError::Forbidden("mobile client required (x-sdz-client)".into()))?;

    match value.as_str() {
        "ios" => Ok(SdzClientType::Ios),
        "android" => Ok(SdzClientType::Android),
        _ => Err(SdzApiError::Forbidden(
            "invalid client type (ios/android only)".into(),
        )),
    }
}
