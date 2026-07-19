# syntax=docker/dockerfile:1

ARG POSTGRESQL_BASE_IMAGE=kdbdeveloper/postgresql-base:bookworm-pgdg-v1
FROM ${POSTGRESQL_BASE_IMAGE}

ARG POSTGRES_MAJOR=17
ARG POSTGRES_PREVIOUS_MAJOR=16

LABEL name="kdb-postgresql" \
      summary="kdb PostgreSQL ${POSTGRES_MAJOR} data-plane runtime" \
      org.opencontainers.image.vendor="kdb" \
      postgresql.version.major="${POSTGRES_MAJOR}" \
      postgresql.upgrade.previous-major="${POSTGRES_PREVIOUS_MAJOR}"

ENV PG_MAJOR=${POSTGRES_MAJOR}
ENV PGDATA=/pgdata/pg${POSTGRES_MAJOR}
ENV PATH=/usr/lib/postgresql/${POSTGRES_MAJOR}/bin:${PATH}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-${POSTGRES_MAJOR} postgresql-client-${POSTGRES_MAJOR} \
        postgresql-contrib-${POSTGRES_MAJOR} postgresql-${POSTGRES_MAJOR}-postgis-3 \
        postgresql-${POSTGRES_MAJOR}-pgvector postgresql-${POSTGRES_MAJOR}-repack \
        postgresql-${POSTGRES_PREVIOUS_MAJOR} postgresql-client-${POSTGRES_PREVIOUS_MAJOR} \
        postgresql-contrib-${POSTGRES_PREVIOUS_MAJOR} \
    && rm -rf /var/lib/apt/lists/*

COPY .build/postgresql/kdb-pg-runtime /usr/local/bin/kdb-pg-runtime
COPY .build/postgresql/kdb-pg-tool /usr/local/bin/kdb-pg-tool
COPY postgresql/scripts/postgres-entrypoint.sh /kdb/bin/postgres-entrypoint.sh
COPY postgresql/scripts/postgres-startup.sh /kdb/bin/postgres-startup.sh
COPY postgresql/scripts/postgres-major-upgrade.sh /kdb/bin/postgres-major-upgrade.sh

RUN chmod 0755 /usr/local/bin/kdb-pg-runtime /usr/local/bin/kdb-pg-tool /kdb/bin/*.sh

EXPOSE 5432
VOLUME ["/pgdata", "/pgwal", "/var/run/kdb-ha"]

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/kdb/bin/postgres-entrypoint.sh"]
USER postgres
CMD ["kdb-pg-runtime", "--socket=/var/run/kdb-ha/postgres-runtime.sock"]
