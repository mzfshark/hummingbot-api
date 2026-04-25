#!/usr/bin/env bash
# Script para configurar EMQX: criar usuários MQTT e ACLs

set -e

# Variáveis de ambiente esperadas
: "${MQTT_ADMIN_USER:=admin}"
: "${MQTT_ADMIN_PASSWORD:=admin_password}"
: "${MQTT_USER:=hummingbot}"
: "${MQTT_PASSWORD:=hummingbot_pass}"

# Função para executar comando dentro do container EMQX
exec_in_emqx() {
  docker exec -i hummingbot-broker "$@"
}

# Criar usuário admin (já existe por padrão, mas garantimos a senha)
exec_in_emqx /opt/emqx/bin/emqx_ctl users add "$MQTT_ADMIN_USER" "$MQTT_ADMIN_PASSWORD"

# Criar usuário para Hummingbot
exec_in_emqx /opt/emqx/bin/emqx_ctl users add "$MQTT_USER" "$MQTT_PASSWORD"

# Definir ACLs
# Permitir que o usuário admin tenha acesso total
cat <<EOF | exec_in_emqx /opt/emqx/bin/emqx_ctl acl add
user $MQTT_ADMIN_USER
topic readwrite #
EOF

# Permitir que o usuário hummingbot publique/subscriva nos tópicos necessários
cat <<EOF | exec_in_emqx /opt/emqx/bin/emqx_ctl acl add
user $MQTT_USER
topic readwrite hummingbot/#
EOF

echo "EMQX configurado com sucesso. Usuários e ACLs criados."
