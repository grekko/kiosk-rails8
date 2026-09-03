# Kiosk

Tracks Drinks, Orders, Clients and Monthly Reports, Settlements and Payments.

# Development

Secrets are managed via ENV variables. See .envrc.

## Run locally

```bash
bin/setup   # first time: install deps, prepare DB
bin/dev     # start the server (Puma) at http://localhost:3050
```

`bin/dev` loads `.env` and execs `bin/rails server`. Set the port via `PORT` in `.env` (defaults to `3050`).

## JSON API

Clients and the settlement workflow (create, update, complete, mail) are also available as an internal JSON API under `/api`, authenticated with a bearer token from the Rails credentials (`api.token`, falling back to `ENV["API_TOKEN"]`).

Call it from this repo with `KioskApi::Client` or the `script/api` CLI, both of which read `API_TOKEN` (and the optional `KIOSK_API_URL`) from `.env`:

```bash
script/api clients --active
script/api create-settlement --client-id 1 --monthly-report-id 4 --generated-at 2026-01-31 --positions 7:3
script/api complete 42 && script/api send-email 42
```

See [docs/api.md](docs/api.md).


## How to Deploy

The Docker image is built in CI, pushed to the private registry at `diskstation.tail9a6aa.ts.net:5005`, and pulled by a Portainer stack managed as code in [`grekko.dsm/portainer-stacks/kiosk`](../grekko.dsm/portainer-stacks/kiosk).

Each build is tagged with the short git SHA so deploys reference an immutable image. Portainer CE has no "re-pull image" toggle, so we never rely on the mutable `:latest` tag for deploys — the stack always pins a specific SHA.

### Deploy

Merge to `main`. Once CI is green, [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) builds + pushes the SHA-tagged image and bumps `KIOSK_TAG` in the stack repo's `.env`. Portainer redeploys on its next git-poll interval.

To deploy from a laptop instead — CI down, or you want it now — run `script/deploy` with `grekko.dsm` checked out as a sibling directory. Same steps, same result.

### Rollback

Change `KIOSK_TAG` in `grekko.dsm/portainer-stacks/kiosk/.env` back to the previous SHA, commit, push. No rebuild needed.

See [docs/deploy.md](docs/deploy.md) for the full rationale.
