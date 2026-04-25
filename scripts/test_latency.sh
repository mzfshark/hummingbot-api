#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

set -a
# shellcheck disable=SC1091
source .env.mqtt
set +a

MQTT_HOST="${MQTT_HOST:-localhost}"
MQTT_PORT="${MQTT_PORT:-1883}"
TOPIC="axodus/latency"
MESSAGE="latency-$(date +%s%N)"
TMP_FILE="$(mktemp)"

timeout 10 mosquitto_sub -h "$MQTT_HOST" -p "$MQTT_PORT" \
  -u "$MQTT_MCP_USERNAME" -P "$MQTT_MCP_PASSWORD" \
  -t "$TOPIC" -C 1 >"$TMP_FILE" &
SUB_PID=$!
sleep 1

start=$(date +%s%3N)
mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" \
  -u "$MQTT_MCP_USERNAME" -P "$MQTT_MCP_PASSWORD" \
  -t "$TOPIC" -m "$MESSAGE" >/dev/null 2>&1
wait "$SUB_PID"
end=$(date +%s%3N)

latency=$((end - start))

if [[ "$(cat "$TMP_FILE")" != "$MESSAGE" ]]; then
  echo "❌ Falha ao receber mensagem de latência"
  rm -f "$TMP_FILE"
  exit 1
fi

rm -f "$TMP_FILE"

if [[ $latency -lt 100 ]]; then
  echo "✅ Latência MQTT dentro do esperado: ${latency}ms"
else
  echo "⚠️ Latência alta: ${latency}ms"
fi
