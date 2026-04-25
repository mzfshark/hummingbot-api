# Example Grid Strategy - Template para Trinity Agent

## Visão Geral

Este é um template de estratégia de Grid Trading para ser usado pelo Trinity Agent. O Grid Trading é uma estratégia que coloca ordens de compra e venda em intervalos regulares de preço, lucrando com a volatilidade lateral do mercado.

## Estrutura de Diretórios

```
condor/
└── trading_agents/
    └── example_grid_strategy/
        ├── agent.md           # Este arquivo (documentação da estratégia)
        ├── config.yaml        # Configuração da estratégia
        ├── strategy.py        # Implementação da lógica (opcional)
        └── requirements.txt   # Dependências específicas (opcional)
```

## Descrição da Estratégia

### Grid Trading Básico

O Grid Trading funciona da seguinte maneira:

1. **Definição do Grid**: Define-se um preço inferior e superior
2. **Criação das Ordens**: O capital é dividido em N níveis (grid)
3. **Execução**: Ordens de compra são colocadas abaixo do preço atual, ordens de venda acima
4. **Lucro**: Quando o preço oscila, as ordens são executadas e novas ordens são colocadas

### Parâmetros Principais

| Parâmetro | Descrição | Padrão | Range |
|-----------|-----------|--------|-------|
| `grid_levels` | Número de níveis do grid | 10 | 5-50 |
| `budget` | Orçamento total (USDT) | 1000 | >100 |
| `price_lower` | Preço inferior do grid | - | >0 |
| `price_upper` | Preço superior do grid | - | > price_lower |
| `order_quantity` | Quantidade por ordem | auto | >0 |

## Configuração (config.yaml)

O arquivo `config.yaml` deve seguir o formato abaixo (veja o arquivo `config.yaml` neste diretório para exemplo completo):

```yaml
strategy:
  name: "example_grid_strategy"
  type: "grid"
  version: "1.0.0"
  
  # Parâmetros da estratégia
  grid_levels: 10
  budget: 1000
  price_lower: 45000
  price_upper: 55000
  
  # Configurações de execução
  exchange: "binance"
  market: "BTC-USDT"
  leverage: 1
  
  # Gerenciamento de risco
  stop_loss: 5.0  # percentual
  take_profit: 10.0  # percentual
  max_drawdown: 15.0  # percentual
```

## Instruções de Uso

### 1. Preparação

Certifique-se de que o ambiente está configurado:

```bash
# Verificar se o Condor está rodando
docker ps | grep condor

# Verificar se o EMQX está acessível
mosquitto_pub -h localhost -p 1883 -u hummingbot -P <password> \
  -t "hummingbot/test" -m "test"
```

### 2. Configuração da Estratégia

Edite o arquivo `config.yaml` com seus parâmetros:

```bash
# Copie o exemplo
cp condor/trading_agents/example_grid_strategy/config.yaml \
   condor/trading_agents/my_grid_strategy/config.yaml

# Edite conforme necessário
vim condor/trading_agents/my_grid_strategy/config.yaml
```

### 3. Registro da Estratégia via API

Registre a estratégia na Hummingbot API:

```bash
# Usando curl
curl -X POST http://localhost:8000/api/v1/bots \
  -u usuario:senha \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my_grid_btc",
    "strategy": "grid_strike",
    "config": {
      "exchange": "binance",
      "market": "BTC-USDT",
      "budget": 1000,
      "grid_levels": 10,
      "price_lower": 45000,
      "price_upper": 55000
    }
  }'
```

### 4. Inicialização via Trinity Agent (MQTT)

O Trinity Agent pode iniciar a estratégia via MQTT:

```python
import json
import paho.mqtt.client as mqtt

client = mqtt.Client()
client.username_pw_set("hummingbot", "password")

client.connect("localhost", 1883, 60)

# Publicar comando de início
command = {
    "bot_id": "my_grid_btc",
    "action": "start",
    "timestamp": "2026-04-25T18:30:00Z"
}

client.publish("hummingbot/control/start", json.dumps(command))
client.disconnect()
```

### 5. Monitoramento

Monitore a execução via MQTT ou API:

```bash
# Subscrever em atualizações de status
mosquitto_sub -h localhost -p 1883 -u hummingbot -P <password> \
  -t "hummingbot/bots/my_grid_btc/status" -v

# Ou via API
curl -u usuario:senha http://localhost:8000/api/v1/bots/my_grid_btc
```

## Exemplo de Fluxo de Trabalho com Trinity

```python
# trinity_grid_deploy.py
from trinity_integration import TrinityAgent

# Inicializar Trinity
trinity = TrinityAgent(
    api_base="http://localhost:8000",
    mqtt_host="localhost",
    mqtt_port=1883
)

# 1. Analisar mercado
market_analysis = trinity.analyze_market("BTC-USDT")
current_price = market_analysis["price"]

# 2. Calcular parâmetros do grid
grid_config = {
    "exchange": "binance",
    "market": "BTC-USDT",
    "budget": 1000,
    "grid_levels": 10,
    "price_lower": current_price * 0.90,  # 10% abaixo
    "price_upper": current_price * 1.10,  # 10% acima
    "stop_loss": 5.0
}

# 3. Criar bot
bot = trinity.create_bot("trinity_grid_btc", "grid_strike", grid_config)

# 4. Iniciar via MQTT
trinity.start_bot_via_mqtt(bot["id"])

# 5. Monitorar
@trinity.on_message("hummingbot/bots/trinity_grid_btc/status")
def on_status_update(payload):
    print(f"PnL: {payload['pnl']}")
    if payload['pnl_pct'] > 10:
        trinity.stop_bot_via_mqtt(bot["id"])
```

## Formato das Mensagens

### Status Publicado pela Estratégia

```json
{
  "bot_id": "my_grid_btc",
  "strategy": "grid_strike",
  "status": "running",
  "pnl": 25.50,
  "pnl_pct": 2.55,
  "grid": {
    "levels": 10,
    "filled_orders": 3,
    "pending_orders": 7,
    "last_price": 50500.0
  },
  "positions": [
    {
      "side": "BUY",
      "price": 49500.0,
      "quantity": 0.01,
      "unrealized_pnl": 10.0
    }
  ],
  "timestamp": "2026-04-25T18:30:00Z"
}
```

### Comandos Aceitos

| Comando | Tópico | Payload |
|---------|--------|---------|
| Iniciar | `hummingbot/control/start` | `{"bot_id": "xxx", "action": "start"}` |
| Parar | `hummingbot/control/stop` | `{"bot_id": "xxx", "action": "stop"}` |
| Atualizar | `hummingbot/control/config` | `{"bot_id": "xxx", "config": {...}}` |
| Ordem Manual | `hummingbot/control/order` | `{"symbol": "BTC-USDT", "side": "BUY", ...}` |

## Solução de Problemas

### Estratégia não inicia
- Verificar se o orçamento é suficiente
- Checar logs: `docker logs condor --tail 50`
- Validar config.yaml: `python -c "import yaml; yaml.safe_load(open('config.yaml'))"`

### Ordens não estão sendo criadas
- Verificar conectividade com exchange (connector)
- Checar saldo na conta
- Validar parâmetros de preço (lower < upper)

### PnL não está sendo atualizado
- Verificar se o bot está publicando no MQTT
- Subscrever no tópico para debug: `mosquitto_sub -t "hummingbot/bots/+/status" -v`
- Checar logs da API: `docker logs hummingbot-api --tail 50`

## Métricas e KPIs

Monitore as seguintes métricas:

| Métrica | Descrição | Meta |
|---------|-----------|------|
| PnL | Lucro/Prejuízo total | > 0 |
| PnL % | Lucro/Prejuízo percentual | > 0% |
| Win Rate | Taxa de acerto | > 50% |
| Grid Utilization | % do grid preenchido | 30-70% |
| Drawdown Máx | Maior queda do pico | < 15% |
| Sharpe Ratio | Retorno ajustado ao risco | > 1.0 |

## Referências

- [Grid Trading Strategy](https://www.investopedia.com/terms/g/grid-trading.asp)
- [Hummingbot Grid Strategies](https://docs.hummingbot.org/strategies/)
- [Trinity Integration Guide](./docs/TRINITY_INTEGRATION.md)
- [Setup Documentation](./docs/SETUP.md)

## Checklist de Deploy

Antes de iniciar a estratégia, verifique:

- [ ] `config.yaml` validado (sintaxe e parâmetros)
- [ ] Saldo suficiente na exchange
- [ ] Conector configurado (Binance, etc.)
- [ ] API keys com permissões adequadas
- [ ] Stop loss configurado
- [ ] Monitoramento ativo (MQTT ou API)
- [ ] Plano de saída definido
- [ ] Testado em ambiente de simulação/homologação

---

**Nota:** Este é um template de exemplo. Ajuste os parâmetros conforme sua tolerância a risco e análise de mercado.
