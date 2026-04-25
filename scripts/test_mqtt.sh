#!/usr/bin/env bash

# Test MQTT Pub/Sub - verifica comunicação entre containers via MQTT
# Requer que o broker MQTT (EMQX) esteja rodando e a variável MQTT_HOST esteja definida

set -euo pipefail

MQTT_HOST="${MQTT_HOST:-localhost}"
MQTT_PORT="${MQTT_PORT:-1883}"
TOPIC="test/integration"
MESSAGE="ping-$(date +%s)"

# Publica mensagem
pub_result=$(mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "$TOPIC" -m "$MESSAGE" 2>&1 || true)

# Subscreve e verifica mensagem (timeout 5s)
sub_result=$(mosquitto_sub -h "$MQTT_HOST" -p "$MQTT_PORT" -t "$TOPIC" -C 1 -W 5 2>&1 || true)

if [[ "$sub_result" == "$MESSAGE" ]]; then
  echo "✅ MQTT Pub/Sub funcionando corretamente"
else
  echo "❌ Falha no MQTT Pub/Sub"
  echo "Publicação: $pub_result"
  echo "Subscrição: $sub_result"
  exit 1
fi
