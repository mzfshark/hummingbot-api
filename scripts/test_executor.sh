#!/usr/bin/env bash

# Test Executor (Grid) - cria um executor via API
# Requer que a API do Hummingbot esteja rodando e a variável de ambiente HBM_API_URL esteja definida

set -euo pipefail

API_URL="${HBM_API_URL:-http://localhost:8080}"

# Dados do executor Grid (exemplo genérico)
read -r -d '' PAYLOAD <<'EOF'
{
  "name": "test-executor-grid",
  "type": "grid",
  "config": {
    "grid_size": 10,
    "price_spacing": 0.01,
    "base_asset": "ETH",
    "quote_asset": "USDT"
  }
}
EOF

response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/executors" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [[ "$response" -eq 201 ]]; then
  echo "✅ Executor Grid criado com sucesso (HTTP $response)"
else
  echo "❌ Falha ao criar executor Grid (HTTP $response)"
  exit 1
fi
