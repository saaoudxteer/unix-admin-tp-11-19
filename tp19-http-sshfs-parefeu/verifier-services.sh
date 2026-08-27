#!/usr/bin/env bash
set -Eeuo pipefail

failed=0
check_service() {
  local service=$1
  if systemctl is-active --quiet "$service"; then
    printf '[OK] service %s actif\n' "$service"
  else
    printf '[ECHEC] service %s inactif\n' "$service" >&2
    failed=1
  fi
}

check_service httpd
check_service named
check_service sshd
check_service firewalld
check_service fail2ban

if curl --fail --silent --show-error --max-time 3 \
  http://127.0.0.1/ >/dev/null; then
  printf '[OK] HTTP local répond\n'
else
  printf '[ECHEC] HTTP local\n' >&2
  failed=1
fi

if command -v firewall-cmd >/dev/null 2>&1; then
  firewall-cmd --zone=tp-public --list-all
fi
exit "$failed"

