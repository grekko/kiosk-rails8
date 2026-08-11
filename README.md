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

Clients and the settlement workflow (create, update, complete, mail) are also available as an internal JSON API under `/api`, authenticated with a bearer token from the Rails credentials (`api.token`).

See [docs/api.md](docs/api.md).


## How to Deploy

The Docker image is built locally, pushed to the private registry at `192.168.178.35:5005`, and pulled by a Portainer stack managed as code in [`grekko.dsm/portainer-stacks/kiosk`](../grekko.dsm/portainer-stacks/kiosk).

Each build is tagged with the short git SHA so deploys reference an immutable image. Portainer CE has no "re-pull image" toggle, so we never rely on the mutable `:latest` tag for deploys — the stack always pins a specific SHA.

### Deploy

1. Commit all changes.
2. Run `script/deploy`. Builds + pushes SHA-tagged image, bumps `KIOSK_TAG` in the stack repo's `stack.env`, commits + pushes. Portainer redeploys on its next git-poll interval.

### Rollback

Change `KIOSK_TAG` in `grekko.dsm/portainer-stacks/kiosk/stack.env` back to the previous SHA, commit, push. No rebuild needed.

See [docs/deploy.md](docs/deploy.md) for the full rationale.
