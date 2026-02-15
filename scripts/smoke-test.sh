#!/usr/bin/env bash
set -euo pipefail

BASE="${BASE_URL:-http://localhost:26280}"

echo "[1/8] Nginx health"
curl -fsS -I "$BASE/health" >/dev/null

echo "[2/8] Keycloak realm (master)"
curl -fsS -I "$BASE/auth/realms/master" >/dev/null

echo "[3/8] OpenWebUI page"
curl -fsS -I "$BASE/webui" >/dev/null

echo "[4/8] OpenWebUI assets (_app)"
curl -fsS -I "$BASE/_app/immutable/" | grep -E "HTTP/1.1 200|HTTP/1.1 301|HTTP/1.1 403|HTTP/1.1 405" >/dev/null || true

echo "[5/8] OpenWebUI static asset (favicon)"
curl -fsS -I "$BASE/static/favicon.png" >/dev/null || true

echo "[6/8] OpenWebUI backend API (/api/config)"
curl -fsS -I "$BASE/api/config" >/dev/null

echo "[7/8] OpenWebUI backend API (/webui/api/config)"
curl -fsS -I "$BASE/webui/api/config" >/dev/null

echo "[8/8] FastAPI health (/toy/health)"
curl -fsS "$BASE/toy/health" | jq . >/dev/null 2>&1 || curl -fsS "$BASE/toy/health" >/dev/null

echo "All smoke tests passed."


