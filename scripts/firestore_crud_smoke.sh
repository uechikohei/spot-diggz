#!/usr/bin/env bash
set -euo pipefail

api_url="${SDZ_API_URL:-http://localhost:8080}"

if [[ -z "${SDZ_ID_TOKEN:-}" ]]; then
  echo "SDZ_ID_TOKEN is required (Firebase ID token for Authorization header)." >&2
  exit 1
fi

spot_name="smoke-$(uuidgen | tr '[:upper:]' '[:lower:]')"
payload=$(cat <<EOF
{
  "name": "${spot_name}",
  "description": "smoke test",
  "location": { "lat": 35.6812, "lng": 139.7671 },
  "tags": ["smoke"],
  "images": []
}
EOF
)

echo "POST /sdz/spots"
create_response=$(curl -sS -X POST "${api_url}/sdz/spots" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${SDZ_ID_TOKEN}" \
  -H "X-SDZ-Client: ios" \
  -d "${payload}")

spot_id=$(echo "${create_response}" | jq -r '.spotId')
if [[ -z "${spot_id}" || "${spot_id}" == "null" ]]; then
  echo "failed to create spot: ${create_response}" >&2
  exit 1
fi

echo "GET /sdz/spots/${spot_id}"
curl -sS "${api_url}/sdz/spots/${spot_id}" | jq .

echo "GET /sdz/spots"
curl -sS "${api_url}/sdz/spots" | jq '.[0:3]'
