#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() { printf "%b%s%b\n" "$GREEN" "$1" "$NC"; }
warn() { printf "%b%s%b\n" "$YELLOW" "$1" "$NC"; }
fail() { printf "%b%s%b\n" "$RED" "$1" "$NC" >&2; exit 1; }
info() { printf "%b%s%b\n" "$BLUE" "$1" "$NC"; }

[[ "$(uname -s)" == "Linux" ]] || fail "Ambiente não suportado: requer Linux"

kernel="$(uname -r)"
ram_mb="$(awk '/MemTotal/ { print int($2 / 1024) }' /proc/meminfo)"
disk_gb="$(df -BG /opt | awk 'NR==2 { gsub(/G/, "", $4); print $4 }')"

info "Kernel detectado: ${kernel}"
info "RAM detectada: ${ram_mb} MB"
info "Espaço livre em /opt: ${disk_gb} GB"

(( ram_mb >= 8192 )) && pass "RAM >= 8GB" || warn "RAM abaixo do recomendado (8GB)"
(( disk_gb >= 20 )) && pass "Espaço livre >= 20GB" || warn "Espaço livre abaixo do recomendado (20GB)"

command -v docker >/dev/null 2>&1 || fail "Docker não encontrado"
docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 não encontrado"
command -v curl >/dev/null 2>&1 || fail "curl não encontrado"
command -v jq >/dev/null 2>&1 || warn "jq não encontrado; alguns scripts usarão fallback via python3"
command -v mosquitto_pub >/dev/null 2>&1 || warn "mosquitto-clients não encontrado"
command -v python3 >/dev/null 2>&1 || fail "python3 não encontrado"

pass "Docker disponível: $(docker --version)"
pass "Docker Compose disponível: $(docker compose version --short)"

for repo in /opt/hummingbot-api /opt/mcp-hummingbot /opt/condor; do
    [[ -d "$repo/.git" ]] && pass "Repositório encontrado: $repo" || fail "Repositório ausente: $repo"
done

ports=(8000 1883 3000 5432 8083 8088 18083)
for port in "${ports[@]}"; do
    if ss -ltn "( sport = :$port )" | tail -n +2 | grep -q .; then
        warn "Porta ${port} já está em uso"
    else
        pass "Porta ${port} disponível"
    fi
done

pass "Pré-requisitos validados"
