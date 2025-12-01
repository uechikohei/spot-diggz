mod application;
mod domain;
mod infrastructure;
mod presentation;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    // .envを読み込んで環境変数をセット（存在しなくてもOK）
    let _ = dotenvy::dotenv();
    init_tracing();
    let router = presentation::router::sdz_build_router();

    let addr = resolve_listen_address();
    println!("spot-diggz api listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, router).await?;

    Ok(())
}

fn init_tracing() {
    // 環境変数RUST_LOGでログレベルを制御可能。例: RUST_LOG=info,sdz_api=debug
    let env_filter = tracing_subscriber::EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| "info,sdz_api=debug".into());
    tracing_subscriber::fmt()
        .with_env_filter(env_filter)
        .with_target(false)
        .compact()
        .init();
}

fn resolve_listen_address() -> std::net::SocketAddr {
    // Cloud RunではPORT環境変数が渡されるため、デフォルト8080を優先。
    let port = std::env::var("PORT")
        .ok()
        .and_then(|value| value.parse::<u16>().ok())
        .unwrap_or(8080);
    std::net::SocketAddr::from(([0, 0, 0, 0], port))
}
