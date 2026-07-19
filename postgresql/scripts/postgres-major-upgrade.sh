#!/usr/bin/env bash
set -euo pipefail

old_major="${1:?old major is required}"
new_major="${2:?new major is required}"
old_data="${3:-/pgdata/pg${old_major}}"
new_data="${4:-/pgdata/pg${new_major}}"
old_bin="/usr/lib/postgresql/${old_major}/bin"
new_bin="/usr/lib/postgresql/${new_major}/bin"
work_dir="/tmp/kdb-pg-upgrade-${old_major}-to-${new_major}"

fail() {
  printf 'postgres major upgrade rejected: %s\n' "$*" >&2
  exit 1
}

[[ "${old_major}" =~ ^(16|17)$ ]] || fail "supported sources are 16 and 17"
[ "$((old_major + 1))" = "${new_major}" ] || fail "only adjacent major upgrades are supported"
[ -x "${old_bin}/pg_ctl" ] || fail "old PostgreSQL binaries are missing"
[ -x "${new_bin}/pg_upgrade" ] || fail "target PostgreSQL binaries are missing"
[ -f "${old_data}/PG_VERSION" ] || fail "old PGDATA is missing"
[ "$(<"${old_data}/PG_VERSION")" = "${old_major}" ] || fail "old PGDATA version mismatch"
if [ -f "${old_data}/postmaster.pid" ]; then
  if "${old_bin}/pg_ctl" -D "${old_data}" status >/dev/null 2>&1; then
    fail "old PostgreSQL must be stopped"
  fi
  # An ungracefully terminated Pod may leave a PID file on its PVC. The
  # upgrade Job has its own PID namespace, so pg_ctl is the authoritative
  # process check and the stale file is safe to remove here.
  rm -f "${old_data}/postmaster.pid"
fi

if [ -f "${new_data}/.kdb-major-upgrade-complete" ] && [ "$(<"${new_data}/PG_VERSION")" = "${new_major}" ]; then
  printf 'postgres major upgrade already complete: %s -> %s\n' "${old_major}" "${new_major}"
  exit 0
fi

rm -rf "${new_data}"
rm -rf "${work_dir}"
mkdir -p "${new_data}" /tmp/postgres "${work_dir}"
chmod 0700 "${new_data}"
cd "${work_dir}"

cluster_state="$(${old_bin}/pg_controldata "${old_data}" | awk -F: '/Database cluster state/ {sub(/^[[:space:]]+/, "", $2); print $2}')"
if [ "${cluster_state}" != "shut down" ]; then
  printf 'source cluster state is %s; performing isolated crash recovery and clean shutdown\n' "${cluster_state}"
  "${old_bin}/pg_ctl" -D "${old_data}" \
    -o "-c listen_addresses='' -c unix_socket_directories='${work_dir}' -c ssl=off -c archive_mode=off" \
    -w start
  "${old_bin}/pg_ctl" -D "${old_data}" -m fast -w stop
fi

initdb_args=(-D "${new_data}" --no-sync)
checksum_version="$(${old_bin}/pg_controldata "${old_data}" | awk -F: '/Data page checksum version/ {gsub(/[[:space:]]/, "", $2); print $2}')"
if [ "${checksum_version:-0}" != "0" ]; then
  initdb_args+=(--data-checksums)
elif [ "${new_major}" -ge 18 ]; then
  # PostgreSQL 18 enables checksums by default; pg_upgrade requires the new
  # cluster to match the source cluster's checksum setting.
  initdb_args+=(--no-data-checksums)
fi
"${new_bin}/initdb" "${initdb_args[@]}"

common=(
  --old-bindir="${old_bin}"
  --new-bindir="${new_bin}"
  --old-datadir="${old_data}"
  --new-datadir="${new_data}"
  --socketdir=/tmp/postgres
  --old-options="-c ssl=off"
  --new-options="-c ssl=off"
)

"${new_bin}/pg_upgrade" "${common[@]}" --check
"${new_bin}/pg_upgrade" "${common[@]}"
rm -f "${new_data}/standby.signal" "${new_data}/recovery.signal"
touch "${new_data}/.kdb-major-upgrade-complete"
sync
printf 'postgres major upgrade complete: %s -> %s; automatic downgrade is unsupported\n' "${old_major}" "${new_major}"
