# Deploy from CI, with `script/deploy` on a laptop as the fallback

Deploys used to be run by hand from a laptop. Since #209, `.github/workflows/deploy.yml` deploys every push to `main` once CI is green: it builds the exact commit CI approved, joins the tailnet to reach the NAS registry, pushes the SHA-tagged image ([ADR 0001](0001-deploy-immutable-sha-tagged-images.md)) and bumps `KIOSK_TAG` in `grekko/dsm`. `script/deploy` stays, unchanged, as the escape hatch for when CI or the tailnet is down; it does the same steps and gives the same result.

## Consequences

CI needs the `TS_OAUTH_CLIENT_ID`, `TS_OAUTH_SECRET` and `DSM_DEPLOY_TOKEN` secrets, and both paths have to stay equivalent: a change to one deploy path must be made in the other too.
