# KDB Logging Images

This directory contains KDB-owned wrapper images for the log collection system.
The wrappers keep the upstream runtime behavior and add KDB labels/directories so
KDB deployments can pin internal image names while still tracking upstream
versions clearly.

## Version Matrix

| Component | Upstream image | Pinned version | Usage |
| --- | --- | --- | --- |
| Fluent Bit | `fluent/fluent-bit` | `5.0.6` | Node-level log collector DaemonSet |
| Loki | `grafana/loki` | `3.7.0` | KDB managed Loki deployment |

Version notes:

- Fluent Bit `5.0.6` is the latest stable release confirmed on 2026-06-09. The
  upstream image is distroless-oriented and suitable for production collectors.
- Loki `3.7.0` is the version used by the current Grafana Loki Docker
  installation documentation. The upstream container runs as UID/GID `10001`.
- KDB managed Loki should be installed by Helm. Current Grafana documentation
  says the OSS Loki Helm chart moved to `grafana-community/helm-charts`; simple
  scalable mode is being deprecated before Loki 4.0, so new KDB deployments
  should generate values that can migrate to the recommended mode without
  coupling product APIs to chart internals.

## Build

```bash
make logging-images IMAGE_PREFIX=registry.example.com/kdb
```

Replace `registry.example.com/kdb` with the target internal registry namespace.
The Makefile exposes the following overridable tags:

```bash
make loki IMAGE_PREFIX=registry.example.com/kdb LOKI_IMAGE_TAG=3.7.0-kdb.1
make fluent-bit IMAGE_PREFIX=registry.example.com/kdb FLUENT_BIT_IMAGE_TAG=5.0.6-kdb.1
```

## Helm Values Usage

KDB generated Helm values should reference internal images explicitly:

```yaml
loki:
  image:
    registry: registry.example.com
    repository: kdb/loki
    tag: 3.7.0-kdb.1

fluentBit:
  image:
    registry: registry.example.com
    repository: kdb/fluent-bit
    tag: 5.0.6-kdb.1
```

The final chart key names depend on the selected chart. Keep the KDB API model
stable and translate it to chart-specific values in the deployment layer.

## Upgrade Rules

- Upgrade Fluent Bit and Loki independently unless a tested chart requires a
  coordinated bump.
- Do not use `latest` in production values.
- Record the upstream image, upstream version, KDB image tag, chart version, and
  generated values checksum in every provisioning task.
- Keep all credentials in Kubernetes Secrets or external secret references. Do
  not bake credentials into these images.
