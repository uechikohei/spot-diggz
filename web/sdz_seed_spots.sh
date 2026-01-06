SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDZ_SAMPLE_DIR="${SCRIPT_DIR}/sample"
export SDZ_SAMPLE_DIR

cat <<'EOF' > /tmp/sdz_seed_spots.sh
#!/usr/bin/env bash
set -euo pipefail

# ===== 必要な環境変数 =====
# .env を読んでいる前提
: "${YOUR_FIREBASE_WEB_API_KEY:?missing}"
: "${TEST_USER_ID:?missing}"
: "${TEST_USER_PASSWORD:?missing}"
: "${SDZ_SAMPLE_DIR:?missing}"

SDZ_PROJECT_ID="sdz-dev"
SDZ_API_URL="https://sdz-dev-api-btg4pixilq-an.a.run.app"

# Firestore REST用トークン（削除処理にのみ使用）
FIRESTORE_TOKEN="$(gcloud auth print-access-token)"

# Firebase IDトークン取得（API用）
payload="$(jq -n --arg email "${TEST_USER_ID}" --arg password "${TEST_USER_PASSWORD}" \
  '{email:$email,password:$password,returnSecureToken:true}')"

SDZ_ID_TOKEN="$(curl -sS \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${YOUR_FIREBASE_WEB_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${payload}" | jq -r '.idToken')"

echo "ID token length: ${#SDZ_ID_TOKEN}"

# ===== 1) Firestore /spots を全削除 =====
echo "Delete all spots..."
list="$(curl -sS -H "Authorization: Bearer ${FIRESTORE_TOKEN}" \
  "https://firestore.googleapis.com/v1/projects/${SDZ_PROJECT_ID}/databases/(default)/documents/spots?pageSize=200")"

echo "${list}" | jq -r '.documents[]?.name' | while read -r doc; do
  id="$(echo "${doc}" | awk -F/ '{print $NF}')"
  curl -sS -X DELETE \
    "https://firestore.googleapis.com/v1/projects/${SDZ_PROJECT_ID}/databases/(default)/documents/spots/${id}" \
    -H "Authorization: Bearer ${FIRESTORE_TOKEN}" >/dev/null
  echo "deleted ${id}"
done

# ===== 2) 画像アップロード → APIでスポット作成 =====
spots=(
  "dev-smoke-1|${SDZ_SAMPLE_DIR}/dev-smoke-1.png|35.6812|139.7671"
  "dev-smoke-2|${SDZ_SAMPLE_DIR}/dev-smoke-2.png|35.6812|139.7671"
  "dev-smoke-3|${SDZ_SAMPLE_DIR}/dev-smoke-3.png|35.6812|139.7671"
  "dev-smoke-spot|${SDZ_SAMPLE_DIR}/dev-smoke-spot.png|35.6812|139.7671"
)

for item in "${spots[@]}"; do
  IFS='|' read -r name file lat lng <<< "${item}"

  echo "upload url: ${name}"
  upload="$(curl -sS -X POST "${SDZ_API_URL}/sdz/spots/upload-url" \
    -H "Authorization: Bearer ${SDZ_ID_TOKEN}" \
    -H "X-SDZ-Client: ios" \
    -H "Content-Type: application/json" \
    -d '{"contentType":"image/png"}')"

  upload_url="$(echo "${upload}" | jq -r '.uploadUrl')"
  object_url="$(echo "${upload}" | jq -r '.objectUrl')"

  if [ -z "${upload_url}" ] || [ "${upload_url}" = "null" ]; then
    echo "ERROR: uploadUrl missing for ${name}"
    echo "${upload}"
    exit 1
  fi

  curl -sS -X PUT "${upload_url}" \
    -H "Content-Type: image/png" \
    --upload-file "${file}" > /dev/null

  body="$(jq -n \
    --arg name "${name}" \
    --arg desc "dev seed data" \
    --argjson lat "${lat}" \
    --argjson lng "${lng}" \
    --arg url "${object_url}" \
    '{name:$name,description:$desc,location:{lat:$lat,lng:$lng},tags:["smoke","dev"],images:[$url]}')"

  curl -sS -X POST "${SDZ_API_URL}/sdz/spots" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${SDZ_ID_TOKEN}" \
    -H "X-SDZ-Client: ios" \
    -d "${body}" | jq '.spotId'

  echo "seeded: ${name}"
done
EOF

bash /tmp/sdz_seed_spots.sh
