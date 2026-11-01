# Deploy immutable SHA-tagged images, never `:latest`

Portainer CE has no "re-pull image" option, so redeploying a stack that points at the mutable `:latest` tag reuses the cached image and does nothing. Each build is therefore tagged with its short git SHA, and the stack in `grekko/dsm` pins `KIOSK_TAG` to that SHA. A deploy is a one-line tag change, a rollback is setting the previous SHA, and every running image maps to exactly one commit (the SHA is also the Sentry release). `:latest` is still pushed, but only for ad-hoc `docker run`. Full rationale: [docs/deploy.md](../deploy.md).

## Consequences

Old tags pile up in the NAS registry and must be pruned by hand.
