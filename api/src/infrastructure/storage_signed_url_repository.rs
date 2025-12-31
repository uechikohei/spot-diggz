use async_trait::async_trait;
use base64::{engine::general_purpose, Engine as _};
use chrono::{DateTime, Duration, FixedOffset, Utc};
use hex::ToHex;
use percent_encoding::{utf8_percent_encode, AsciiSet, CONTROLS};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::{
    application::use_cases::storage_repository::{
        SdzStorageRepository, SdzUploadUrlRequest, SdzUploadUrlResult,
    },
    presentation::error::SdzApiError,
};

const SDZ_STORAGE_HOST: &str = "storage.googleapis.com";
const SDZ_GCS_ALGORITHM: &str = "GOOG4-RSA-SHA256";

pub struct SdzStorageSignedUrlRepository {
    sdz_bucket: String,
    sdz_service_account_email: String,
    sdz_expires_in: u32,
    http: Client,
}

impl SdzStorageSignedUrlRepository {
    pub fn new(
        sdz_bucket: String,
        sdz_service_account_email: String,
        sdz_expires_in: u32,
    ) -> Result<Self, SdzApiError> {
        let http = Client::builder().build().map_err(|e| {
            tracing::error!("Failed to build reqwest client: {:?}", e);
            SdzApiError::Internal
        })?;
        Ok(Self {
            sdz_bucket,
            sdz_service_account_email,
            sdz_expires_in,
            http,
        })
    }

    async fn fetch_access_token(&self) -> Result<String, SdzApiError> {
        if let Ok(token) = std::env::var("SDZ_STORAGE_SIGNING_TOKEN") {
            return Ok(token);
        }
        if let Ok(token) = std::env::var("SDZ_FIRESTORE_TOKEN") {
            return Ok(token);
        }

        let metadata_url = "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token";
        let resp = self
            .http
            .get(metadata_url)
            .header("Metadata-Flavor", "Google")
            .send()
            .await
            .map_err(|e| {
                tracing::error!("Failed to fetch metadata token: {:?}", e);
                SdzApiError::Internal
            })?;

        if !resp.status().is_success() {
            let body = resp.text().await.unwrap_or_default();
            tracing::error!("Metadata token error: {}", body);
            return Err(SdzApiError::Internal);
        }

        let token = resp.json::<SdzMetadataToken>().await.map_err(|e| {
            tracing::error!("Failed to parse metadata token: {:?}", e);
            SdzApiError::Internal
        })?;

        Ok(token.access_token)
    }

    async fn sign_blob(&self, access_token: &str, payload: &str) -> Result<String, SdzApiError> {
        let url = format!(
            "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/{}:signBlob",
            self.sdz_service_account_email
        );

        let req = SdzSignBlobRequest {
            payload: general_purpose::STANDARD.encode(payload.as_bytes()),
        };

        let resp = self
            .http
            .post(url)
            .bearer_auth(access_token)
            .json(&req)
            .send()
            .await
            .map_err(|e| {
                tracing::error!("signBlob request error: {:?}", e);
                SdzApiError::Internal
            })?;

        if !resp.status().is_success() {
            let body = resp.text().await.unwrap_or_default();
            tracing::error!("signBlob error: {}", body);
            return Err(SdzApiError::Internal);
        }

        let signed = resp.json::<SdzSignBlobResponse>().await.map_err(|e| {
            tracing::error!("Failed to parse signBlob response: {:?}", e);
            SdzApiError::Internal
        })?;

        let signature_bytes = general_purpose::STANDARD
            .decode(signed.signed_blob.as_bytes())
            .map_err(|e| {
                tracing::error!("Failed to decode signedBlob: {:?}", e);
                SdzApiError::Internal
            })?;

        Ok(signature_bytes.encode_hex())
    }

    fn build_signed_url(
        &self,
        request: &SdzUploadUrlRequest,
        now: DateTime<Utc>,
        signature: &str,
    ) -> String {
        let timestamp = now.format("%Y%m%dT%H%M%SZ").to_string();
        let timestamp_query = timestamp.clone();
        let datestamp = now.format("%Y%m%d").to_string();
        let scope = format!("{}/auto/storage/goog4_request", datestamp);
        let credential = format!("{}/{}", self.sdz_service_account_email, scope);

        let mut query_params = vec![
            (
                "X-Goog-Algorithm".to_string(),
                SDZ_GCS_ALGORITHM.to_string(),
            ),
            ("X-Goog-Credential".to_string(), credential),
            ("X-Goog-Date".to_string(), timestamp_query),
            (
                "X-Goog-Expires".to_string(),
                self.sdz_expires_in.to_string(),
            ),
            (
                "X-Goog-SignedHeaders".to_string(),
                "content-type;host".to_string(),
            ),
        ];

        query_params.sort();
        let canonical_query = sdz_build_query(&query_params);
        let canonical_uri = sdz_build_canonical_uri(&self.sdz_bucket, &request.sdz_object_name);

        format!(
            "https://{}{}?{}&X-Goog-Signature={}",
            SDZ_STORAGE_HOST, canonical_uri, canonical_query, signature
        )
    }

    fn build_object_url(&self, object_name: &str) -> String {
        let encoded_path = sdz_encode_path(object_name);
        format!(
            "https://{}/{}/{}",
            SDZ_STORAGE_HOST, self.sdz_bucket, encoded_path
        )
    }
}

#[async_trait]
impl SdzStorageRepository for SdzStorageSignedUrlRepository {
    async fn create_upload_url(
        &self,
        request: SdzUploadUrlRequest,
    ) -> Result<SdzUploadUrlResult, SdzApiError> {
        let now = Utc::now();
        let timestamp = now.format("%Y%m%dT%H%M%SZ").to_string();
        let timestamp_query = timestamp.clone();
        let datestamp = now.format("%Y%m%d").to_string();
        let scope = format!("{}/auto/storage/goog4_request", datestamp);
        let credential = format!("{}/{}", self.sdz_service_account_email, scope);

        let mut query_params = vec![
            (
                "X-Goog-Algorithm".to_string(),
                SDZ_GCS_ALGORITHM.to_string(),
            ),
            ("X-Goog-Credential".to_string(), credential),
            ("X-Goog-Date".to_string(), timestamp_query),
            (
                "X-Goog-Expires".to_string(),
                self.sdz_expires_in.to_string(),
            ),
            (
                "X-Goog-SignedHeaders".to_string(),
                "content-type;host".to_string(),
            ),
        ];

        query_params.sort();
        let canonical_query = sdz_build_query(&query_params);
        let canonical_uri = sdz_build_canonical_uri(&self.sdz_bucket, &request.sdz_object_name);

        let canonical_headers = format!(
            "content-type:{}\nhost:{}\n",
            request.sdz_content_type, SDZ_STORAGE_HOST
        );
        let signed_headers = "content-type;host";
        let canonical_request = format!(
            "PUT\n{}\n{}\n{}\n{}\nUNSIGNED-PAYLOAD",
            canonical_uri, canonical_query, canonical_headers, signed_headers
        );

        let canonical_hash = sdz_sha256_hex(&canonical_request);
        let string_to_sign = format!(
            "{}\n{}\n{}\n{}",
            SDZ_GCS_ALGORITHM, timestamp, scope, canonical_hash
        );

        let access_token = self.fetch_access_token().await?;
        let signature = self.sign_blob(&access_token, &string_to_sign).await?;
        let upload_url = self.build_signed_url(&request, now, &signature);
        let object_url = self.build_object_url(&request.sdz_object_name);

        let expires_at = sdz_to_jst(now + Duration::seconds(i64::from(self.sdz_expires_in)));

        Ok(SdzUploadUrlResult {
            sdz_upload_url: upload_url,
            sdz_object_url: object_url,
            sdz_object_name: request.sdz_object_name,
            sdz_expires_at: expires_at,
        })
    }
}

#[derive(Debug, Deserialize)]
struct SdzMetadataToken {
    #[serde(rename = "access_token")]
    access_token: String,
}

#[derive(Debug, Serialize)]
struct SdzSignBlobRequest {
    payload: String,
}

#[derive(Debug, Deserialize)]
struct SdzSignBlobResponse {
    #[serde(rename = "signedBlob")]
    signed_blob: String,
}

fn sdz_sha256_hex(input: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    hex::encode(hasher.finalize())
}

const SDZ_PATH_ENCODE_SET: &AsciiSet = &CONTROLS
    .add(b' ')
    .add(b'"')
    .add(b'<')
    .add(b'>')
    .add(b'`')
    .add(b'#')
    .add(b'?')
    .add(b'{')
    .add(b'}')
    .add(b'[')
    .add(b']')
    .add(b'%');

const SDZ_QUERY_ENCODE_SET: &AsciiSet = &CONTROLS
    .add(b' ')
    .add(b'"')
    .add(b'#')
    .add(b'$')
    .add(b'%')
    .add(b'&')
    .add(b'\'')
    .add(b'(')
    .add(b')')
    .add(b'*')
    .add(b'+')
    .add(b',')
    .add(b'/')
    .add(b':')
    .add(b';')
    .add(b'<')
    .add(b'=')
    .add(b'>')
    .add(b'?')
    .add(b'@')
    .add(b'[')
    .add(b'\\')
    .add(b']')
    .add(b'^')
    .add(b'`')
    .add(b'{')
    .add(b'|')
    .add(b'}');

fn sdz_encode_path(value: &str) -> String {
    value
        .split('/')
        .map(|segment| utf8_percent_encode(segment, SDZ_PATH_ENCODE_SET).to_string())
        .collect::<Vec<_>>()
        .join("/")
}

fn sdz_encode_query(value: &str) -> String {
    utf8_percent_encode(value, SDZ_QUERY_ENCODE_SET).to_string()
}

fn sdz_build_canonical_uri(bucket: &str, object_name: &str) -> String {
    let full_path = format!("/{}/{}", bucket, object_name);
    sdz_encode_path(&full_path)
}

fn sdz_build_query(params: &[(String, String)]) -> String {
    params
        .iter()
        .map(|(k, v)| format!("{}={}", sdz_encode_query(k), sdz_encode_query(v)))
        .collect::<Vec<_>>()
        .join("&")
}

fn sdz_to_jst(time: DateTime<Utc>) -> DateTime<FixedOffset> {
    let offset = FixedOffset::east_opt(9 * 3600).expect("valid offset");
    time.with_timezone(&offset)
}
