FROM busybox:1.36.1 AS kdb-dirs
RUN mkdir -p /kdb/fluent-bit-kdb/etc /kdb/fluent-bit-kdb/parsers /kdb/fluent-bit-kdb/state

FROM fluent/fluent-bit:5.0.6

LABEL org.opencontainers.image.title="kdb-fluent-bit" \
      org.opencontainers.image.description="KDB log collector image based on the upstream Fluent Bit stable image." \
      org.opencontainers.image.base.name="fluent/fluent-bit" \
      org.opencontainers.image.version="5.0.6" \
      org.opencontainers.image.source="https://hub.docker.com/r/fluent/fluent-bit" \
      org.opencontainers.image.vendor="KDB" \
      kdb.upstream.image="fluent/fluent-bit:5.0.6" \
      kdb.upstream.release-date="2026-05-21" \
      kdb.image.purpose="log-collector-daemonset" \
      kdb.image.created="2026-06-09"

COPY --from=kdb-dirs --chown=0:0 /kdb/fluent-bit-kdb /fluent-bit/kdb

USER 0
WORKDIR /fluent-bit
