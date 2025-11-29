use std::convert::Infallible;

use hyper::{Body, Method, Request, Response, StatusCode};

use super::handlers::health_handler;

pub async fn route(req: Request<Body>) -> Result<Response<Body>, Infallible> {
    match (req.method(), req.uri().path()) {
        (&Method::GET, "/sdz/health") => health_handler::handle_health().await,
        _ => Ok(Response::builder()
            .status(StatusCode::NOT_FOUND)
            .body(Body::from("Not Found"))
            .unwrap()),
    }
}
