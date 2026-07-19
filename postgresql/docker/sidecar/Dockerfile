# syntax=docker/dockerfile:1

ARG POSTGRESQL_BASE_IMAGE=kdbdeveloper/postgresql-base:bookworm-pgdg-v1
FROM ${POSTGRESQL_BASE_IMAGE}

LABEL name="kdb-postgresql-sidecar" \
      summary="KDB PostgreSQL HA, management and backup sidecar" \
      org.opencontainers.image.vendor="kdb"

RUN apt-get update \
    && apt-get install -y --no-install-recommends pgbackrest \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/patroni /etc/pgbackrest /backrestrepo /var/log/pgbackrest \
    && chown -R postgres:postgres /etc/patroni /etc/pgbackrest /backrestrepo /var/log/pgbackrest

COPY .build/postgresql/kdb-ha /usr/local/bin/kdb-ha
COPY .build/postgresql/kdb-hactl /usr/local/bin/kdb-hactl

RUN chmod 0755 /usr/local/bin/kdb-ha /usr/local/bin/kdb-hactl

EXPOSE 8008
VOLUME ["/pgdata", "/pgwal", "/backrestrepo", "/var/run/kdb-ha"]

USER postgres
ENTRYPOINT ["/usr/local/bin/kdb-ha"]
CMD ["/etc/patroni/patroni.yaml"]
