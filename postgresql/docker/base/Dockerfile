# syntax=docker/dockerfile:1

ARG DEBIAN_IMAGE=debian:bookworm-slim
FROM ${DEBIAN_IMAGE}

ARG DEBIAN_IMAGE
ARG PGDG_DISTRIBUTION=bookworm-pgdg

LABEL name="kdb-postgresql-base" \
      summary="Shared KDB PostgreSQL operating-system runtime" \
      org.opencontainers.image.vendor="kdb" \
      org.opencontainers.image.base.name="${DEBIAN_IMAGE}" \
      kdb.postgresql.pgdg.distribution="${PGDG_DISTRIBUTION}"

ENV DEBIAN_FRONTEND=noninteractive
ENV PGHOST=/tmp/postgres
ENV PGPORT=5432

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl dumb-init gosu gnupg procps \
    && install -d /usr/share/postgresql-common/pgdg \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        | gpg --dearmor -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.gpg] https://apt.postgresql.org/pub/repos/apt ${PGDG_DISTRIBUTION} main" \
        > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-common rsync \
    && apt-get purge -y --auto-remove gnupg \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /kdb/bin /etc/postgresql/tls /pgdata /pgwal /tmp/postgres /var/run/kdb-ha \
	&& chown -R postgres:postgres /kdb /etc/postgresql/tls \
		/pgdata /pgwal /tmp/postgres /var/run/kdb-ha \
	&& chmod 0700 /pgdata /pgwal \
	&& chmod 0775 /tmp/postgres /var/run/kdb-ha
