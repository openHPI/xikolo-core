# Update NodeJS

This guide will assist you when upgrading the NodeJS version. The focus of this guide is on preparing the application for a new NodeJS
version, it does not cover the deployment completely.

## Local setup (individually)

The following changes need to be performed by each developer individually to get ready for the new NodeJS version.
According to the [local setup](./index.md) guide, using NVM is recommended for managing NodeJS versions.

```shell
nvm install lts/iron
# Optional: Set as new default version if desired
nvm alias default lts/iron

# Build the assets for the development environment
make assets
```

## Code changes (committed)

The following changes are only performed once and need to be committed to the repository.
Please commit your changes and open a merge request.

### Update `.node-version`

NVM (and other tools) use the `.node-version` file to determine the NodeJS version to use. Therefore, the file needs to be
updated to the new NodeJS version.

### Update `.nvmrc`

Similarly, the file `.nvmrc` needs to be updated to the new NodeJS version.

### Update `debian/control`

Update the `nodejs` constraint for the NodeJS version being installed on production systems.

### Update `.gitlab-ci.yml`

The `.gitlab-ci.yml` file needs to be updated to the new NodeJS version. The `image` line specifies the Docker image to
use for the respective job in the CI pipeline.

The line consists of the image name (`node`), the NodeJS version and image flavour (`22-slim`), and a digest  (`sha256: <...>`).

```yaml
# .gitlab-ci.yml
image: node:22-slim@sha256:35531c52ce27b6575d69755c73e65d4468dba93a25644eed56dc12879cae9213
```

You may also skip this step and leave updating to the Renovate bot. Based on the schedule defined, Renovate will automatically update the image and image digest, so that you just need to approve and merge the corresponding merge request.

```yaml
# .gitlab-ci.yml
image: node:22-slim
```

### Documentation

Once you changed all versions, please remember to update the
[local setup](./index.md) guide to reflect the new NodeJS version (e.g., in the `nvm install` command).
