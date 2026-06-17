#!/usr/bin/env bash
set -euo pipefail

expected_major="${1:-${PG_MAJOR:-14}}"
wal_directory="${2:-/pgwal/pg${expected_major}_wal}"

halt() {
  local rc=$?
  echo "$*" >&2
  exit "${rc/#0/1}"
}

results() {
  printf '::kdb-postgresql: %s::%s\n' "$@"
}

mkdir -p "${PGDATA}" "${wal_directory}" /tmp/postgres
chmod 0700 "${PGDATA}" "${wal_directory}"
chmod 0775 /tmp/postgres

results "postgres path" "$(command -v postgres)"
postgres_version="$(postgres --version)"
results "postgres version" "${postgres_version}"
[[ "${postgres_version}" =~ \ ${expected_major}($|[^0-9]) ]] || halt "postgres major version mismatch: expected ${expected_major}, got ${postgres_version}"

if [ -f "${PGDATA}/PG_VERSION" ]; then
  data_version="$(cat "${PGDATA}/PG_VERSION")"
  results "data version" "${data_version}"
  [ "${data_version}" = "${expected_major}" ] || halt "PGDATA version mismatch: expected ${expected_major}, got ${data_version}"
fi

if [ ! -e "${PGDATA}/postgresql.conf" ]; then
  touch "${PGDATA}/postgresql.conf"
fi

if [ ! -e "${PGDATA}/pg_wal" ]; then
  ln -s "${wal_directory}" "${PGDATA}/pg_wal"
elif [ -d "${PGDATA}/pg_wal" ] && [ "$(realpath "${PGDATA}/pg_wal")" != "$(realpath "${wal_directory}")" ]; then
  mv "${PGDATA}/pg_wal"/* "${wal_directory}/" 2>/dev/null || true
  rmdir "${PGDATA}/pg_wal" 2>/dev/null || true
  ln -sfn "${wal_directory}" "${PGDATA}/pg_wal"
fi

rm -f "${PGDATA}/recovery.signal"
results "startup check" "ok"
