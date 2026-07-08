# kdbdeveloper/ubi8-base

`kdbdeveloper/ubi8-base` is the shared UBI8 minimal base image for KDB
containers. It exists to avoid repeatedly pulling
`registry.access.redhat.com/ubi8-minimal` and reinstalling common tools in
downstream image builds.

## Build

From `kdb-container`:

```bash
docker build \
  -f base/ubi8-base/Dockerfile \
  -t kdbdeveloper/ubi8-base:latest \
  base/ubi8-base
```

For multi-platform builds:

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f base/ubi8-base/Dockerfile \
  -t kdbdeveloper/ubi8-base:latest \
  base/ubi8-base
```

## Included Packages

The image includes shared UBI8 runtime and troubleshooting packages observed in
current KDB container builds:

- `bind-utils`
- `ca-certificates`
- `curl`
- `gettext`
- `glibc-langpack-en`
- `hostname`
- `iputils`
- `less`
- `nss_wrapper`
- `procps-ng`
- `tzdata`
- `vim-minimal`
- `wget`
- `yum`

It also sets:

- `LANG=en_US.utf-8`
- `LC_ALL=en_US.utf-8`

## Not Included

The base image intentionally does not include database-specific or
version-sensitive packages, such as:

- Percona XtraBackup RPMs
- PostgreSQL server/client packages
- pgBackRest, Patroni, pgbouncer, or ClickHouse binaries
- compiler/build toolchains such as `gcc`, `make`, `automake`, `autoconf`,
  `libtool`, and `*-devel` packages
- EPEL or PostgreSQL repository configuration

Keep these in downstream images so service images can migrate independently and
avoid inheriting unrelated dependencies.

## Current UBI8 Minimal References

The following files currently use `FROM registry.access.redhat.com/ubi8-minimal`
and can migrate to `FROM kdbdeveloper/ubi8-base:latest` later as needed:

- `kdb-sidecar/hack/mysql/Dockerfile.redhat`
- `kdb-sidecar/hack/docker/Dockerfile`
- `kdb-sidecar/hack/docker/Dockerfile.clickhouse`
- `kdb/hack/docker/Dockerfile`
- `pgoperator/hack/containers/pgbouncer/Dockerfile`
- `pgoperator/hack/containers/pgbouncer/Dockerfilebak`
- `pgoperator/hack/containers/pgbackrest/Dockerfile`
- `pgoperator/hack/containers/pgbackrest/Dockerfilebak`
- `pgoperator/hack/containers/postgres/Dockerfile`
- `pgoperator/hack/containers/postgres/Dockerfilebak`

There is also one documentation reference:

- `kdb-project/test-docs/fix-operator-resource-helper/README.md`

No existing Dockerfile has been modified for this base image.
