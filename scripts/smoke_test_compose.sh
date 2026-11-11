#!/usr/bin/env bash
# Author: Domonick Mack
# Date: 2026-11-10
# Description: End-to-end Docker Compose smoke test verifying MongoDB 7, Django API, Two-Way Sync, and Download Portal.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export MONGODB_HOST_PORT="${MONGODB_HOST_PORT:-27029}"
export BACKEND_HOST_PORT="${BACKEND_HOST_PORT:-8029}"
BASE_URL="${SMOKE_TEST_BASE_URL:-http://127.0.0.1:${BACKEND_HOST_PORT}}"

cd "$ROOT_DIR"

echo "========================================================"
echo " 1/5 Building & Starting Docker Compose Stack..."
echo "========================================================"
docker compose up -d --build

echo "========================================================"
echo " 2/5 Waiting for Backend & MongoDB Healthcheck..."
echo "========================================================"
MAX_RETRIES=30
COUNT=0
until curl -fsS "$BASE_URL/api/health/" >/dev/null 2>&1; do
  COUNT=$((COUNT + 1))
  if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
    echo "Error: Backend failed to become healthy within timeout."
    docker compose logs
    exit 1
  fi
  sleep 2
done

HEALTH_JSON="$(curl -fsS "$BASE_URL/api/health/")"
echo "Health response: $HEALTH_JSON"
echo "$HEALTH_JSON" | grep -q '"status":"healthy"'

echo "========================================================"
echo " 3/5 Testing Two-Way Batch Sync Endpoint (/api/sync/)..."
echo "========================================================"
SYNC_PAYLOAD='{
  "notes": [
    {
      "id": "smoke_note_001",
      "folderId": "notes",
      "title": "CI Smoke Test Note",
      "body": "Verified end-to-end with Docker Compose and MongoDB 7.",
      "tags": ["ci", "docker"],
      "isPinned": true,
      "isLocked": false,
      "checklists": [],
      "tables": [],
      "attachments": [],
      "createdAt": "2026-11-10T12:00:00Z",
      "updatedAt": "2026-11-10T12:00:00Z"
    }
  ],
  "folders": [
    {
      "id": "smoke_folder_001",
      "name": "CI Pipeline Folder",
      "account": "iCloud",
      "isSystem": false,
      "iconType": "folder",
      "createdAt": "2026-11-10T12:00:00Z",
      "updatedAt": "2026-11-10T12:00:00Z"
    }
  ],
  "lastSyncTimestamp": "2026-11-10T12:00:00Z"
}'

SYNC_RESPONSE="$(curl -fsS -X POST "$BASE_URL/api/sync/" \
  -H "Content-Type: application/json" \
  -d "$SYNC_PAYLOAD")"

echo "$SYNC_RESPONSE" | grep -q '"status":"success"'
echo "$SYNC_RESPONSE" | grep -q '"CI Smoke Test Note"'
echo "$SYNC_RESPONSE" | grep -q '"CI Pipeline Folder"'

echo "========================================================"
echo " 4/5 Verifying Note Retrieval & Cleanup (/api/notes/)..."
echo "========================================================"
NOTE_DETAIL="$(curl -fsS "$BASE_URL/api/notes/smoke_note_001/")"
echo "$NOTE_DETAIL" | grep -q '"id":"smoke_note_001"'

curl -fsS -X DELETE "$BASE_URL/api/notes/smoke_note_001/" >/dev/null
curl -fsS -X DELETE "$BASE_URL/api/folders/smoke_folder_001/" >/dev/null

echo "========================================================"
echo " 5/5 Verifying Installer Download Portal (/download/)..."
echo "========================================================"
PORTAL_HTML="$(curl -fsS "$BASE_URL/download/")"
echo "$PORTAL_HTML" | grep -q "Lusid for macOS"

echo "========================================================"
echo " E2E Docker Compose Smoke Test PASSED!"
echo "========================================================"
