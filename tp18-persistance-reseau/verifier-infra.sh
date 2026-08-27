#!/usr/bin/env bash
set -Eeuo pipefail

readonly HOSTS=(nakedeb.lab.test rocky1.lab.test xubuntu.lab.test)
failed=0

for host in "${HOSTS[@]}"; do
  if getent ahostsv4 "$host" >/dev/null; then
    printf '[OK] DNS %s -> %s\n' "$host" "$(getent ahostsv4 "$host" | awk 'NR == 1 {print $1}')"
  else
    printf '[ECHEC] résolution de %s\n' "$host" >&2
    failed=1
    continue
  fi

  if ping -c 1 -W 2 "$host" >/dev/null; then
    printf '[OK] ICMP %s\n' "$host"
  else
    printf '[ECHEC] ICMP %s\n' "$host" >&2
    failed=1
  fi
done

exit "$failed"

