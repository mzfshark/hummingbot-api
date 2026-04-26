# Trinity Integration Guide

O Trinity roda fora do Docker e conversa com a stack Axodus por REST, MQTT e, opcionalmente, MCP HTTP.

## REST API

Base URL:

```text
http://localhost:8000
```

Credenciais: use `USERNAME` e `PASSWORD` de `.env.hummingbot`.

Imagem default de deploy:

- `HBOT_IMAGE` em `.env.hummingbot` define a imagem usada quando o deploy nao envia `image`.
- Default recomendado: `hummingbot/hummingbot:development` (buildado localmente do repo em `TRADINGBOT_PATH`).

Fluxos principais:

1. Health:
   `GET /health`
2. Listar accounts:
   `GET /accounts/`
3. Descobrir connectors:
   `GET /connectors/`
4. Criar conta lógica para a API:
   `POST /accounts/add-account?account_name={account_name}`
5. Adicionar credenciais:
   `POST /accounts/add-credential/{account_name}/{connector_name}`
6. Criar executor:
   `POST /executors/`
7. Consultar market data:
   `POST /market-data/candles`

Exemplo em Python:

```python
import requests

session = requests.Session()
session.auth = ("admin", "your_api_password")

health = session.get("http://localhost:8000/health", timeout=10)
health.raise_for_status()

accounts = session.get("http://localhost:8000/accounts/", timeout=10)
accounts.raise_for_status()
print(accounts.json())
```

## MQTT

Broker:

```text
host=localhost
port=1883
```

Credenciais do Trinity: usar `MQTT_USERNAME` e `MQTT_PASSWORD` de `.env.trinity`.

Tópicos que a suite libera para o Trinity:

- `trinity/commands` (publish)
- `hummingbot/#` (subscribe)
- `hbot/#` (subscribe; contrato nativo do Hummingbot)
- `data/#` (subscribe)

Exemplo em Python com `paho-mqtt`:

```python
import paho.mqtt.client as mqtt

client = mqtt.Client()
client.username_pw_set("trinity_user", "your_trinity_mqtt_password")
client.connect("localhost", 1883, 30)
client.subscribe("hummingbot/#")
client.subscribe("hbot/#")
client.publish("trinity/commands", '{"action":"healthcheck"}')
client.loop_start()
```

## MCP HTTP

Endpoint:

```text
http://localhost:3000/mcp
```

Health:

```text
http://localhost:3000/health
```

O MCP local usa o repositório [mcp-hummingbot](/opt/mcp-hummingbot) com transporte HTTP habilitado para integração externa.

Sessao (para harnesses REST):

- Login: `POST http://localhost:3000/auth/login` com JSON `{"username": "...", "password": "..."}` retorna `session_id`.
- Deploy v2 controllers: `POST http://localhost:3000/deploy/v2/controllers` com `Authorization: Bearer <session_id>` e payload do Hummingbot API.
- Deploy v2 script: `POST http://localhost:3000/deploy/v2/script` com `Authorization: Bearer <session_id>` e payload do Hummingbot API.

Exemplo via CLI (host Linux):

```bash
cd /opt/hummingbot-api
SESSION_ID="$(./scripts/mcp_login.sh)"

curl -sS -X POST http://localhost:3000/deploy/v2/controllers \
  -H "Authorization: Bearer ${SESSION_ID}" \
  -H "Content-Type: application/json" \
  -d '{
    "instance_name": "paper_bot_001",
    "credentials_profile": "master_account",
    "controllers_config": ["example_grid_controller"]
  }'
```

## Condor

Documentação HTTP do Condor:

```text
http://localhost:8088/docs
```

Schema OpenAPI:

```text
http://localhost:8088/openapi.json
```

Autenticacao para chamadas `GET/POST /api/v1/...`:

- Opcao 1 (interativo): gerar token via Telegram (`/web`) e trocar por JWT em `POST /api/v1/auth/token-login`.
- Opcao 2 (automatizado): definir `CONDOR_TOKEN` no ambiente do Condor e chamar com `Authorization: Bearer <CONDOR_TOKEN>`.

Exemplo (automatizado):

```bash
curl -sS http://localhost:8088/api/v1/servers \
  -H "Authorization: Bearer ${CONDOR_TOKEN}"
```

## Pré-condições para testes de trading

- credenciais reais ou testnet da exchange
- `TELEGRAM_TOKEN` configurado para o Condor
- `ADMIN_USER_ID` configurado para o Condor
- Gateway externo disponível em `http://host.docker.internal:15888` se você usar conectores DEX/Gateway
- Para estrategias v2 novas (codigo): repo do Tradingbot clonado no host em `TRADINGBOT_PATH` (default: `/opt/tradingbot`) e imagem `HBOT_IMAGE` buildada localmente.
