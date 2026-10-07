#!/usr/bin/env bash
# Wspólne funkcje skryptów. Nie uruchamiać bezpośrednio.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INIT_FILE="$ROOT/vault/init.json"
cd "$ROOT"

need() {
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || { echo "Brak polecenia: $c" >&2; exit 1; }
  done
}

# Token operatora: zmienna VAULT_TOKEN albo root token z vault/init.json (tworzy go bootstrap.sh).
vault_token() {
  if [ -n "${VAULT_TOKEN:-}" ]; then
    printf '%s' "$VAULT_TOKEN"
  elif [ -f "$INIT_FILE" ]; then
    jq -r '.root_token' "$INIT_FILE"
  else
    echo "Brak VAULT_TOKEN i pliku $INIT_FILE" >&2
    exit 1
  fi
}

# vault <args...>: CLI Vaulta wewnątrz kontenera, z tokenem operatora.
vault() {
  docker compose exec -T -e VAULT_TOKEN="$(vault_token)" vault vault "$@"
}

# vault_anon <args...>: bez tokena (status, init, unseal).
vault_anon() {
  docker compose exec -T vault vault "$@"
}

# Compose wymaga zmiennych tajnych przy interpolacji całego pliku, także gdy startujemy sam Vault.
compose_vault_only() {
  POSTGRES_PASSWORD=x LITELLM_DB_PASSWORD=x LITELLM_MASTER_KEY=x LITELLM_SALT_KEY=x \
    docker compose up -d vault
}

wait_for_vault() {
  local out
  for _ in $(seq 1 30); do
    # status kończy się kodem 2 dla zapieczętowanego Vaulta; liczy się tylko, że API odpowiada
    out="$(vault_anon status 2>&1 || true)"
    if grep -q Initialized <<<"$out"; then return 0; fi
    sleep 2
  done
  echo "Vault nie odpowiada" >&2
  exit 1
}

vault_is_sealed() {
  [ "$(vault_anon status -format=json 2>/dev/null | jq -r '.sealed')" = "true" ]
}

unseal_vault() {
  if vault_is_sealed; then
    vault_anon operator unseal "$(jq -r '.unseal_keys_b64[0]' "$INIT_FILE")" >/dev/null
    echo "Vault odpieczętowany."
  fi
}
