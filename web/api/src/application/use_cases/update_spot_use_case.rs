use std::sync::Arc;

use crate::{
    application::use_cases::spot_repository::SdzSpotRepository,
    domain::models::{sdz_validate_urls, SdzSpot, SdzSpotLocation, SdzSpotType, SdzSpotValidationError},
    presentation::error::SdzApiError,
};

pub struct SdzUpdateSpotUseCase;

impl SdzUpdateSpotUseCase {
    pub fn new() -> Self {
        Self
    }

    pub async fn execute(
        &self,
        repo: Arc<dyn SdzSpotRepository>,
        spot_id: String,
        input: UpdateSpotInput,
    ) -> Result<SdzSpot, SdzApiError> {
        let existing = repo
            .find_by_id(&spot_id)
            .await?
            .ok_or(SdzApiError::NotFound)?;

        let updated = merge_spot(existing, input).map_err(map_validation_error)?;
        repo.update(updated.clone()).await?;
        Ok(updated)
    }
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct UpdateSpotInput {
    pub name: Option<String>,
    pub description: Option<String>,
    pub location: Option<UpdateSpotLocation>,
    pub tags: Option<Vec<String>>,
    pub images: Option<Vec<String>>,
    #[serde(rename = "spotType")]
    pub spot_type: Option<String>,
    #[serde(rename = "instagramUrl")]
    pub instagram_url: Option<String>,
    #[serde(rename = "officialUrl")]
    pub official_url: Option<String>,
    #[serde(rename = "businessHours")]
    pub business_hours: Option<String>,
    pub sections: Option<Vec<String>>,
}

#[derive(Debug, Clone, serde::Deserialize)]
pub struct UpdateSpotLocation {
    pub lat: f64,
    pub lng: f64,
}

fn merge_spot(
    mut spot: SdzSpot,
    input: UpdateSpotInput,
) -> Result<SdzSpot, SdzSpotValidationError> {
    if let Some(name) = input.name {
        spot.name = name;
    }
    if let Some(desc) = input.description {
        spot.description = Some(desc);
    }
    if let Some(loc) = input.location {
        spot.location = Some(SdzSpotLocation {
            lat: loc.lat,
            lng: loc.lng,
        });
    }
    if let Some(tags) = input.tags {
        spot.tags = tags;
    }
    if let Some(images) = input.images {
        spot.images = images;
    }
    if let Some(spot_type) = input.spot_type {
        spot.sdz_spot_type = parse_spot_type_input(&spot_type);
    }
    if let Some(url) = input.instagram_url {
        spot.sdz_instagram_url = if url.is_empty() { None } else { Some(url) };
    }
    if let Some(url) = input.official_url {
        spot.sdz_official_url = if url.is_empty() { None } else { Some(url) };
    }
    sdz_validate_urls(
        spot.sdz_instagram_url.as_deref(),
        spot.sdz_official_url.as_deref(),
    )?;
    if let Some(hours) = input.business_hours {
        spot.sdz_business_hours = if hours.is_empty() { None } else { Some(hours) };
    }
    if let Some(sections) = input.sections {
        spot.sdz_sections = sections;
    }

    let offset = chrono::FixedOffset::east_opt(9 * 3600).expect("valid offset");
    spot.updated_at = chrono::Utc::now().with_timezone(&offset);

    Ok(spot)
}

fn parse_spot_type_input(value: &str) -> Option<SdzSpotType> {
    match value {
        "park" => Some(SdzSpotType::Park),
        "street" => Some(SdzSpotType::Street),
        _ => None,
    }
}

fn map_validation_error(err: SdzSpotValidationError) -> SdzApiError {
    SdzApiError::BadRequest(err.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::infrastructure::in_memory_spot_repository::SdzInMemorySpotRepository;

    async fn seed_spot(repo: &Arc<dyn SdzSpotRepository>) -> SdzSpot {
        let spot = SdzSpot::new_with_id(
            "spot-1".into(),
            "test park".into(),
            Some("desc".into()),
            None,
            vec!["park".into()],
            vec![],
            "user-1".into(),
        )
        .unwrap();
        repo.create(spot).await.unwrap()
    }

    #[tokio::test]
    async fn update_spot_name() {
        let repo: Arc<dyn SdzSpotRepository> = Arc::new(SdzInMemorySpotRepository::default());
        seed_spot(&repo).await;

        let use_case = SdzUpdateSpotUseCase::new();
        let input = UpdateSpotInput {
            name: Some("updated name".into()),
            description: None,
            location: None,
            tags: None,
            images: None,
            spot_type: None,
            instagram_url: None,
            official_url: None,
            business_hours: None,
            sections: None,
        };

        let result = use_case
            .execute(repo.clone(), "spot-1".into(), input)
            .await
            .unwrap();
        assert_eq!(result.name, "updated name");
        assert_eq!(result.description, Some("desc".into()));
    }

    #[tokio::test]
    async fn update_spot_not_found() {
        let repo: Arc<dyn SdzSpotRepository> = Arc::new(SdzInMemorySpotRepository::default());

        let use_case = SdzUpdateSpotUseCase::new();
        let input = UpdateSpotInput {
            name: Some("name".into()),
            description: None,
            location: None,
            tags: None,
            images: None,
            spot_type: None,
            instagram_url: None,
            official_url: None,
            business_hours: None,
            sections: None,
        };

        let err = use_case
            .execute(repo, "nonexistent".into(), input)
            .await
            .unwrap_err();
        assert!(matches!(err, SdzApiError::NotFound));
    }
}
