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
TOPIC="axodus/test/$(date +%s)"
MESSAGE="ping-$(date +%s)"
TMP_FILE="$(mktemp)"

timeout 10 mosquitto_sub -h "$MQTT_HOST" -p "$MQTT_PORT" \
  -u "$MQTT_MCP_USERNAME" -P "$MQTT_MCP_PASSWORD" \
  -t "$TOPIC" -C 1 >"$TMP_FILE" &
SUB_PID=$!
sleep 1

mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" \
  -u "$MQTT_MCP_USERNAME" -P "$MQTT_MCP_PASSWORD" \
  -t "$TOPIC" -m "$MESSAGE"

wait "$SUB_PID"

if [[ "$(cat "$TMP_FILE")" == "$MESSAGE" ]]; then
  echo "✅ MQTT Pub/Sub funcionando corretamente"
else
  echo "❌ Falha no MQTT Pub/Sub"
  cat "$TMP_FILE"
  rm -f "$TMP_FILE"
  exit 1
fi

rm -f "$TMP_FILE"
