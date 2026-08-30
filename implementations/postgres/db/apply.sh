#!/usr/bin/env bash
# Applies the whole database in order. Order matters: see the header of each file.
set -euo pipefail
DB="${1:-crmthree_local}"
for f in 00-role.sql schema.sql 10-grants.sql policies.sql 20-auth.sql 30-realtime.sql; do
  printf '  %-14s ' "$f"
  if out=$(psql -q -d "$DB" -v ON_ERROR_STOP=1 -f "$f" 2>&1); then echo "applied"
  else echo "FAILED"; echo "$out" | grep -i error | head -3; exit 1; fi
done
