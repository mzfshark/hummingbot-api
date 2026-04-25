#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tests=(
  "$SCRIPT_DIR/healthcheck.sh"
  "$SCRIPT_DIR/test_market_data.sh"
  "$SCRIPT_DIR/test_mqtt.sh"
  "$SCRIPT_DIR/test_latency.sh"
  "$SCRIPT_DIR/test_condor.sh"
  "$SCRIPT_DIR/test_connector.sh"
  "$SCRIPT_DIR/test_executor.sh"
)

for test in "${tests[@]}"; do
  echo "Executando $(basename "$test")..."
  bash "$test"
done

echo "✅ Todos os testes de integração foram executados"
