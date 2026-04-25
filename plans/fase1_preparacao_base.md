# Fase 1: Preparação Base - Axodus Trading Suit

## Objetivo
Preparar o ambiente base para o Axodus Trading Suit, validando pré-requisitos, configurando repositórios, instalando dependências e criando a estrutura de diretórios.

## Tempo Estimado
15-30 minutos

---

## 1. Validação de Pré-requisitos

### 1.1 Sistema Operacional
- **Status Atual**: Linux 6.6.87.2-microsoft-standard-WSL2 (WSL2)
- **Requisito**: Linux (Ubuntu/Debian ou RHEL/CentOS)
- **Resultado**: ✅ Compatível

### 1.2 Hardware
| Recurso | Mínimo | Recomendado | Atual | Status |
|---------|--------|-------------|-------|--------|
| RAM | 4GB | 8GB | 14.6GB | ✅ OK |
| Disco | 10GB | 20GB+ | 962GB livre | ✅ OK |
| CPU | - | - | x86_64 | ✅ OK |

### 1.3 Portas Necessárias
| Porta | Serviço | Status |
|-------|---------|--------|
| 8000 | Hummingbot API | A verificar |
| 1883 | EMQX (MQTT) | A verificar |
| 8083 | EMQX (WebSocket) | A verificar |
| 18083 | EMQX (Dashboard) | A verificar |
| 5432 | PostgreSQL | A verificar |

### 1.4 Ferramentas
| Ferramenta | Status | Ação |
|------------|--------|------|
| Docker | ✅ Instalado (v29.4.0) | OK |
| Docker Compose | ✅ Instalado | OK |
| Git | ✅ Instalado | OK |
| Curl | ✅ Instalado | OK |

---

## 2. Clonagem de Repositórios

skip - O diretório `/opt/hummingbot-api` já contém arquivos do projeto, portanto, a clonagem pode ser pulada. Recomenda-se verificar o status do repositório atual e fazer backup se necessário antes de qualquer operação destrutiva. Confira /opt/hummingbot-api para confirmar a estrutura e os arquivos presentes.

## 3. Instalação do Docker e Docker Compose

### 3.1 Status Atual
- **Docker**: ✅ Já instalado (versão 29.4.0)
- **Docker Compose**: ✅ Instalado


---

## 4. Criação da Estrutura de Diretórios

### 4.1 Estrutura Esperada
```
/opt/hummingbot-api/
├── bots/                    # Controllers e scripts de bots
│   ├── controllers/
│   │   ├── directional_trading/
│   │   ├── market_making/
│   │   └── generic/
│   └── scripts/
├── config/                  # Arquivos de configuração
├── data/                    # Dados e banco de dados
├── database/                # Modelos e conexões
├── logs/                    # Logs da aplicação
├── models/                  # Modelos de dados
├── plans/                   # Planos de implementação
├── routers/                 # Rotas da API
├── scripts/                 # Scripts de instalação e utilitários
├── services/                # Serviços da aplicação
├── test/                    # Testes
├── utils/                   # Utilitários
├── .env.hummingbot          # Configurações da API
├── .env.mcp                 # Configurações do MCP
├── .env.trinity             # Configurações do Trinity
├── docker-compose.yml       # Configuração Docker
└── Makefile                 # Comandos automatizados
```

### 4.2 Comandos para Criar Estrutura
```bash
# Garantir que os diretórios principais existam
mkdir -p /opt/hummingbot-api/{config,data,logs,plans,test,scripts}

# Verificar estrutura atual
tree -L 2 /opt/hummingbot-api 2>/dev/null || ls -la /opt/hummingbot-api
```

---

## 5. Checklist de Execução

### Passo 1: Validar Pré-requisitos
- [x] Verificar SO (Linux WSL2)
- [x] Verificar RAM (14.6GB disponível)
- [x] Verificar espaço em disco (962GB livre)
- [ ] Verificar portas disponíveis
- [ ] Verificar Git instalado
- [ ] Verificar Curl instalado

### Passo 2: Clonar/Atualizar Repositórios
- [ ] Verificar status do repositório atual em `/opt/hummingbot-api`
- [ ] Fazer backup se necessário
- [ ] Clonar ou atualizar repositório hummingbot-api
- [ ] Verificar scripts de instalação

### Passo 3: Instalar Docker Compose
- [ ] Atualizar repositórios apt
- [ ] Instalar docker-compose
- [ ] Verificar instalação

### Passo 4: Criar Estrutura de Diretórios
- [x] Estrutura base já existe (verificar arquivos atuais)
- [ ] Criar diretórios faltantes se necessário
- [ ] Configurar permissões

---

## 6. Próximos Passos (Fase 2)
1. Configurar arquivos `.env` (hummingbot, mcp, trinity)
2. Configurar `docker-compose.yml` com redes segregadas
3. Inicializar serviços (PostgreSQL, EMQX, Hummingbot API)
4. Validar comunicação entre componentes

---

## 7. Observações Importantes
- O diretório `/opt/hummingbot-api` já contém arquivos do projeto
- O script `scripts/setup_hummingbot_mcp.sh` já existe e pode ser usado para automação
- Docker já está instalado, apenas Docker Compose precisa ser configurado
- Recomenda-se fazer backup antes de qualquer operação destrutiva
