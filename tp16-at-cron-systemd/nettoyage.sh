#!/usr/bin/env bash
set -Eeuo pipefail

readonly LOG_FILE="${LOG_FILE:-/tmp/bilan-nettoyage.txt}"
((EUID == 0)) || {
  printf 'Exécuter ce script avec sudo.\n' >&2
  exit 1
}

exec >>"$LOG_FILE" 2>&1
printf '\n=== Nettoyage du %s ===\n' "$(date --iso-8601=seconds)"
printf 'Place avant nettoyage :\n'
df -h -t ext4 || df -h /
apt-get clean
apt-get -y autoremove
printf 'Place après nettoyage :\n'
df -h -t ext4 || df -h /

