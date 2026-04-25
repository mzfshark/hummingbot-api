#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

set -a
# shellcheck disable=SC1091
source .env.hummingbot
set +a

API_URL="${HBM_API_URL:-http://localhost:8000}"
CONNECTOR_NAME="${TEST_MARKET_CONNECTOR:-binance}"
TRADING_PAIR="${TEST_MARKET_PAIR:-BTC-USDT}"
INTERVAL="${TEST_MARKET_INTERVAL:-1m}"
MAX_RECORDS="${TEST_MARKET_RECORDS:-10}"

PAYLOAD=$(cat <<EOF
{
  "connector_name": "$CONNECTOR_NAME",
  "trading_pair": "$TRADING_PAIR",
  "interval": "$INTERVAL",
  "max_records": $MAX_RECORDS
}
EOF
)

response=$(curl -s -u "$USERNAME:$PASSWORD" -w "\n%{http_code}" -X POST "$API_URL/market-data/candles" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | head -n -1)

if [[ "$http_code" -eq 200 ]]; then
  count=$(echo "$body" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))' 2>/dev/null || echo "0")
  if [[ $count -gt 0 ]]; then
    echo "✅ Dados de mercado recebidos (${count} candles)"
  else
    echo "❌ Endpoint retornou 200 mas sem candles"
    exit 1
  fi
else
  echo "❌ Falha ao acessar endpoint market_data (HTTP $http_code)"
  echo "Resposta: $body"
  exit 1
fi
