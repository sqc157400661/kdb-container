FROM busybox:1.36.1 AS kdb-dirs
RUN mkdir -p /kdb/etc-loki-kdb /kdb/var-loki-kdb

FROM grafana/loki:3.7.0

LABEL org.opencontainers.image.title="kdb-loki" \
      org.opencontainers.image.description="KDB managed Loki image based on the upstream Grafana Loki image." \
      org.opencontainers.image.base.name="grafana/loki" \
      org.opencontainers.image.version="3.7.0" \
      org.opencontainers.image.source="https://grafana.com/docs/loki/latest/setup/install/docker/" \
      org.opencontainers.image.vendor="KDB" \
      kdb.upstream.image="grafana/loki:3.7.0" \
      kdb.image.purpose="managed-loki" \
      kdb.image.created="2026-06-09"

COPY --from=kdb-dirs --chown=10001:10001 /kdb/etc-loki-kdb /etc/loki/kdb
COPY --from=kdb-dirs --chown=10001:10001 /kdb/var-loki-kdb /var/loki/kdb

USER 10001
WORKDIR /loki
