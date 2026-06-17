# kdb PostgreSQL Images

This directory contains the first PostgreSQL runtime image definition for kdb.

## Build

```bash
make postgresql14
```

Optional overrides:

```bash
make postgresql14 IMAGE_PREFIX=kdbdeveloper POSTGRESQL_IMAGE_TAG=dev
```

## Contents

- PostgreSQL 14 server, client and contrib packages.
- Patroni with Kubernetes and etcd3 support.
- pgBackRest.
- kdb startup and Patroni probe scripts.

The image is intended as a development baseline for the PostgreSQL operator work. Production hardening still needs fixed package sources, offline dependency handling, SBOM/CVE checks, and Kubernetes smoke evidence.
