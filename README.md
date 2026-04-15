# Kiosk

Tracks Drinks, Orders, Clients and Monthly Reports, Settlements and Payments.

# Development

Secrets are managed via ENV variables. See .envrc.


## How to Deploy

The Docker image is built locally, pushed to the private registry on `diskstation:5005`, and pulled by a Portainer stack on the NAS.

Each build is tagged with the short git SHA so deploys reference an immutable image. Portainer CE has no "re-pull image" toggle, so we never rely on the mutable `:latest` tag for deploys — the stack always pins a specific SHA.

### Build & push

1. Commit all changes.
2. Run `script/build`. It verifies the working tree is clean, builds, tags with the SHA + `latest`, and pushes both to `diskstation:5005`. Copy the SHA it prints.

### Update the stack

1. Portainer → Stacks → `kiosk` → Editor.
2. Change the image reference to `diskstation:5005/kiosk:<sha>`.
3. Update the stack. Portainer pulls the new tag and recreates the container.

### Rollback

Edit the stack image line back to the previous SHA and update. No rebuild needed — old tags stay in the registry.

See [docs/deploy.md](docs/deploy.md) for the full rationale.
