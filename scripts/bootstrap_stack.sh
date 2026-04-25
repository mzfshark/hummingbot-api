#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    printf "%b%s%b\n" "$BLUE" "$1" "$NC"
}

ok() {
    printf "%b%s%b\n" "$GREEN" "$1" "$NC"
}

warn() {
    printf "%b%s%b\n" "$YELLOW" "$1" "$NC"
}

fail() {
    printf "%b%s%b\n" "$RED" "$1" "$NC" >&2
    exit 1
}

require_file() {
    local path="$1"
    [[ -f "$path" ]] || fail "Arquivo obrigatório ausente: $path"
}

source_env_file() {
    local path="$1"
    set -a
    # shellcheck disable=SC1090
    source "$path"
    set +a
}

wait_for_http() {
    local name="$1"
    local url="$2"
    local max_attempts="${3:-60}"
    local attempt=1

    until curl -fsS "$url" >/dev/null 2>&1; do
        if (( attempt >= max_attempts )); then
            fail "Timeout aguardando ${name} em ${url}"
        fi
        sleep 2
        attempt=$((attempt + 1))
    done

    ok "${name} respondeu em ${url}"
}

mkdir -p \
    bots/instances \
    bots/strategies \
    data/market \
    data/trades \
    logs \
    ssl \
    volumes/postgres \
    volumes/emqx/data \
    volumes/emqx/log \
    volumes/mcp \
    condor/data \
    condor/logs \
    condor/trading_agents

require_file ".env.postgres"
require_file ".env.mqtt"
require_file ".env.hummingbot"
require_file ".env.mcp"
require_file ".env.condor"

source_env_file ".env.postgres"
source_env_file ".env.hummingbot"
source_env_file ".env.condor"
if [[ -f ../condor/.env ]]; then
    source_env_file "../condor/.env"
fi

if [[ -z "${TELEGRAM_TOKEN:-}" ]]; then
    fail "TELEGRAM_TOKEN não configurado em .env.condor"
fi

if [[ -z "${ADMIN_USER_ID:-}" ]]; then
    fail "ADMIN_USER_ID não configurado em .env.condor"
fi

cat > condor/config.yml <<EOF
servers:
  axodus-local:
    host: hummingbot-api
    port: 8000
    username: ${USERNAME}
    password: ${PASSWORD}
default_server: axodus-local
admin_id: ${ADMIN_USER_ID}
users:
  ${ADMIN_USER_ID}:
    user_id: ${ADMIN_USER_ID}
    role: admin
    created_at: 0
    notes: Axodus bootstrap admin
server_access:
  axodus-local:
    owner_id: ${ADMIN_USER_ID}
    created_at: 0
    shared_with: {}
chat_defaults:
  ${ADMIN_USER_ID}: axodus-local
version: 1
EOF

log "Validando pré-requisitos"
./scripts/validate_prerequisites.sh

log "Subindo stack Docker"
docker compose up -d --build

log "Aguardando serviços principais"
wait_for_http "EMQX Dashboard" "http://localhost:18083/status"
wait_for_http "Hummingbot API" "http://localhost:8000/health"

log "Configurando autenticação e ACLs do EMQX"
./scripts/configure_emqx.sh

log "Aplicando seed de banco"
docker exec -i hummingbot-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < scripts/seed-data.sql >/dev/null
ok "Seed aplicado"

log "Aguardando serviços auxiliares"
wait_for_http "MCP Server" "http://localhost:3000/health"
wait_for_http "Condor" "http://localhost:8088/health"

log "Executando healthcheck final"
./scripts/healthcheck.sh

ok "Axodus Trading Suit inicializado com sucesso"
