#!/usr/bin/env bash
# Script para validar integrações entre serviços

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando validação de integrações...${NC}"

# Variáveis de ambiente
HUMMINGBOT_API_URL="${HUMMINGBOT_API_URL:-http://localhost:8000}"
EMQX_HOST="${EMQX_HOST:-localhost}"
EMQX_PORT="${EMQX_PORT:-1883}"
MQTT_USER="${MQTT_USER:-hummingbot}"
MQTT_PASSWORD="${MQTT_PASSWORD:-hummingbot_pass}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-hbot}"
POSTGRES_DB="${POSTGRES_DB:-hummingbot_api}"

# Função para verificar status
check_status() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}✓ $2${NC}"
  else
    echo -e "${RED}✗ $2${NC}"
    exit 1
  fi
}

# 1. Validar Hummingbot API
echo -e "\n${YELLOW}1. Validando Hummingbot API...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" -u admin:admin "$HUMMINGBOT_API_URL/health" || true)
if [ "$response" = "200" ] || [ "$response" = "401" ] || [ "$response" = "403" ]; then
  echo -e "${GREEN}✓ Hummingbot API está respondendo (HTTP $response)${NC}"
else
  echo -e "${YELLOW}⚠ Hummingbot API não está respondendo na porta 8000. Verifique se o serviço está rodando.${NC}"
fi

# 2. Validar EMQX MQTT Broker
echo -e "\n${YELLOW}2. Validando EMQX MQTT Broker...${NC}"
if command -v mosquitto_pub &> /dev/null; then
  # Testar publicação MQTT
  mosquitto_pub -h "$EMQX_HOST" -p "$EMQX_PORT" -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
    -t "test/integration" -m "test_message" -d 2>&1 | grep -q "Client" && \
    echo -e "${GREEN}✓ EMQX MQTT Broker está aceitando conexões${NC}" || \
    echo -e "${YELLOW}⚠ Falha ao conectar no EMQX MQTT Broker${NC}"
else
  echo -e "${YELLOW}⚠ mosquitto_pub não encontrado. Instale mosquitto-clients para testar MQTT.${NC}"
  echo -e "${YELLOW}  sudo apt-get install mosquitto-clients${NC}"
fi

# 3. Validar PostgreSQL
echo -e "\n${YELLOW}3. Validando PostgreSQL...${NC}"
if command -v pg_isready &> /dev/null; then
  pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" && \
    echo -e "${GREEN}✓ PostgreSQL está aceitando conexões${NC}" || \
    echo -e "${YELLOW}⚠ PostgreSQL não está respondendo${NC}"
else
  echo -e "${YELLOW}⚠ pg_isready não encontrado. Instale postgresql-client para testar.${NC}"
fi

# 4. Testar conexão HTTP com EMQX Dashboard
echo -e "\n${YELLOW}4. Validando EMQX Dashboard...${NC}"
emqx_response=$(curl -s -o /dev/null -w "%{http_code}" "http://$EMQX_HOST:18083/" || true)
if [ "$emqx_response" = "200" ] || [ "$emqx_response" = "301" ] || [ "$emqx_response" = "302" ]; then
  echo -e "${GREEN}✓ EMQX Dashboard está acessível${NC}"
else
  echo -e "${YELLOW}⚠ EMQX Dashboard não está acessível na porta 18083${NC}"
fi

# 5. Validar conectividade entre containers (se estiver rodando via docker-compose)
echo -e "\n${YELLOW}5. Validando conectividade entre containers...${NC}"
if docker ps | grep -q hummingbot-api && docker ps | grep -q hummingbot-broker; then
  echo -e "${GREEN}✓ Containers Docker estão rodando${NC}"
  
  # Testar se a API consegue alcançar o EMQX
  docker exec hummingbot-api ping -c 1 emqx > /dev/null 2>&1 && \
    echo -e "${GREEN}✓ hummingbot-api consegue alcançar emqx${NC}" || \
    echo -e "${YELLOW}⚠ hummingbot-api não consegue alcançar emqx${NC}"
  
  # Testar se a API consegue alcançar o PostgreSQL
  docker exec hummingbot-api ping -c 1 postgres > /dev/null 2>&1 && \
    echo -e "${GREEN}✓ hummingbot-api consegue alcançar postgres${NC}" || \
    echo -e "${YELLOW}⚠ hummingbot-api não consegue alcançar postgres${NC}"
else
  echo -e "${YELLOW}⚠ Containers Docker não estão rodando. Execute 'docker-compose up -d' primeiro.${NC}"
fi

echo -e "\n${GREEN}Validação concluída!${NC}"
