ARG CLICKHOUSE_IMAGE=clickhouse/clickhouse-server:24.3
FROM ${CLICKHOUSE_IMAGE}

LABEL maintainers="kdbdeveloper"
LABEL description="KDB ClickHouse Keeper image"

USER root
RUN mkdir -p /var/lib/clickhouse-keeper /var/log/clickhouse-server \
    && chown -R clickhouse:clickhouse /var/lib/clickhouse-keeper /var/log/clickhouse-server

USER clickhouse
ENTRYPOINT ["clickhouse-keeper"]
