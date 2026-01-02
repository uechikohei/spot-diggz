use crate::domain::models::HealthStatus;

pub struct HealthCheckUseCase;

impl HealthCheckUseCase {
    pub fn new() -> Self {
        Self
    }

    pub async fn execute(&self) -> HealthStatus {
        HealthStatus::Healthy
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn health_check_returns_healthy() {
        let use_case = HealthCheckUseCase::new();
        let result = use_case.execute().await;
        assert!(matches!(result, HealthStatus::Healthy));
    }
}
