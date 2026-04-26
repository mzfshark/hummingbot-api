# Axodus Trading Suit Readiness Checklist

## Infraestrutura

- [x] `docker compose ps` mostra `hummingbot-postgres`, `hummingbot-broker`, `hummingbot-api`, `mcp-server` e `condor`
- [x] `http://localhost:8000/health` responde `200`
- [x] `http://localhost:3000/health` responde `200`
- [x] `http://localhost:18083/status` responde `200`
- [x] `http://localhost:8088/openapi.json` responde `200`
- [x] `docker exec hummingbot-postgres pg_isready ...` responde com sucesso
- [x] `docker image inspect hummingbot/hummingbot:development` responde com sucesso (ou `HBOT_IMAGE` configurada)

## Banco e seed

- [x] `scripts/seed-data.sql` foi aplicado sem erro
- [x] `account_states` contém ao menos `master_account`
- [x] tabelas auxiliares (`supported_connectors`, `executor_types`, `system_config`, `supported_trading_pairs`) existem

## MQTT / EMQX

- [x] `scripts/configure_emqx.sh` executou com sucesso
- [x] usuários `hummingbot_api`, `mcp_user`, `condor_user`, `data_collector` e `trinity_user` existem
- [x] ACLs foram gravadas no built-in authorization do EMQX
- [x] `scripts/test_mqtt.sh` passou
- [x] `scripts/test_latency.sh` ficou abaixo de 100ms em ambiente local

## API / MCP / Condor

- [x] autenticação HTTP da API funciona em `/accounts/`
- [x] market data funciona em `POST /market-data/candles`
- [x] MCP HTTP está disponível em `http://localhost:3000/mcp`
- [x] Condor publica a API web em `http://localhost:8088/openapi.json`
- [x] deploy v2 sem `image` usa `HBOT_IMAGE` (default: `hummingbot/hummingbot:development`)

## Testes dependentes de segredo

- [x] `scripts/test_connector.sh` executado com credenciais reais/testnet (validado acesso a credentials)
- [x] `scripts/test_executor.sh` executado com connector válido (master_account com binance OK)
- [x] `scripts/test_condor.sh` enviou mensagem no Telegram

## Documentação

- [x] [docs/SETUP.md](/opt/hummingbot-api/docs/SETUP.md) revisado
- [x] [docs/TRINITY_INTEGRATION.md](/opt/hummingbot-api/docs/TRINITY_INTEGRATION.md) revisado
- [x] [.env.example](/opt/hummingbot-api/.env.example) revisado
