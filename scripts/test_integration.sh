#!/usr/bin/env bash

# Orquestrador de testes de integração - executa todos os scripts de teste sequencialmente
# Cada script deve retornar 0 em caso de sucesso; se algum falhar, o orquestrador aborta

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tests=(
  "$SCRIPT_DIR/test_connector.sh"
  "$SCRIPT_DIR/test_executor.sh"
  "$SCRIPT_DIR/test_mqtt.sh"
  "$SCRIPT_DIR/test_market_data.sh"
  "$SCRIPT_DIR/test_latency.sh"
)

for test in "${tests[@]}"; do
  echo "=== Executando $test ==="
  if [[ -x "$test" ]]; then
    "$test"
    echo "✅ $test concluído com sucesso"
  else
    echo "❌ Script não executável ou não encontrado: $test"
    exit 1
  fi
  echo ""
done

echo "🎉 Todos os testes de integração foram concluídos com sucesso!"
