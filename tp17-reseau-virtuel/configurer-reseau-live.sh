#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROLE="${1:-}"
readonly IFACE_LEFT="${IFACE_LEFT:-enp0s8}"
readonly IFACE_RIGHT="${IFACE_RIGHT:-enp0s9}"

((EUID == 0)) || {
  printf 'Exécuter ce script avec sudo.\n' >&2
  exit 1
}

configure_address() {
  local interface=$1
  local address=$2
  ip link show "$interface" >/dev/null
  ip address replace "$address" dev "$interface"
  ip link set "$interface" up
}

case $ROLE in
  nakedeb)
    configure_address "$IFACE_LEFT" 192.168.10.20/24
    ip route replace 192.168.20.0/24 via 192.168.10.30 dev "$IFACE_LEFT"
    ;;
  rocky1)
    configure_address "$IFACE_LEFT" 192.168.10.30/24
    configure_address "$IFACE_RIGHT" 192.168.20.31/24
    sysctl -w net.ipv4.ip_forward=1
    if command -v firewall-cmd >/dev/null 2>&1; then
      firewall-cmd --zone=trusted --add-interface="$IFACE_LEFT"
      firewall-cmd --zone=trusted --add-interface="$IFACE_RIGHT"
    fi
    ;;
  xubuntu)
    configure_address "$IFACE_LEFT" 192.168.20.40/24
    ip route replace 192.168.10.0/24 via 192.168.20.31 dev "$IFACE_LEFT"
    ;;
  *)
    printf 'Usage : sudo %s nakedeb|rocky1|xubuntu\n' "${0##*/}" >&2
    exit 2
    ;;
esac

ip -br address
ip route

