# Axodus Trading Suit Setup

Este diretório agora sobe a suite real com:

- `PostgreSQL 16` em `localhost:5432`
- `EMQX 5.8` em `localhost:1883`, `localhost:8083` e `localhost:18083`
- `Hummingbot API` em `localhost:8000`
- `MCP Server` em `localhost:3000/mcp`
- `Condor` em `localhost:8088`

As redes Docker estão segregadas em:

- `axodus_backend_network`
- `axodus_emqx_network`
- `axodus_mcp_network`

## Arquivos de ambiente

Preencha estes arquivos antes do bootstrap:

- `.env.postgres`
- `.env.mqtt`
- `.env.hummingbot`
- `.env.mcp`
- `.env.condor`
- `.env.trinity` (para o agente Trinity externo)

Use [.env.example](/opt/hummingbot-api/.env.example) como referência.

Nota: o `bootstrap_stack.sh` agora garante que existe um `CONDOR_TOKEN` (service token) para automação.
Se você não definir `CONDOR_TOKEN` em `.env.condor`, ele vai gerar um automaticamente e salvar no arquivo.

## Tradingbot local (estratégias v2 novas)

Para desenvolver e deployar estratégias v2 novas (código), a suite espera um repo local do Tradingbot em:

```bash
git clone -b master https://github.com/Axodus/Tradingbot.git /opt/tradingbot
```

O bootstrap builda automaticamente a imagem `HBOT_IMAGE` (default: `hummingbot/hummingbot:development`) a partir desse path.

## Bootstrap recomendado

```bash
./scripts/bootstrap_stack.sh
```

O bootstrap faz:

1. valida pré-requisitos
2. cria diretórios runtime
3. gera `condor/config.yml`
4. sobe os containers
5. configura autenticação/ACLs do EMQX
6. aplica `scripts/seed-data.sql`
7. executa o healthcheck final

## Subida manual

```bash
docker compose up -d --build
./scripts/configure_emqx.sh
docker exec -i hummingbot-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < scripts/seed-data.sql
./scripts/healthcheck.sh
```

## Estrutura esperada

```text
/opt/hummingbot-api/
├── bots/instances/
├── bots/strategies/
├── data/market/
├── data/trades/
├── logs/
├── volumes/postgres/
├── volumes/emqx/
├── ssl/
└── condor/trading_agents/
```

## Endpoints principais

- API root: [http://localhost:8000/](http://localhost:8000/)
- API docs: [http://localhost:8000/docs](http://localhost:8000/docs)
- API health: [http://localhost:8000/health](http://localhost:8000/health)
- MCP health: [http://localhost:3000/health](http://localhost:3000/health)
- MCP endpoint: [http://localhost:3000/mcp](http://localhost:3000/mcp)
- EMQX Dashboard: [http://localhost:18083](http://localhost:18083)
- Condor OpenAPI: [http://localhost:8088/openapi.json](http://localhost:8088/openapi.json)
- Condor docs: [http://localhost:8088/docs](http://localhost:8088/docs)

## Scripts úteis

- [scripts/bootstrap_stack.sh](/opt/hummingbot-api/scripts/bootstrap_stack.sh)
- [scripts/validate_prerequisites.sh](/opt/hummingbot-api/scripts/validate_prerequisites.sh)
- [scripts/configure_emqx.sh](/opt/hummingbot-api/scripts/configure_emqx.sh)
- [scripts/healthcheck.sh](/opt/hummingbot-api/scripts/healthcheck.sh)
- [scripts/validate_integrations.sh](/opt/hummingbot-api/scripts/validate_integrations.sh)
- [scripts/test_integration.sh](/opt/hummingbot-api/scripts/test_integration.sh)
- [scripts/mcp_login.sh](/opt/hummingbot-api/scripts/mcp_login.sh) (gera `session_id` do MCP para chamadas REST)

## Observações práticas

- `test_connector.sh` e `test_executor.sh` dependem de credenciais reais de exchange/testnet.
- `test_condor.sh` depende de `TELEGRAM_TOKEN` e `ADMIN_USER_ID`.
- O MCP local agora roda em HTTP (`/mcp`) para poder ser healthchecked e consumido fora do stdio.
