#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

die() { echo "ERROR: $*" >&2; exit 1; }

if [[ -f ".env.mcp" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env.mcp"
  set +a
fi

MCP_HOST="${MCP_HOST:-localhost}"
MCP_PORT="${MCP_PORT:-3000}"
MCP_BASE_URL="${MCP_BASE_URL:-http://${MCP_HOST}:${MCP_PORT}}"

USERNAME="${1:-${MCP_LOGIN_USERNAME:-${HUMMINGBOT_USERNAME:-}}}"
PASSWORD="${2:-${MCP_LOGIN_PASSWORD:-${HUMMINGBOT_PASSWORD:-}}}"

[[ -n "$USERNAME" ]] || die "username ausente. Passe como arg1 ou defina MCP_LOGIN_USERNAME (ou HUMMINGBOT_USERNAME) em .env.mcp"
[[ -n "$PASSWORD" ]] || die "password ausente. Passe como arg2 ou defina MCP_LOGIN_PASSWORD (ou HUMMINGBOT_PASSWORD) em .env.mcp"

export _MCP_LOGIN_USERNAME="$USERNAME"
export _MCP_LOGIN_PASSWORD="$PASSWORD"
export _MCP_BASE_URL="$MCP_BASE_URL"

python3 - <<'PY'
import json
import os
import sys
import urllib.error
import urllib.request

base_url = os.environ.get("_MCP_BASE_URL", "http://localhost:3000").rstrip("/")
username = os.environ.get("_MCP_LOGIN_USERNAME", "").strip()
password = os.environ.get("_MCP_LOGIN_PASSWORD", "").strip()

payload = {"username": username, "password": password}
data = json.dumps(payload).encode("utf-8")
req = urllib.request.Request(
    f"{base_url}/auth/login",
    data=data,
    headers={"Content-Type": "application/json"},
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        raw = resp.read()
except urllib.error.HTTPError as e:
    body = e.read().decode("utf-8", errors="replace")
    sys.stderr.write(body + "\n")
    sys.exit(1)

try:
    parsed = json.loads(raw.decode("utf-8", errors="replace"))
except Exception:
    sys.stderr.write(raw.decode("utf-8", errors="replace") + "\n")
    sys.exit(1)

session_id = str(parsed.get("session_id", "")).strip()
if not session_id:
    sys.stderr.write(json.dumps(parsed) + "\n")
    sys.exit(1)

sys.stdout.write(session_id + "\n")
PY

