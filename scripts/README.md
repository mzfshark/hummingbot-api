# Script de Instalação Automatizada para Hummingbot, MCP_Axodus_Trading e Trinity

## Descrição
Este script automatiza a instalação e configuração do ambiente para o **Hummingbot API**, **MCP_Axodus_Trading** e o **agent Trinity**. Ele verifica e instala dependências, configura variáveis de ambiente, inicializa containers Docker e valida o setup.

## Correções Críticas de Segurança e Resiliência Implementadas

### 1. Isolamento de Rede Docker
- **Redes segregadas**: 
  - `"mcp_network"`: MCP Hummingbot Server e Trinity Agent
  - `"emqx_network"`: EMQX e serviços que precisam se comunicar com ele
  - `"backend_network"`: PostgreSQL e serviços de backend
- **Comunicação restrita**: O MCP se comunica com o EMQX apenas através de interfaces específicas
- **Isolamento completo**: Serviços não têm acesso a redes às quais não pertencem

### 2. Rollback Automatizado
- Sistema de rollback completo que desfaz todas as alterações em caso de falha
- Registra todas as etapas de instalação para reversão segura
- Remove redes Docker criadas manualmente
- Notifica o usuário sobre o rollback realizado

### 3. Validação de Healthcheck do MQTT
- Verifica se o EMQX está respondendo nas portas 1883 (MQTT) e 8083 (WebSocket)
- Testa autenticação no broker MQTT usando credenciais configuradas
- Aguarda até que o EMQX esteja pronto antes de prosseguir

### 4. Teste de Integração Final
- Envia comando de teste do MCP para o Hummingbot Engine via MQTT
- Mede o tempo de resposta e valida latência (< 500ms)
- Exibe relatório de latência antes da ativação em testnet
- Garante que a comunicação entre componentes está funcional

## Integração com o Trinity Agent

Este script configura o ambiente para integração segura com o **Trinity Agent**, permitindo:

- **Comunicação MQTT**: Tópicos dedicados para envio de ordens, status e comandos
- **Autenticação segura**: Uso das mesmas credenciais do MCP para acesso ao EMQX
- **CORS configurado**: Permite requisições da aplicação Trinity rodando em localhost
- **Firewall configurado**: Permite tráfego local para integração com o Trinity
- **Validação completa**: Testes de conexão, publicação/assinatura de tópicos e CORS

### Tópicos MQTT Configurados para o Trinity:
- `trinity/orders`: Envio de ordens de trading
- `trinity/status`: Status de execução do Trinity
- `trinity/commands`: Comandos para o MCP

### Políticas de Acesso (ACLs) para o Trinity:
- Permissão de **assinatura** nos tópicos `trinity/#`
- Permissão de **publicação** nos tópicos `trinity/#` e `hummingbot/#`
- Uso das mesmas credenciais do MCP (`mcp_user`)

## Pré-requisitos
- Sistema operacional: Linux (Ubuntu/Debian ou RHEL/CentOS)
- Hardware mínimo:
  - 4GB RAM (8GB recomendado para produção)
  - 10GB espaço em disco
  - Kernel 4.4+
- Ferramentas:
  - Git
  - Docker
  - Docker Compose

## Uso
```bash
./setup_hummingbot_mcp.sh --mode [development|production]
```

### Modos de Execução
| Modo | Descrição |
|------|-----------|
| **development** | Modo de desenvolvimento com todas as portas abertas para localhost e logs detalhados. |
| **production** | Modo de produção com firewalls configurados, redes isoladas e segurança reforçada. |

## Estrutura de Diretórios
```bash
tree -L 2 /opt/hummingbot-api
```

## Serviços Instalados
| Serviço | Descrição | Porta | URL |
|---------|-----------|-------|-----|
| Hummingbot API | API REST para gerenciamento de bots | 8000 | http://localhost:8000 |
| EMQX | Broker MQTT para comunicação em tempo real | 1883, 8083 | http://localhost:18083 |
| PostgreSQL | Banco de dados para armazenamento de dados | 5432 | - |
| Trinity Agent | Agente de IA para orquestração de operações | - | - |

## Configuração
Os arquivos de configuração são gerados automaticamente na raiz do projeto:
- `.env.hummingbot` - Configurações da API
- `.env.mcp` - Configurações do MCP
- `.env.condor` - Configurações do Condor
- `.env.trinity` - Configurações do Trinity (gerado em `/opt/hummingbot-api/trinity/`)

## Regras de Firewall Configuradas

### Modo Produção:
- **SSH**: Porta 22/TCP
- **Hummingbot API**: Porta 8000/TCP
- **MQTT**: Porta 1883/TCP
- **MQTT WebSocket**: Porta 8083/TCP
- **Tráfego Local**: Permitido apenas de 127.0.0.1 para integração com Trinity

### Modo Desenvolvimento:
- **Tráfego Local**: Permitido de 127.0.0.1 para integração com Trinity
- **Hummingbot API**: Porta 8000/TCP
- **MQTT**: Porta 1883/TCP
- **MQTT WebSocket**: Porta 8083/TCP

## Solução de Problemas

### Erro: "Container não inicia"
1. Verifique os logs: `docker logs [container_name]`
2. Reinicie os serviços: `docker-compose down && docker-compose up -d`

### Erro: "Falha na comunicação entre componentes"
1. Verifique se os containers estão em execução: `docker ps`
2. Verifique as redes Docker: `docker network inspect mcp_network`
                          `docker network inspect emqx_network`
                          `docker network inspect backend_network`
3. Teste a conectividade entre containers: `docker exec -it [container_name] ping [outro_container]`

### Erro: "Falha na integração com o Trinity"
1. Verifique se o Trinity consegue se conectar ao MQTT: `docker exec trinity-agent sh -c "python3 -c 'import paho.mqtt.client as mqtt; print(\"Teste de conexão\")'"`
2. Verifique as credenciais no arquivo `.env.trinity`
3. Teste a publicação/assinatura nos tópicos dedicados: `docker exec trinity-agent sh -c "mosquitto_pub -h emqx -u mcp_user -P [senha] -t trinity/status -m 'teste'"`

### Erro: "Porta já em uso"
1. Identifique o processo usando a porta: `sudo lsof -i :[port]`
2. Encerre o processo: `sudo kill -9 [PID]`

## Segurança
- **Credenciais**: Senhas são geradas automaticamente com complexidade mínima (12 caracteres, letras maiúsculas/minúsculas, números e caracteres especiais).
- **Firewall**: Configurado para permitir apenas tráfego essencial e local.
- **Redes**: Redes Docker segregadas para isolamento de serviços.
- **Rollback**: Em caso de falha, o script executa rollback automático para desfazer alterações.
- **CORS**: Configurado para permitir apenas requisições de origens específicas (localhost).

## Logs
Os logs são armazenados em:
- `/opt/hummingbot-api/logs` - Logs da API e serviços
- `/opt/hummingbot-api/trinity/logs` - Logs do Trinity

A rotação de logs é configurada automaticamente para manter 7 dias de histórico.

## Testes de Integração Automatizados
O script realiza os seguintes testes para validar a integração com o Trinity:

1. **Conexão MQTT**: Testa se o Trinity consegue se conectar ao EMQX
2. **Tópicos Dedicados**: Testa publicação e assinatura nos tópicos `trinity/status`
3. **CORS**: Testa se a API aceita requisições de origens permitidas
4. **Comunicação Completa**: Valida toda a cadeia de comunicação entre componentes

## Variáveis de Ambiente do Trinity
O arquivo `.env.trinity` é gerado automaticamente com as seguintes configurações:

```ini
TRINITY_AGENT_ID=trinity-agent
MQTT_BROKER_HOST=emqx
MQTT_BROKER_PORT=1883
MQTT_USERNAME=mcp_user
MQTT_PASSWORD=[senha_gerada_automaticamente]
```

**Nota**: O Trinity usa as mesmas credenciais do MCP para autenticação no EMQX, garantindo consistência e segurança.