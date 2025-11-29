use std::convert::Infallible;
use std::net::SocketAddr;

use hyper::service::{make_service_fn, service_fn};
use hyper::Server;

use crate::presentation::router::route;

pub async fn run() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let addr = resolve_listen_address();
    let make_svc = make_service_fn(|_conn| async {
        Ok::<_, Infallible>(service_fn(route))
    });

    println!("spot-diggz api listening on http://{}", addr);
    Server::bind(&addr).serve(make_svc).await?;

    Ok(())
}

fn resolve_listen_address() -> SocketAddr {
    // Cloud Run ではPORT環境変数が渡されるため、デフォルト8080を優先。
    let port = std::env::var("PORT")
        .ok()
        .and_then(|value| value.parse::<u16>().ok())
        .unwrap_or(8080);
    SocketAddr::from(([0, 0, 0, 0], port))
}
