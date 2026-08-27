#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROLE="${1:-}"
readonly IFACE_LEFT="${IFACE_LEFT:-enp0s8}"
readonly IFACE_RIGHT="${IFACE_RIGHT:-enp0s9}"

((EUID == 0)) || {
  printf 'Exécuter ce script avec sudo.\n' >&2
  exit 1
}
command -v nmcli >/dev/null 2>&1 || {
  printf 'NetworkManager/nmcli est requis par ce script.\n' >&2
  exit 1
}

ensure_profile() {
  local profile=$1
  local interface=$2
  local address=$3
  local routes=$4
  local dns=$5

  if ! nmcli connection show "$profile" >/dev/null 2>&1; then
    nmcli connection add type ethernet ifname "$interface" con-name "$profile"
  fi
  nmcli connection modify "$profile" \
    connection.interface-name "$interface" \
    ipv4.method manual \
    ipv4.addresses "$address" \
    ipv4.gateway '' \
    ipv4.routes "$routes" \
    ipv4.dns "$dns" \
    ipv4.never-default yes \
    ipv6.method disabled
  nmcli connection up "$profile"
}

case $ROLE in
  nakedeb)
    ensure_profile tp18-vboxnet0 "$IFACE_LEFT" 192.168.10.20/24 \
      '192.168.20.0/24 192.168.10.30' '192.168.10.30'
    ;;
  rocky1)
    ensure_profile tp18-vboxnet0 "$IFACE_LEFT" 192.168.10.30/24 '' '127.0.0.1'
    ensure_profile tp18-vboxnet1 "$IFACE_RIGHT" 192.168.20.31/24 '' '127.0.0.1'
    printf 'net.ipv4.ip_forward = 1\n' >/etc/sysctl.d/90-tp-router.conf
    sysctl --system >/dev/null
    ;;
  xubuntu)
    ensure_profile tp18-vboxnet1 "$IFACE_LEFT" 192.168.20.40/24 \
      '192.168.10.0/24 192.168.20.31' '192.168.20.31,192.168.10.20'
    ;;
  *)
    printf 'Usage : sudo %s nakedeb|rocky1|xubuntu\n' "${0##*/}" >&2
    exit 2
    ;;
esac

nmcli connection show --active
ip -br address
ip route

