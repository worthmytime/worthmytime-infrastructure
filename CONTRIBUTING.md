# Jak pracujemy

Te same zasady co w `worthmytime-backend` i `worthmytime-frontend`:

> **issue = branch = pull request = merge = zamknięcie zadania = usunięcie brancha**

1. Issue (utwórz, jeśli brak).
2. Branch z aktualnego `dev`: `<typ>/<numer-issue>-<opis>` (typy: `feature`, `fix`, `chore`, `docs`, `refactor`, `test`).
3. PR do `dev` z `Closes #<numer>` w opisie. Kontrole: `test` (walidacja compose, shellcheck) i `pr-policy`.
4. *Squash and merge* do `dev`. Wydania `dev` -> `stage` -> `main` robi tylko właściciel (`poewer`) merge commitem; potem synchronizacja wsteczna `main` -> `dev` i `main` -> `stage`.

Pełny opis (gałęzie, wydania, sprzątanie): [CONTRIBUTING w backendzie](https://github.com/worthmytime/worthmytime-backend/blob/main/CONTRIBUTING.md).

## Zasady specyficzne dla infrastruktury

- **Żadnych sekretów w repo.** Hasła i klucze API żyją w Vaulcie (`wmt/infra`); plik `.env` jest generowany i ignorowany przez git.
- Obrazy przypinaj do wersji (`LITELLM_TAG`, `VAULT_TAG`), gdy stack idzie na produkcję; zmiana wersji to osobny PR.
- Zmiana wymagająca ręcznych kroków na serwerze (np. migracja, nowy sekret) musi je opisywać w README.
