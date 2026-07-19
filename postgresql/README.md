# kdb PostgreSQL Images

This directory contains the PostgreSQL 16/17/18 data-plane images and the
single PostgreSQL management Sidecar image for KDB. PostgreSQL does not embed
the generic `kdb-sidecar`.

## Build

```bash
make postgresql-images
make postgresql-smoke
```

`postgresql-images` first builds the shared base image and then builds the
three version images from their independent Dockerfiles. CI can publish the
base independently and build only the version layers:

```bash
make postgresql-base \
  POSTGRESQL_BASE_IMAGE=registry.example.com/kdb/postgresql-base \
  POSTGRESQL_BASE_IMAGE_TAG=bookworm-pgdg-v1

make postgresql-version-images \
  POSTGRESQL_BASE_IMAGE=registry.example.com/kdb/postgresql-base \
  POSTGRESQL_BASE_IMAGE_TAG=bookworm-pgdg-v1
```

Optional overrides:

```bash
make postgresql-images IMAGE_PREFIX=kdbdeveloper POSTGRESQL_IMAGE_TAG=dev
```

## Images

- `postgresql16`, `postgresql17`, `postgresql18`: PostgreSQL server, matching
  client/control binaries, extensions, the minimal `kdb-pg-runtime` command
  server and the `kdb-pg-tool` proxy used by PostgreSQL archive/restore hooks.
- `postgresql-sidecar`: `kdb-ha`, `kdb-hactl` and pgBackRest. This is the only
  PostgreSQL management Sidecar and is shared by PostgreSQL major versions.
- `postgresql-base`: Debian, PGDG repository metadata, common users,
  directories and operating-system tools shared by both image families.

## Image layering

`postgresql/docker/base/Dockerfile` owns the slow-moving shared layer: Debian,
the PGDG repository, common operating-system tools, runtime users, directories
and permissions. Publish this image under an immutable tag and advance the tag
deliberately for base operating-system security updates.

`postgresql/docker/16/Dockerfile`, `17/Dockerfile` and `18/Dockerfile` remain
independent version extension points. Each owns its PostgreSQL packages,
extensions and any future version-only customization. The upgrade-capable
images install only the previous major needed by the supported path (`17`
includes `16`; `18` includes `17`). They do not contain `kdb-ha`, `kdb-hactl`
or pgBackRest.

`postgresql/docker/sidecar/Dockerfile` owns all Pod-local management and backup
tools. `kdb-ha` calls version-sensitive PostgreSQL commands through the
allowlisted `/var/run/kdb-ha/postgres-runtime.sock`; PostgreSQL archive and
restore hooks call pgBackRest through the reverse
`/var/run/kdb-ha/postgres-tools.sock`. Both sockets are Pod-local Unix sockets
on an `emptyDir`; neither protocol is exposed through a Service.

Production pipelines should pass a registry-qualified, digest-pinned value as
`POSTGRESQL_BASE_IMAGE_REF`, for example
`registry.example.com/kdb/postgresql-base@sha256:...`. The Makefile's
`POSTGRESQL_BASE_IMAGE` plus `POSTGRESQL_BASE_IMAGE_TAG` form is intended for
local builds and for the base-image publication job.

`make postgresql-binaries` builds `kdb-ha`, `kdb-hactl`, `kdb-pg-runtime` and
`kdb-pg-tool` from the sibling `kdb-ha/` repository into the ignored
`.build/postgresql/` staging directory. Image builds therefore use the exact
workspace source being integrated.

The legacy PostgreSQL 14 target remains only for compatibility and is not part
of the new product baseline.

## pgBackRest runtime contract

The image includes pgBackRest for S3-compatible repositories. The Operator
mounts `pgbackrest.conf` read-only, injects repository credentials from a
Secret, and enables continuous WAL archive/restore commands. Default policy is
weekly full, daily differential, continuous WAL, three retained full backup
chains, and a 14-day product PITR target.

NewInstance restore uses the same image as a `pgbackrest-restore` init
container. It restores into an empty target PVC, validates the restored
`PG_VERSION` marker, and only then allows the normal startup and `kdb-ha`
containers to run.
