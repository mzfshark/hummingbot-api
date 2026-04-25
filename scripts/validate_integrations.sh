#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

set -a
# shellcheck disable=SC1091
source .env.postgres
# shellcheck disable=SC1091
source .env.hummingbot
set +a

echo "Validando integrações Axodus..."

./scripts/healthcheck.sh

curl -fsS -u "$USERNAME:$PASSWORD" http://localhost:8000/connectors/ >/dev/null
echo "✓ API autenticada consegue listar connectors"

docker exec hummingbot-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT COUNT(*) FROM account_states;" >/dev/null
echo "✓ API e PostgreSQL compartilham schema esperado"

curl -fsS http://localhost:3000/health >/dev/null
echo "✓ MCP consegue alcançar a API"

curl -fsS http://localhost:8088/health >/dev/null
echo "✓ Condor expôs dashboard/health"

echo "Validação concluída."
