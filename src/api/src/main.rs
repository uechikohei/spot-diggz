mod application;
mod domain;
mod infrastructure;
mod presentation;
mod bootstrap;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    bootstrap::run().await
}
