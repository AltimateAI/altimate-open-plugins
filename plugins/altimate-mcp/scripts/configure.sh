#!/usr/bin/env bash
# Register the Altimate MCP in Claude Code and/or Codex at user level.
#
# The API key is never written to a config file: Claude Code expands
# ${ALTIMATE_API_KEY} at runtime and Codex reads it through
# bearer_token_env_var. Tenant and timezone are written as plain header values
# because they are not secret. The team is not part of the connection: the
# agent passes it as the `team` argument of each tool call.
set -euo pipefail

DEFAULT_URL="https://mcp.getaltimate.com/mcp"

usage() {
  cat <<'EOF'
Usage: configure.sh [options]

Registers the Altimate MCP for the current user.

Options:
  --client claude|codex|both  Which client to configure (default: both found on PATH)
  --tenant NAME               Tenant name (default: $ALTIMATE_TENANT)
  --url URL                   MCP endpoint (default: $ALTIMATE_MCP_URL or production)
  --timezone ZONE             IANA timezone (default: $ALTIMATE_TIMEZONE or UTC)
  --name NAME                 Server name (default: altimate-user)
  --key-env VAR               Environment variable holding the API key
                              (default: ALTIMATE_API_KEY)
  --remove                    Remove the server instead of adding it
  -h, --help                  Show this help

The API key must be in the environment variable named by --key-env whenever the
client starts. It is never written to disk by this script.
EOF
}

client=""; tenant="${ALTIMATE_TENANT:-}"
url="${ALTIMATE_MCP_URL:-$DEFAULT_URL}"; tz="${ALTIMATE_TIMEZONE:-UTC}"
# The plugin's bundled server is called "altimate"; the default name here keeps
# this registration from colliding with it.
name="altimate-user"; key_env="ALTIMATE_API_KEY"; remove=0

while [ $# -gt 0 ]; do
  case "$1" in
    --client) client="${2:?--client needs a value}"; shift 2 ;;
    --tenant) tenant="${2:?--tenant needs a value}"; shift 2 ;;
    --url) url="${2:?--url needs a value}"; shift 2 ;;
    --timezone) tz="${2:?--timezone needs a value}"; shift 2 ;;
    --name) name="${2:?--name needs a value}"; shift 2 ;;
    --key-env) key_env="${2:?--key-env needs a value}"; shift 2 ;;
    --remove) remove=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$name" in *[!A-Za-z0-9_-]*|"") echo "Server name may use letters, digits, '-' and '_' only." >&2; exit 2 ;; esac
case "$key_env" in *[!A-Za-z0-9_]*|"") echo "--key-env must be an environment variable name." >&2; exit 2 ;; esac

clients=()
case "$client" in
  claude|codex) clients=("$client") ;;
  both) clients=(claude codex) ;;
  "") for c in claude codex; do command -v "$c" >/dev/null 2>&1 && clients+=("$c"); done ;;
  *) echo "--client must be claude, codex or both." >&2; exit 2 ;;
esac
if [ ${#clients[@]} -eq 0 ]; then
  echo "Neither the claude nor the codex command was found on PATH." >&2; exit 1
fi
for c in "${clients[@]}"; do
  command -v "$c" >/dev/null 2>&1 || { echo "The $c command was not found on PATH." >&2; exit 1; }
done

if [ "$remove" -eq 0 ]; then
  [ -n "$tenant" ] || { echo "Set --tenant or ALTIMATE_TENANT." >&2; exit 2; }
  case "$url" in https://*|http://localhost*|http://127.0.0.1*) ;; *) echo "--url must be https." >&2; exit 2 ;; esac
  if [ -z "${!key_env:-}" ]; then
    echo "Note: \$$key_env is not set in this shell. Set it in your shell profile before starting the client." >&2
  fi
fi

remove_claude() { claude mcp remove "$name" -s user >/dev/null 2>&1 || true; }

add_claude() {
  remove_claude
  local args=(mcp add --transport http --scope user "$name" "$url"
    --header "Authorization: Bearer \${$key_env}"
    --header "X-Tenant: $tenant"
    --header "X-Timezone: $tz")
  claude "${args[@]}"
}

codex_config() { echo "${CODEX_HOME:-$HOME/.codex}/config.toml"; }

remove_codex() { codex mcp remove "$name" >/dev/null 2>&1 || true; }

add_codex() {
  remove_codex
  codex mcp add "$name" --url "$url" --bearer-token-env-var "$key_env"
  # codex mcp add has no header option; append the header table it reads.
  python3 - "$(codex_config)" "$name" "$tenant" "$tz" <<'PY'
import json, sys
path, name, tenant, tz = sys.argv[1:5]
headers = {"X-Tenant": tenant, "X-Timezone": tz}
lines = [f"\n[mcp_servers.{name}.http_headers]"]
lines += [f"{json.dumps(k)} = {json.dumps(v)}" for k, v in headers.items()]
with open(path, "a", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
PY
}

for c in "${clients[@]}"; do
  if [ "$remove" -eq 1 ]; then
    "remove_$c"; echo "Removed $name from $c."
  else
    "add_$c"; echo "Registered $name in $c for tenant $tenant."
  fi
done
[ "$remove" -eq 1 ] || echo "Restart the client, then ask it a cost question to check the connection."
