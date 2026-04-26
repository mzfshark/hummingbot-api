#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

set -a
# shellcheck disable=SC1091
source .env.condor
if [[ -f ../condor/.env ]]; then
  # shellcheck disable=SC1091
  source ../condor/.env
fi
set +a

curl -fsS http://localhost:8088/openapi.json >/dev/null
echo "✅ Condor respondeu na API web"

if [[ -n "${TELEGRAM_TOKEN:-}" && -n "${ADMIN_USER_ID:-}" ]]; then
  response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    -d chat_id="$ADMIN_USER_ID" \
    -d text="Axodus Condor integration check $(date +%s)")
  ok=$(echo "$response" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("ok", False))')
  if [[ "$ok" == "True" || "$ok" == "true" ]]; then
    echo "✅ Mensagem de verificação enviada ao Telegram"
  else
    echo "❌ Condor está online, mas o envio ao Telegram falhou"
    echo "$response"
    exit 1
  fi
else
  echo "SKIP: TELEGRAM_TOKEN/ADMIN_USER_ID não configurados"
fi

if [[ "${SHOW_CONDOR_LOGS:-0}" == "1" ]] && command -v docker >/dev/null 2>&1; then
  echo "--- Logs recentes do serviço Condor (tokens redigidos) ---"
  docker logs --tail 20 condor 2>&1 | sed -E 's#(bot)[0-9]+:[A-Za-z0-9_-]+#\1***:***#g' || true
fi
