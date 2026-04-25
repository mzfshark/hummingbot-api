#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

set -a
# shellcheck disable=SC1091
source .env.hummingbot
set +a

API_URL="${HBM_API_URL:-http://localhost:8000}"
ACCOUNT_NAME="${TEST_ACCOUNT_NAME:-integration_test}"
CONNECTOR_NAME="${TEST_CONNECTOR_NAME:-binance_testnet}"
CREDENTIALS_JSON="${TEST_CONNECTOR_CREDENTIALS_JSON:-}"

if [[ -z "$CREDENTIALS_JSON" ]]; then
  echo "SKIP: defina TEST_CONNECTOR_CREDENTIALS_JSON para testar credenciais reais."
  exit 0
fi

curl -fsS -u "$USERNAME:$PASSWORD" -X POST \
  "$API_URL/accounts/add-account?account_name=$ACCOUNT_NAME" >/dev/null 2>&1 || true

response=$(curl -s -u "$USERNAME:$PASSWORD" -o /tmp/test-connector.json -w "%{http_code}" \
  -X POST "$API_URL/accounts/add-credential/$ACCOUNT_NAME/$CONNECTOR_NAME" \
  -H "Content-Type: application/json" \
  -d "$CREDENTIALS_JSON")

if [[ "$response" != "201" && "$response" != "200" ]]; then
  echo "❌ Falha ao adicionar credenciais do connector (HTTP $response)"
  cat /tmp/test-connector.json
  exit 1
fi

if curl -fsS -u "$USERNAME:$PASSWORD" "$API_URL/accounts/$ACCOUNT_NAME/credentials" | grep -q "$CONNECTOR_NAME"; then
  echo "✅ Connector $CONNECTOR_NAME configurado para $ACCOUNT_NAME"
else
  echo "❌ O connector não apareceu na listagem de credenciais"
  exit 1
fi
