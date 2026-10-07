#!/usr/bin/env bash
# Zapisuje sekrety z Vaulta (wmt/infra) do .env (uprawnienia 600). Vault musi być odpieczętowany.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need docker jq

umask 077
vault kv get -format=json wmt/infra \
  | jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"' > "$ROOT/.env"
echo "Zapisano $ROOT/.env ($(wc -l < "$ROOT/.env") zmiennych)."
