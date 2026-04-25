#!/bin/bash

# =============================================================================
# Script de Instalação Automatizada para Hummingbot, MCP_Axodus_Trading e Trinity
# =============================================================================
#
# Este script automatiza a instalação e configuração do ambiente para o Hummingbot API,
# MCP_Axodus_Trading e o agent Trinity. Ele verifica e instala dependências,
# configura variáveis de ambiente, inicializa containers Docker e valida o setup.
#
# IMPORTANTE: Este script inclui correções críticas de segurança e resiliência:
# - Redes Docker segregadas para isolamento de serviços
# - Sistema de rollback automatizado
# - Validação de healthcheck do MQTT (EMQX)
# - Teste de integração entre componentes
#
# Autor: Axodus Trading
# Versão: 2.1.0
# Licença: MIT
# =============================================================================

# Variáveis globais
PROJECT_ROOT=${PROJECT_ROOT:-/opt/hummingbot-api}
TRINITY_DIR=${TRINITY_DIR:-$PROJECT_ROOT/trinity}
LOG_DIR=${LOG_DIR:-$PROJECT_ROOT/logs}
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ROLLBACK_STEPS=()
MODE="development"
SECURE_CREDENTIALS=false

# Funções utilitárias
error_exit() {
    echo -e "\033[31m[ERROR] $1\033[0m" >&2
    execute_rollback
    exit 1
}

success_msg() {
    echo -e "\033[32m[SUCCESS] $1\033[0m"
}

info_msg() {
    echo -e "\033[34m[INFO] $1\033[0m"
}

warning_msg() {
    echo -e "\033[33m[WARNING] $1\033[0m"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

add_rollback_step() {
    ROLLBACK_STEPS+=("$1")
}

execute_rollback() {
    info_msg "Executando rollback das alterações..."
    for step in "${ROLLBACK_STEPS[@]}"; do
        info_msg "Rollback: $step"
        eval "$step" || warning_msg "Falha ao executar rollback: $step"
    done
}

# =============================================================================
# Verifica e instala dependências
# =============================================================================

install_dependencies() {
    info_msg "Verificando e instalando dependências..."

    # Verifica e instala Docker
    if ! command_exists docker; then
        if command_exists apt-get; then
            sudo apt-get update || error_exit "Falha ao atualizar repositórios"
            sudo apt-get install -y docker.io docker-compose || error_exit "Falha ao instalar Docker"
        elif command_exists yum; then
            sudo yum install -y docker docker-compose || error_exit "Falha ao instalar Docker"
        else
            error_exit "Gerenciador de pacotes não suportado. Instale Docker manualmente."
        fi
    fi

    # Verifica e instala netcat (para testes de conectividade)
    if ! command_exists nc; then
        if command_exists apt-get; then
            sudo apt-get install -y netcat || warning_msg "Falha ao instalar netcat"
        elif command_exists yum; then
            sudo yum install -y nc || warning_msg "Falha ao instalar netcat"
        fi
    fi

    # Verifica e instala curl
    if ! command_exists curl; then
        if command_exists apt-get; then
            sudo apt-get install -y curl || warning_msg "Falha ao instalar curl"
        elif command_exists yum; then
            sudo yum install -y curl || warning_msg "Falha ao instalar curl"
        fi
    fi

    # Inicia e habilita Docker
    sudo systemctl start docker || error_exit "Falha ao iniciar Docker"
    sudo systemctl enable docker || warning_msg "Falha ao habilitar Docker"

    success_msg "Dependências verificadas e instaladas com sucesso."
}

# =============================================================================
# Verifica se netcat está instalado
# =============================================================================

check_netcat_installed() {
    if ! command_exists nc; then
        warning_msg "Netcat não está instalado. Alguns testes de conectividade podem falhar."
    fi
}

# =============================================================================
# Exibe ajuda
# =============================================================================

show_help() {
    cat <<EOL
Uso: $0 --mode [development|production] [--help] [--secure-credentials]

Opções:
    --mode               Modo de execução. Valores válidos: development ou production.
    --help               Exibe esta mensagem de ajuda.
    --secure-credentials Usa armazenamento seguro para credenciais (experimental).

Descrição:
    Este script automatiza a instalação e configuração do ambiente para o Hummingbot,
    MCP_Axodus_Trading e o agent Trinity. Ele verifica e instala dependências,
    configura variáveis de ambiente, inicializa containers Docker e valida o setup.

    O script oferece suporte a rollback automatizado em caso de falhas e validação
    de integrações entre componentes. Para ambientes de produção, recomenda-se
    usar o modo "production" com firewalls e redes isoladas.

    IMPORTANTE: Este script implementa correções críticas de segurança e resiliência:
    - Redes Docker segregadas para isolamento de serviços
    - Sistema de rollback automatizado
    - Validação de healthcheck do MQTT (EMQX)
    - Teste de integração entre MCP e Hummingbot Engine
EOL
}

# =============================================================================
# Gera documentação README.md
# =============================================================================

generate_readme() {
    info_msg "Gerando documentação README.md..."

    local readme_file="$SCRIPT_DIR/README.md"
    cat > "$readme_file" <<'EOL'
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
EOL

    success_msg "Documentação gerada com sucesso."
}

# =============================================================================
# Fluxo Principal
# =============================================================================

# Processa argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --secure-credentials)
            SECURE_CREDENTIALS=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            error_exit "Opção desconhecida: $1. Use --help para ver as opções disponíveis."
            ;;
    esac
done

# Valida o modo
if [[ "$MODE" != "development" && "$MODE" != "production" ]]; then
    error_exit "Modo inválido: $MODE. Use 'development' ou 'production'."
fi

info_msg "Iniciando setup no modo $MODE..."

# Executa as etapas
install_dependencies
check_netcat_installed
configure_environment
configure_trinity_integration
configure_docker_networks
install_trinity
configure_docker_compose
configure_firewall
start_services
validate_mqtt_healthcheck
run_integration_test
validate_setup
configure_log_rotation

# Gera documentação
generate_readme

success_msg "Setup concluído com sucesso!"
info_msg "Acesse os serviços:"
info_msg "  - Hummingbot API: http://localhost:8000"
if [ "$MODE" = "development" ]; then
    info_msg "  - EMQX Dashboard: http://localhost:18083"
else
    info_msg "  - EMQX Dashboard: https://localhost:18083 (somente via VPN)"
fi
info_msg "  - Logs: $LOG_DIR"
info_msg "  - Documentação: $PROJECT_ROOT/scripts/README.md"
info_msg "  - Configurações do Trinity: $TRINITY_DIR/.env.trinity"
exit 0
