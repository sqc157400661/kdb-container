FROM debian:bookworm-slim

ARG POSTGRES_MAJOR=14
ARG PATRONI_VERSION=3.3.5
ARG PG_BACKREST_VERSION=2.48

LABEL name="kdb-postgresql" \
      summary="kdb PostgreSQL ${POSTGRES_MAJOR} runtime with Patroni and pgBackRest" \
      org.opencontainers.image.vendor="kdb" \
      postgresql.version.major="${POSTGRES_MAJOR}"

ENV DEBIAN_FRONTEND=noninteractive
ENV PG_MAJOR=${POSTGRES_MAJOR}
ENV PGDATA=/pgdata/pg${POSTGRES_MAJOR}
ENV PGHOST=/tmp/postgres
ENV PGPORT=5432
ENV PATH=/usr/lib/postgresql/${POSTGRES_MAJOR}/bin:${PATH}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dumb-init \
        gosu \
        gnupg \
        lsb-release \
        procps \
    && install -d /usr/share/postgresql-common/pgdg \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        | gpg --dearmor -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-pip \
        python3-psycopg2 \
        python3-venv \
        postgresql-${POSTGRES_MAJOR} \
        postgresql-client-${POSTGRES_MAJOR} \
        postgresql-contrib-${POSTGRES_MAJOR} \
        pgbackrest \
        rsync \
        tini \
    && pip3 install --break-system-packages --no-cache-dir "patroni[kubernetes,etcd3]==${PATRONI_VERSION}" \
    && apt-get purge -y --auto-remove gnupg lsb-release \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /kdb/bin /kdb/conf /pgdata /pgwal /pgconf /backrestrepo /var/log/pgbackrest /tmp/postgres \
    && chown -R postgres:postgres /kdb /pgdata /pgwal /pgconf /backrestrepo /var/log/pgbackrest /tmp/postgres \
    && chmod 0700 /pgdata /pgwal \
    && chmod 0775 /tmp/postgres

COPY postgresql/scripts/postgres-entrypoint.sh /kdb/bin/postgres-entrypoint.sh
COPY postgresql/scripts/postgres-startup.sh /kdb/bin/postgres-startup.sh
COPY postgresql/scripts/patroni-liveness.sh /kdb/bin/patroni-liveness.sh
COPY postgresql/scripts/patroni-readiness.sh /kdb/bin/patroni-readiness.sh

RUN chmod +x /kdb/bin/*.sh

EXPOSE 5432 8008

VOLUME ["/pgdata", "/pgwal", "/pgconf", "/backrestrepo"]

ENTRYPOINT ["/usr/bin/dumb-init", "--", "/kdb/bin/postgres-entrypoint.sh"]
USER postgres
CMD ["patroni", "/etc/patroni"]
