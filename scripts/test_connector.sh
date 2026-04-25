#!/usr/bin/env bash

# Test Setup Connector - cria um connector via API
# Requer que a API do Hummingbot esteja rodando e a variável de ambiente HBM_API_URL esteja definida

set -euo pipefail

API_URL="${HBM_API_URL:-http://localhost:8080}"

# Dados do connector (exemplo genérico, ajustar conforme necessidade)
read -r -d '' PAYLOAD <<'EOF'
{
  "name": "test-connector",
  "type": "uniswap",
  "config": {
    "network": "mainnet",
    "rpc_url": "https://mainnet.infura.io/v3/YOUR_PROJECT_ID"
  }
}
EOF

response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/connectors" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

if [[ "$response" -eq 201 ]]; then
  echo "✅ Connector criado com sucesso (HTTP $response)"
else
  echo "❌ Falha ao criar connector (HTTP $response)"
  exit 1
fi
