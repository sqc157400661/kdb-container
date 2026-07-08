ARG CLICKHOUSE_BACKUP_IMAGE=altinity/clickhouse-backup:2.6.23
FROM ${CLICKHOUSE_BACKUP_IMAGE}

LABEL maintainers="kdbdeveloper"
LABEL description="KDB ClickHouse backup runner image"

USER root
RUN mkdir -p /var/lib/clickhouse /var/run/kdb

WORKDIR /var/lib/clickhouse
