#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0

ok() { printf "%b%s%b\n" "$GREEN" "$1" "$NC"; PASSED=$((PASSED + 1)); }
warn() { printf "%b%s%b\n" "$YELLOW" "$1" "$NC"; }
err() { printf "%b%s%b\n" "$RED" "$1" "$NC"; FAILED=$((FAILED + 1)); }
section() { printf "\n%b%s%b\n" "$BLUE" "$1" "$NC"; }

set -a
# shellcheck disable=SC1091
source .env.postgres
# shellcheck disable=SC1091
source .env.mqtt
# shellcheck disable=SC1091
source .env.hummingbot
set +a

section "1. Containers"
for container in hummingbot-postgres hummingbot-broker hummingbot-api mcp-server condor; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container")"
        if [[ "$health" == "healthy" || "$health" == "none" ]]; then
            ok "${container} está rodando (health: ${health})"
        else
            err "${container} está rodando mas health=${health}"
        fi
    else
        err "${container} não está rodando"
    fi
done

section "2. PostgreSQL"
if docker exec hummingbot-postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
    ok "PostgreSQL aceita conexões"
else
    err "PostgreSQL não aceita conexões"
fi

section "3. Hummingbot API"
if curl -fsS http://localhost:8000/health >/dev/null 2>&1; then
    ok "Health endpoint da API respondeu"
else
    err "Health endpoint da API falhou"
fi

if curl -fsS -u "$USERNAME:$PASSWORD" http://localhost:8000/accounts/ >/dev/null 2>&1; then
    ok "Autenticação da API respondeu em /accounts/"
else
    err "Autenticação da API falhou em /accounts/"
fi

section "4. EMQX"
if curl -fsS http://localhost:18083/status >/dev/null 2>&1; then
    ok "EMQX Dashboard respondeu"
else
    err "EMQX Dashboard não respondeu"
fi

section "5. MCP Server"
if curl -fsS http://localhost:3000/health >/dev/null 2>&1; then
    ok "MCP Server respondeu"
else
    err "MCP Server não respondeu"
fi

section "6. Condor"
if curl -fsS http://localhost:8088/health >/dev/null 2>&1; then
    ok "Condor respondeu"
else
    err "Condor não respondeu"
fi

section "7. MQTT"
if command -v mosquitto_pub >/dev/null 2>&1 && command -v mosquitto_sub >/dev/null 2>&1; then
    topic="axodus/healthcheck/$(date +%s)"
    payload="ok-$(date +%s)"
    tmp_file="$(mktemp)"
    timeout 10 mosquitto_sub -h localhost -p 1883 \
        -u "$MQTT_MCP_USERNAME" -P "$MQTT_MCP_PASSWORD" \
        -t "$topic" -C 1 >"$tmp_file" &
    sub_pid=$!
    sleep 1
    if mosquitto_pub -h localhost -p 1883 \
        -u "$MQTT_MCP_USERNAME" -P "$MQTT_MCP_PASSWORD" \
        -t "$topic" -m "$payload" >/dev/null 2>&1 && wait "$sub_pid"; then
        if [[ "$(cat "$tmp_file")" == "$payload" ]]; then
            ok "MQTT pub/sub validado"
        else
            err "MQTT respondeu com payload inesperado"
        fi
    else
        err "Falha no teste MQTT"
    fi
    rm -f "$tmp_file"
else
    warn "mosquitto-clients não instalado; pulando teste MQTT"
fi

printf "\nResultado: %s checks ok, %s falhas\n" "$PASSED" "$FAILED"
(( FAILED == 0 ))
