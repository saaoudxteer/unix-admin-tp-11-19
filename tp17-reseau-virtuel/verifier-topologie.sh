#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROLE="${1:-}"
case $ROLE in
  nakedeb) TARGETS=(192.168.10.30 192.168.20.31 192.168.20.40) ;;
  rocky1) TARGETS=(192.168.10.20 192.168.20.40) ;;
  xubuntu) TARGETS=(192.168.20.31 192.168.10.30 192.168.10.20) ;;
  *) printf 'Usage : %s nakedeb|rocky1|xubuntu\n' "${0##*/}" >&2; exit 2 ;;
esac

failed=0
for target in "${TARGETS[@]}"; do
  if ping -c 1 -W 2 "$target" >/dev/null; then
    printf '[OK] ICMP vers %s\n' "$target"
  else
    printf '[ECHEC] ICMP vers %s\n' "$target" >&2
    failed=1
  fi
done

printf '\nRoutes actives :\n'
ip route
exit "$failed"

