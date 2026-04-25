#!/usr/bin/env bash

# Test Market Data - verifica endpoint /market_data/candles
# Requer que a API do Hummingbot esteja rodando e a variável HBM_API_URL esteja definida

set -euo pipefail

API_URL="${HBM_API_URL:-http://localhost:8080}"

# Parâmetros de exemplo (ajustar conforme necessário)
MARKET="ETH-USDT"
INTERVAL="1m"
START_TIME=$(date -u -d "5 minutes ago" +%s)000
END_TIME=$(date -u +%s)000

response=$(curl -s -w "%{http_code}" -o /tmp/market_data.json "$API_URL/market_data/candles?market=$MARKET&interval=$INTERVAL&start_time=$START_TIME&end_time=$END_TIME")

if [[ "$response" -eq 200 ]]; then
  count=$(jq '. | length' /tmp/market_data.json)
  if [[ $count -gt 0 ]]; then
    echo "✅ Dados de mercado recebidos (${count} candles)"
  else
    echo "❌ Endpoint retornou 200 mas sem candles"
    exit 1
  fi
else
  echo "❌ Falha ao acessar endpoint market_data (HTTP $response)"
  cat /tmp/market_data.json
  exit 1
fi
