#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" = "0" ]; then
  mkdir -p /pgdata /pgwal /tmp/postgres /var/run/kdb-ha
  chown -R postgres:postgres /pgdata /pgwal /tmp/postgres /var/run/kdb-ha
  chmod 0700 /pgdata /pgwal
  chmod 0775 /tmp/postgres
  exec gosu postgres "$0" "$@"
fi

mkdir -p "${PGDATA}" /tmp/postgres
chmod 0700 "${PGDATA}" || true
chmod 0775 /tmp/postgres || true

exec "$@"
