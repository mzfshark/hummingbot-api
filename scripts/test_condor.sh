#!/usr/bin/env bash

# Test Condor (Telegram Bot) - verifica se o bot está respondendo e registra logs
# Requer que o bot Condor esteja rodando e a variável BOT_TOKEN esteja definida

set -euo pipefail

BOT_TOKEN="${BOT_TOKEN:-YOUR_TELEGRAM_BOT_TOKEN}"
CHAT_ID="${CHAT_ID:-YOUR_TELEGRAM_CHAT_ID}"
MESSAGE="Teste de integração Condor $(date +%s)"

# Envia mensagem via Telegram Bot API
response=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d text="$MESSAGE")

ok=$(echo "$response" | jq -r '.ok')

if [[ "$ok" == "true" ]]; then
  echo "✅ Mensagem enviada ao Telegram com sucesso"
else
  echo "❌ Falha ao enviar mensagem ao Telegram"
  echo "Resposta: $response"
  exit 1
fi

# Opcional: verificar logs do container Condor (assume docker-compose service name 'condor')
if command -v docker >/dev/null 2>&1; then
  echo "--- Logs recentes do serviço Condor ---"
  docker logs --tail 20 condor || true
fi
