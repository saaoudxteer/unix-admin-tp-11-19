#!/usr/bin/env bash
set -Eeuo pipefail

readonly PUBLIC_IF="${PUBLIC_IF:-enp0s3}"
readonly INTERNAL_IF_1="${INTERNAL_IF_1:-enp0s8}"
readonly INTERNAL_IF_2="${INTERNAL_IF_2:-enp0s9}"

((EUID == 0)) || {
  printf 'Exécuter ce script avec sudo.\n' >&2
  exit 1
}
command -v firewall-cmd >/dev/null 2>&1 || {
  printf 'Installer et démarrer firewalld.\n' >&2
  exit 1
}

systemctl enable --now firewalld

ensure_zone() {
  local zone=$1
  firewall-cmd --permanent --get-zones \
    | tr ' ' '\n' \
    | grep -Fxq "$zone" || firewall-cmd --permanent --new-zone="$zone"
}

ensure_zone tp-public
ensure_zone tp-internal
firewall-cmd --permanent --zone=tp-public --set-target=DROP
firewall-cmd --permanent --zone=tp-public --add-service=ssh
firewall-cmd --permanent --zone=tp-public --add-service=http
firewall-cmd --permanent --zone=tp-public --change-interface="$PUBLIC_IF"
firewall-cmd --permanent --zone=tp-internal --set-target=ACCEPT
firewall-cmd --permanent --zone=tp-internal --change-interface="$INTERNAL_IF_1"
firewall-cmd --permanent --zone=tp-internal --change-interface="$INTERNAL_IF_2"
firewall-cmd --permanent --set-default-zone=tp-public
firewall-cmd --reload

printf 'Zone publique :\n'
firewall-cmd --zone=tp-public --list-all
printf 'Zone interne :\n'
firewall-cmd --zone=tp-internal --list-all

