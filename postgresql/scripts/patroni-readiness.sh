#!/usr/bin/env bash
set -euo pipefail

port="${1:-8008}"
code="$(curl -k -s -o /dev/null -w '%{http_code}' "https://127.0.0.1:${port}/readiness" || true)"
if [ "${code}" != "200" ]; then
  code="$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:${port}/readiness" || true)"
fi

if [ "${code}" = "200" ]; then
  exit 0
fi

exit 1
