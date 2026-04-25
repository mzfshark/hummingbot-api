#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

set -a
# shellcheck disable=SC1091
source .env.mqtt
set +a

EMQX_BASE_URL="${EMQX_BASE_URL:-http://localhost:18083}"
AUTHN_ID="password_based%3Abuilt_in_database"

require() {
    local name="$1"
    [[ -n "${!name:-}" ]] || { echo "Variável obrigatória ausente: $name" >&2; exit 1; }
}

json_get() {
    python3 -c 'import json, sys; print(json.load(sys.stdin).get(sys.argv[1], ""))' "$1"
}

curl_json() {
    local method="$1"
    local url="$2"
    local body="${3:-}"
    if [[ -n "$body" ]]; then
        curl -fsS -X "$method" "$url" \
            -H "Authorization: Bearer $EMQX_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$body"
    else
        curl -fsS -X "$method" "$url" \
            -H "Authorization: Bearer $EMQX_TOKEN"
    fi
}

create_user() {
    local user_id="$1"
    local password="$2"
    local superuser="${3:-false}"
    local create_body
    create_body=$(printf '{"user_id":"%s","password":"%s","is_superuser":%s}' "$user_id" "$password" "$superuser")
    local code
    code=$(curl -s -o /tmp/emqx-user-create.json -w "%{http_code}" \
        -X POST "${EMQX_BASE_URL}/api/v5/authentication/${AUTHN_ID}/users" \
        -H "Authorization: Bearer $EMQX_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$create_body")

    case "$code" in
        200|201) ;;
        400|409)
            curl_json PUT "${EMQX_BASE_URL}/api/v5/authentication/${AUTHN_ID}/users/${user_id}" \
                "$(printf '{"password":"%s","is_superuser":%s}' "$password" "$superuser")" >/dev/null
            ;;
        *)
            echo "Falha ao criar/atualizar usuário MQTT ${user_id} (HTTP ${code})" >&2
            cat /tmp/emqx-user-create.json >&2
            exit 1
            ;;
    esac
}

replace_acl_rules() {
    local user_id="$1"
    local rules_json="$2"
    local code
    code=$(curl -s -o /tmp/emqx-acl.json -w "%{http_code}" \
        -X PUT "${EMQX_BASE_URL}/api/v5/authorization/sources/built_in_database/rules/users/${user_id}" \
        -H "Authorization: Bearer $EMQX_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$rules_json")

    if [[ "$code" == "404" ]]; then
        curl_json POST "${EMQX_BASE_URL}/api/v5/authorization/sources/built_in_database/rules/users" "[$rules_json]" >/dev/null
        return
    fi

    [[ "$code" == "200" ]] || {
        echo "Falha ao atualizar ACL do usuário ${user_id} (HTTP ${code})" >&2
        cat /tmp/emqx-acl.json >&2
        exit 1
    }
}

require EMQX_DASHBOARD_USERNAME
require EMQX_DASHBOARD_PASSWORD
require MQTT_HUMMINGBOT_USERNAME
require MQTT_HUMMINGBOT_PASSWORD
require MQTT_MCP_USERNAME
require MQTT_MCP_PASSWORD
require MQTT_CONDOR_USERNAME
require MQTT_CONDOR_PASSWORD
require MQTT_DATA_COLLECTOR_USERNAME
require MQTT_DATA_COLLECTOR_PASSWORD
require MQTT_TRINITY_USERNAME
require MQTT_TRINITY_PASSWORD

for _ in $(seq 1 30); do
    if curl -fsS "${EMQX_BASE_URL}/status" >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

LOGIN_PAYLOAD=$(printf '{"username":"%s","password":"%s"}' "$EMQX_DASHBOARD_USERNAME" "$EMQX_DASHBOARD_PASSWORD")
EMQX_TOKEN=$(curl -fsS -X POST "${EMQX_BASE_URL}/api/v5/login" -H "Content-Type: application/json" -d "$LOGIN_PAYLOAD" | json_get token)
[[ -n "$EMQX_TOKEN" ]] || { echo "Não foi possível autenticar no EMQX Dashboard" >&2; exit 1; }

if ! curl -fsS "${EMQX_BASE_URL}/api/v5/authentication/${AUTHN_ID}" -H "Authorization: Bearer $EMQX_TOKEN" >/dev/null 2>&1; then
    curl_json POST "${EMQX_BASE_URL}/api/v5/authentication" '{
      "backend": "built_in_database",
      "mechanism": "password_based",
      "password_hash_algorithm": {
        "name": "sha256",
        "salt_position": "suffix"
      },
      "user_id_type": "username"
    }' >/dev/null
fi

if ! curl -fsS "${EMQX_BASE_URL}/api/v5/authorization/sources" -H "Authorization: Bearer $EMQX_TOKEN" | grep -q 'built_in_database'; then
    curl_json POST "${EMQX_BASE_URL}/api/v5/authorization/sources" '{
      "enable": true,
      "max_rules": 100,
      "type": "built_in_database"
    }' >/dev/null
fi

create_user "$MQTT_HUMMINGBOT_USERNAME" "$MQTT_HUMMINGBOT_PASSWORD" true
create_user "$MQTT_MCP_USERNAME" "$MQTT_MCP_PASSWORD" false
create_user "$MQTT_CONDOR_USERNAME" "$MQTT_CONDOR_PASSWORD" false
create_user "$MQTT_DATA_COLLECTOR_USERNAME" "$MQTT_DATA_COLLECTOR_PASSWORD" false
create_user "$MQTT_TRINITY_USERNAME" "$MQTT_TRINITY_PASSWORD" false

replace_acl_rules "$MQTT_HUMMINGBOT_USERNAME" "{
  \"username\": \"${MQTT_HUMMINGBOT_USERNAME}\",
  \"rules\": [
    {\"topic\": \"#\", \"permission\": \"allow\", \"action\": \"all\"}
  ]
}"

replace_acl_rules "$MQTT_MCP_USERNAME" "{
  \"username\": \"${MQTT_MCP_USERNAME}\",
  \"rules\": [
    {\"topic\": \"hbot/#\", \"permission\": \"allow\", \"action\": \"subscribe\"},
    {\"topic\": \"hummingbot/#\", \"permission\": \"allow\", \"action\": \"subscribe\"},
    {\"topic\": \"trinity/commands\", \"permission\": \"allow\", \"action\": \"publish\"}
  ]
}"

replace_acl_rules "$MQTT_CONDOR_USERNAME" "{
  \"username\": \"${MQTT_CONDOR_USERNAME}\",
  \"rules\": [
    {\"topic\": \"hbot/#\", \"permission\": \"allow\", \"action\": \"subscribe\"},
    {\"topic\": \"hummingbot/#\", \"permission\": \"allow\", \"action\": \"subscribe\"},
    {\"topic\": \"trinity/commands\", \"permission\": \"allow\", \"action\": \"publish\"}
  ]
}"

replace_acl_rules "$MQTT_DATA_COLLECTOR_USERNAME" "{
  \"username\": \"${MQTT_DATA_COLLECTOR_USERNAME}\",
  \"rules\": [
    {\"topic\": \"data/#\", \"permission\": \"allow\", \"action\": \"all\"},
    {\"topic\": \"hummingbot/#\", \"permission\": \"allow\", \"action\": \"subscribe\"}
  ]
}"

replace_acl_rules "$MQTT_TRINITY_USERNAME" "{
  \"username\": \"${MQTT_TRINITY_USERNAME}\",
  \"rules\": [
    {\"topic\": \"trinity/commands\", \"permission\": \"allow\", \"action\": \"publish\"},
    {\"topic\": \"hbot/#\", \"permission\": \"allow\", \"action\": \"subscribe\"},
    {\"topic\": \"hummingbot/#\", \"permission\": \"allow\", \"action\": \"subscribe\"},
    {\"topic\": \"data/#\", \"permission\": \"allow\", \"action\": \"subscribe\"}
  ]
}"

echo "EMQX configurado com autenticação e ACLs."
