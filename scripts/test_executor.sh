#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

set -a
# shellcheck disable=SC1091
source .env.hummingbot
set +a

API_URL="${HBM_API_URL:-http://localhost:8000}"
ACCOUNT_NAME="${TEST_EXECUTOR_ACCOUNT:-integration_test}"
CONNECTOR_NAME="${TEST_EXECUTOR_CONNECTOR:-binance_testnet}"
TRADING_PAIR="${TEST_EXECUTOR_TRADING_PAIR:-BTC-USDT}"

if ! curl -fsS -u "$USERNAME:$PASSWORD" "$API_URL/accounts/$ACCOUNT_NAME/credentials" 2>/dev/null | grep -q "$CONNECTOR_NAME"; then
  echo "SKIP: configure primeiro o connector ${CONNECTOR_NAME} para ${ACCOUNT_NAME}."
  exit 0
fi

PAYLOAD="${TEST_EXECUTOR_PAYLOAD_JSON:-}"
if [[ -z "$PAYLOAD" ]]; then
  PAYLOAD=$(cat <<EOF
{
  "account_name": "$ACCOUNT_NAME",
  "executor_config": {
    "type": "position_executor",
    "connector_name": "$CONNECTOR_NAME",
    "trading_pair": "$TRADING_PAIR",
    "side": "BUY",
    "amount": "0.001",
    "triple_barrier_config": {
      "stop_loss": "0.01",
      "take_profit": "0.02",
      "time_limit": 600
    }
  }
}
EOF
)
fi

response=$(curl -s -u "$USERNAME:$PASSWORD" -o /tmp/test-executor.json -w "%{http_code}" \
  -X POST "$API_URL/executors/" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [[ "$response" == "201" ]]; then
  echo "✅ Executor criado com sucesso"
else
  echo "❌ Falha ao criar executor (HTTP $response)"
  cat /tmp/test-executor.json
  exit 1
fi
