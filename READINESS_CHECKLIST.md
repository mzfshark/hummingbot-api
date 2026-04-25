# Axodus Trading Suit Readiness Checklist

## Infraestrutura

- [ ] `docker compose ps` mostra `hummingbot-postgres`, `hummingbot-broker`, `hummingbot-api`, `mcp-server` e `condor`
- [ ] `http://localhost:8000/health` responde `200`
- [ ] `http://localhost:3000/health` responde `200`
- [ ] `http://localhost:18083/status` responde `200`
- [ ] `http://localhost:8088/health` responde `200`
- [ ] `docker exec hummingbot-postgres pg_isready ...` responde com sucesso

## Banco e seed

- [ ] `scripts/seed-data.sql` foi aplicado sem erro
- [ ] `account_states` contém ao menos `master_account`
- [ ] tabelas auxiliares (`supported_connectors`, `executor_types`, `system_config`, `supported_trading_pairs`) existem

## MQTT / EMQX

- [ ] `scripts/configure_emqx.sh` executou com sucesso
- [ ] usuários `hummingbot_api`, `mcp_user`, `condor_user`, `data_collector` e `trinity_user` existem
- [ ] ACLs foram gravadas no built-in authorization do EMQX
- [ ] `scripts/test_mqtt.sh` passou
- [ ] `scripts/test_latency.sh` ficou abaixo de 100ms em ambiente local

## API / MCP / Condor

- [ ] autenticação HTTP da API funciona em `/accounts/`
- [ ] market data funciona em `POST /market-data/candles`
- [ ] MCP HTTP está disponível em `http://localhost:3000/mcp`
- [ ] Condor publica dashboard em `http://localhost:8088`

## Testes dependentes de segredo

- [ ] `scripts/test_connector.sh` executado com credenciais reais/testnet
- [ ] `scripts/test_executor.sh` executado com connector válido
- [ ] `scripts/test_condor.sh` enviou mensagem no Telegram

## Documentação

- [ ] [docs/SETUP.md](/opt/hummingbot-api/docs/SETUP.md) revisado
- [ ] [docs/TRINITY_INTEGRATION.md](/opt/hummingbot-api/docs/TRINITY_INTEGRATION.md) revisado
- [ ] [.env.example](/opt/hummingbot-api/.env.example) revisado
