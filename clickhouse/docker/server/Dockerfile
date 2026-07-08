ARG CLICKHOUSE_IMAGE=clickhouse/clickhouse-server:24.3
FROM ${CLICKHOUSE_IMAGE}

LABEL maintainers="kdbdeveloper"
LABEL description="KDB ClickHouse server image"

USER root
RUN mkdir -p /var/lib/clickhouse /var/log/clickhouse-server /var/run/kdb \
    && chown -R clickhouse:clickhouse /var/lib/clickhouse /var/log/clickhouse-server /var/run/kdb

USER clickhouse
