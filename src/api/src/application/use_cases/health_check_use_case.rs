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
