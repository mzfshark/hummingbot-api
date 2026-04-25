#!/usr/bin/env bash

# Test Latência - mede latência MQTT publicando e recebendo mensagem
# Requer mosquitto_pub/sub e broker MQTT rodando

set -euo pipefail

MQTT_HOST="${MQTT_HOST:-localhost}"
MQTT_PORT="${MQTT_PORT:-1883}"
TOPIC="test/latency"
MESSAGE="latency-$(date +%s%N)"

start=$(date +%s%3N)
mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "$TOPIC" -m "$MESSAGE" >/dev/null 2>&1
# espera a mensagem de volta
mosquitto_sub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "$TOPIC" -C 1 -W 5 >/dev/null 2>&1
end=$(date +%s%3N)

latency=$((end - start))

if [[ $latency -lt 500 ]]; then
  echo "✅ Latência MQTT dentro do esperado: ${latency}ms"
else
  echo "⚠️ Latência alta: ${latency}ms"
fi
