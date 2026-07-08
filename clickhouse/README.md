# ClickHouse Images

This directory contains KDB build entries for ClickHouse deployment components:

- `server`: ClickHouse database container used by `KDBInstance.spec.clickhouse.computeGroups[].instance.mainContainer`.
- `keeper`: ClickHouse Keeper container used by `KDBInstance.spec.clickhouse.keeper.instance`.
- `sidecar`: KDB sidecar container built by the sibling `kdb-sidecar` repository and started with `manager clickhouse`.
- `backup-runner`: clickhouse-backup compatible local runner used when ClickHouse backup is enabled.

Build from `kdb-container`:

```sh
make clickhouse-images
```

Override versions or repository prefix when needed:

```sh
make clickhouse-images IMAGE_PREFIX=registry.example.com/kdb CLICKHOUSE_VERSION=24.3 CLICKHOUSE_SIDECAR_IMAGE_TAG=v0.0.1
```

The `clickhouse-sidecar` target here delegates to `../kdb-sidecar` so the sidecar binary and Dockerfile stay with the sidecar source code.
