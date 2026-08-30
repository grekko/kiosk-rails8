# Deploy

The Docker image is built in CI, pushed to the private registry on the NAS at `diskstation.tail9a6aa.ts.net:5005`, and pulled by a Portainer stack.

The stack is managed as code in [`grekko.dsm/portainer-stacks/kiosk`](../../grekko.dsm/portainer-stacks/kiosk). Portainer is configured to pull from that repo — deploys happen by editing the image tag in that stack's `.env`, committing, and pushing.

## Problem: Portainer CE cannot force-repull `:latest`

Portainer CE (Community Edition) has no "Re-pull image and redeploy" toggle — that switch is a Business feature. With a mutable tag like `:latest`, Portainer sees the image reference unchanged and reuses the cached layer instead of fetching the new digest we just pushed. The UI redeploy is a no-op in that case.

Workarounds (manual pull, "Recreate with pull latest", SSH + `docker compose pull`) work but are easy to forget and push the problem onto the human.

## Fix: immutable, commit-SHA tags

Tag each build with the short git SHA. Every push produces a new, unique tag. Updating the stack means editing the image reference to the new tag — Portainer sees a changed reference and pulls, regardless of edition.

Benefits:

- Deploys are deterministic. `kiosk:ab12cd3` on the NAS always corresponds to that exact commit.
- Rollback is a one-line stack edit to the prior SHA.
- No cache-invalidation fights with Portainer.

The SHA is also baked into the image as `KIOSK_SHA` and reported to Sentry as the release, so an error points at the deploy that produced it.

## Automatic deploys

[`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml) runs on every push to `main`, gated on CI. It:

1. waits for the CI workflow to finish and exits unless the conclusion is `success`,
2. checks out the exact commit CI went green on — not the branch head, which may already have moved,
3. joins the tailnet via a Tailscale OAuth client tagged `tag:ci`, which is how the runner reaches the NAS registry at all,
4. builds and pushes `kiosk:<sha>` and `kiosk:latest`,
5. bumps `KIOSK_TAG` in the stack repo's `.env` and pushes.

`concurrency: deploy` serialises runs so two merges in quick succession can't race to pin the tag.

It can also be triggered by hand from the Actions tab (`workflow_dispatch`), which skips the CI gate and deploys whatever is on `main`.

### Required secrets

| Secret | Purpose |
| --- | --- |
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth client, `tag:ci` — reaching the registry |
| `TS_OAUTH_SECRET` | ditto |
| `DSM_DEPLOY_TOKEN` | PAT with write access to `grekko/dsm` — committing the tag bump |

The registry itself is unauthenticated; tailnet membership is the access control.

## Manual deploys

`script/deploy` does the same thing from a laptop, and stays as the escape hatch for when CI is down or the tailnet is misbehaving. It expects `grekko.dsm` checked out as a sibling directory, refuses to run on a dirty tree, and no-ops when the stack is already pinned to the current SHA. `script/build` is the build-and-push half on its own.

Both push `:latest` as a convenience pointer — it's never used for deploys, only for ad-hoc `docker run` against the registry.

## Rollback

Set `KIOSK_TAG` back to the prior SHA in `grekko.dsm/portainer-stacks/kiosk/.env`, commit, push. Portainer redeploys on its next git-poll interval. No rebuild — old tags stay in the registry.

## Cleanup

The registry will accumulate tags. Periodically prune old SHA tags from the registry UI on the NAS (keep the last N, or anything referenced by a running stack on any host).
