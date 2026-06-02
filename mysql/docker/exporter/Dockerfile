FROM debian:bookworm-slim

ARG MYSQLD_EXPORTER_VERSION=0.17.2
ARG TARGETARCH

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates wget tar; \
    arch="${TARGETARCH:-amd64}"; \
    case "$arch" in \
      amd64|arm64) ;; \
      *) echo "unsupported TARGETARCH: $arch" >&2; exit 1 ;; \
    esac; \
    wget -nv -O /tmp/mysqld_exporter.tar.gz \
      "https://github.com/prometheus/mysqld_exporter/releases/download/v${MYSQLD_EXPORTER_VERSION}/mysqld_exporter-${MYSQLD_EXPORTER_VERSION}.linux-${arch}.tar.gz"; \
    tar -xzf /tmp/mysqld_exporter.tar.gz -C /tmp; \
    mv "/tmp/mysqld_exporter-${MYSQLD_EXPORTER_VERSION}.linux-${arch}/mysqld_exporter" /usr/local/bin/mysqld_exporter; \
    chmod +x /usr/local/bin/mysqld_exporter; \
    mkdir -p /etc/mysqld_exporter; \
    chown -R nobody:nogroup /etc/mysqld_exporter; \
    rm -rf /tmp/mysqld_exporter* /var/lib/apt/lists/*

COPY mysql/docker/exporter/entrypoint.sh /usr/local/bin/kdb-mysqld-exporter-entrypoint

RUN chmod +x /usr/local/bin/kdb-mysqld-exporter-entrypoint

USER nobody:nogroup

EXPOSE 9104

ENTRYPOINT ["kdb-mysqld-exporter-entrypoint"]
