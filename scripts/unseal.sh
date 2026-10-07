#!/usr/bin/env bash
# Vault po każdym restarcie kontenera/serwera jest zapieczętowany; ten skrypt go odpieczętowuje.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need docker jq

wait_for_vault
unseal_vault
vault_anon status | grep -E 'Initialized|Sealed'
