# Deploy

The Docker image is built locally, pushed to the private registry on the NAS at `192.168.178.35:5005`, and pulled by a Portainer stack.

The stack is managed as code in [`grekko.dsm/portainer-stacks/kiosk`](../../grekko.dsm/portainer-stacks/kiosk). Portainer is configured to pull from that repo — deploys happen by editing the compose file's image tag, committing, and pushing.

## Problem: Portainer CE cannot force-repull `:latest`

Portainer CE (Community Edition) has no "Re-pull image and redeploy" toggle — that switch is a Business feature. With a mutable tag like `:latest`, Portainer sees the image reference unchanged and reuses the cached layer instead of fetching the new digest we just pushed. The UI redeploy is a no-op in that case.

Workarounds (manual pull, "Recreate with pull latest", SSH + `docker compose pull`) work but are easy to forget and push the problem onto the human.

## Fix: immutable, commit-SHA tags

Tag each build with the short git SHA. Every push produces a new, unique tag. Updating the stack means editing the image reference to the new tag — Portainer sees a changed reference and pulls, regardless of edition.

Benefits:

- Deploys are deterministic. `kiosk:ab12cd3` on the NAS always corresponds to that exact commit.
- Rollback is a one-line stack edit to the prior SHA.
- No cache-invalidation fights with Portainer.

## `script/build` — build & push SHA-tagged image

```sh
#!/bin/sh
set -e

REGISTRY="192.168.178.35:5005"
IMAGE="kiosk"
SHA="$(git rev-parse --short HEAD)"

if ! git diff --quiet HEAD; then
  echo "Working tree dirty — commit before building." >&2
  exit 1
fi

docker build --platform linux/x86_64 -t "$IMAGE:$SHA" .
docker image tag "$IMAGE:$SHA" "$REGISTRY/$IMAGE:$SHA"
docker image tag "$IMAGE:$SHA" "$REGISTRY/$IMAGE:latest"

docker image push "$REGISTRY/$IMAGE:$SHA"
docker image push "$REGISTRY/$IMAGE:latest"

echo
echo "Pushed $REGISTRY/$IMAGE:$SHA"
echo "Update Portainer stack image reference to this tag and redeploy."
```

The dirty-tree guard prevents builds that can't be traced back to a single commit.

`:latest` is still pushed as a convenience pointer — it's never used for deploys, only for ad-hoc `docker run` against the registry.

## Deploy steps

1. Commit all changes in this repo.
2. Run `script/deploy`. It:
   - runs `script/build` (build + push SHA + latest to registry),
   - updates `KIOSK_TAG` in `grekko.dsm/portainer-stacks/kiosk/stack.env`,
   - commits and pushes the stack repo.

Portainer redeploys on its next git-poll interval.

The stack compose file references `image: 192.168.178.35:5005/kiosk:${KIOSK_TAG}` — only `stack.env` changes per deploy, so diffs stay clean.

## Rollback

```sh
# set KIOSK_TAG to prior SHA in grekko.dsm/portainer-stacks/kiosk/stack.env
# commit + push; webhook redeploys
```

No rebuild — old tags stay in the registry.

## Cleanup

The registry will accumulate tags. Periodically prune old SHA tags from the registry UI on the NAS (keep the last N, or anything referenced by a running stack on any host).
