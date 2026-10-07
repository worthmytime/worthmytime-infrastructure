#!/usr/bin/env bash
# Pierwsze uruchomienie na serwerze: stawia Vault, inicjuje go, tworzy sekrety i uruchamia cały stack.
# Idempotentny: ponowne uruchomienie niczego nie nadpisuje (istniejące sekrety w Vaulcie zostają).
#
# Opcjonalnie: TYPESAFE_API_KEY=... ./scripts/bootstrap.sh  (inaczej skrypt zapyta)
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need docker jq openssl

echo "==> Vault: start"
compose_vault_only
wait_for_vault

echo "==> Vault: inicjalizacja"
if [ "$(vault_anon status -format=json 2>/dev/null | jq -r '.initialized')" = "true" ]; then
  echo "Już zainicjowany."
else
  umask 077
  vault_anon operator init -key-shares=1 -key-threshold=1 -format=json > "$INIT_FILE"
  echo "Klucz odpieczętowania i root token zapisano w $INIT_FILE (poza gitem)."
  echo "WAŻNE: zrób jego kopię w bezpiecznym miejscu (menedżer haseł). Bez klucza dane Vaulta są nie do odzyskania."
fi
unseal_vault

echo "==> Vault: silnik KV i polityka"
if ! vault secrets list -format=json | jq -e 'has("wmt/")' >/dev/null; then
  vault secrets enable -path=wmt -version=2 kv >/dev/null
fi
printf 'path "wmt/data/*" {\n  capabilities = ["read", "list"]\n}\n' | vault policy write wmt-read - >/dev/null

echo "==> Vault: sekrety wmt/infra"
if vault kv get -format=json wmt/infra >/dev/null 2>&1; then
  echo "Istnieją, nie nadpisuję. Zmiana pojedynczego: vault kv patch wmt/infra KLUCZ=wartość"
else
  typesafe="${TYPESAFE_API_KEY:-}"
  if [ -z "$typesafe" ]; then
    read -rsp "TYPESAFE_API_KEY (Enter = pomiń, dodasz później): " typesafe || true
    echo
  fi
  vault kv put wmt/infra \
    POSTGRES_PASSWORD="$(openssl rand -hex 24)" \
    LITELLM_DB_PASSWORD="$(openssl rand -hex 24)" \
    LITELLM_MASTER_KEY="sk-$(openssl rand -hex 24)" \
    LITELLM_SALT_KEY="sk-$(openssl rand -hex 24)" \
    TYPESAFE_API_KEY="$typesafe" >/dev/null
  echo "Wygenerowano sekrety. LITELLM_SALT_KEY nigdy nie zmieniaj po pierwszym użyciu (szyfruje klucze w bazie)."
fi

echo "==> Stack: .env z Vaulta i uruchomienie"
"$ROOT/scripts/render-env.sh"
docker compose up -d
docker compose ps
