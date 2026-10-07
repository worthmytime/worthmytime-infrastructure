# worthmytime-infrastructure

Manifesty infrastruktury WorthMyTime. Jeden `git pull` i jedna komenda stawiają gotowe do użycia kontenery:

| Usługa | Obraz | Port (tylko loopback) | Do czego |
|---|---|---|---|
| `postgres` | `postgres:16` | 5432 | baza aplikacji (`worthmytime`) i osobna baza `litellm` |
| `litellm` | `ghcr.io/berriai/litellm` | 4000 | proxy do modeli: klucze wirtualne, koszty, pass-through do Jev (TypeSafe) |
| `vault` | `hashicorp/vault` | 8200 | sekrety: hasła, klucze API (self-hosted, storage plikowy) |

Wszystkie usługi są w sieci docker `wmt`, do której można dołączyć backend z innego compose'a:

```yaml
networks:
  wmt:
    external: true
```

Wtedy backend widzi `postgres:5432` i `litellm:4000`.

## Wymagania na serwerze

Docker z pluginem Compose, `jq`, `openssl`, `git`.

## Pierwsze uruchomienie

```bash
git clone https://github.com/worthmytime/worthmytime-infrastructure.git
cd worthmytime-infrastructure
./scripts/bootstrap.sh
```

Skrypt: startuje Vault, inicjuje go (`vault/init.json`, poza gitem), włącza silnik KV `wmt/`, generuje hasła i klucze LiteLLM, pyta o `TYPESAFE_API_KEY`, zapisuje wszystko w Vaulcie, renderuje `.env` i uruchamia stack. Jest idempotentny.

**Zrób kopię `vault/init.json` w menedżerze haseł i potem usuń ją z serwera, jeśli chcesz.** Bez klucza odpieczętowania danych Vaulta nie da się odzyskać. Uwaga: `unseal.sh` używa tego pliku, więc jeśli go usuniesz, odpieczętowujesz ręcznie (`docker compose exec vault vault operator unseal`).

## Codzienna praca

```bash
git pull
./scripts/unseal.sh          # Vault po każdym restarcie jest zapieczętowany
./scripts/render-env.sh      # tylko gdy zmieniły się sekrety w Vaulcie
docker compose up -d
```

Zmiana sekretu: `docker compose exec -e VAULT_TOKEN=... vault vault kv patch wmt/infra TYPESAFE_API_KEY=...`, potem `render-env.sh` i `docker compose up -d`.

UI Vaulta i LiteLLM (`/ui`) są tylko na `127.0.0.1`; z własnego komputera: `ssh -L 8200:127.0.0.1:8200 -L 4000:127.0.0.1:4000 serwer`.

## Jev (TypeSafe) przez LiteLLM

Klucz `TYPESAFE_API_KEY` ma tylko proxy. Aplikacja używa wirtualnego klucza LiteLLM i woła `http://litellm:4000/typesafe/...` zamiast `https://api.typesafe.ai`. Klucz wirtualny tworzysz w UI LiteLLM albo przez API (`/key/generate` z `LITELLM_MASTER_KEY`) i zapisujesz w Vaulcie (np. `wmt/backend`). Dokumentacja: [LiteLLM: TypeSafe pass-through](https://docs.litellm.ai/docs/pass_through/typesafe).

## Ograniczenia obecnej konfiguracji (świadome)

- Vault: jeden klucz odpieczętowania, TLS wyłączony (port tylko na loopback), operator używa root tokena. Przy wyjściu poza jednego serwera: Shamir 3/5, TLS, AppRole dla usług zamiast root tokena.
- Backup: wolumeny `pgdata` i `vault-data` nie są jeszcze kopiowane (osobne zadanie).
- Podłączenie backendu do `wmt` i przeniesienie jego Postgresa tutaj to osobne zmiany w `worthmytime-backend`.

Zasady pracy: [CONTRIBUTING.md](CONTRIBUTING.md).
