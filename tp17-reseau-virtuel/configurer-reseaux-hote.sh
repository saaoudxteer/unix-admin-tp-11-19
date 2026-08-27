#!/usr/bin/env bash
set -Eeuo pipefail

readonly NAKEDEB_VM="${NAKEDEB_VM:-NakeDeb13}"
readonly ROCKY_VM="${ROCKY_VM:-rocky1}"
readonly XUBUNTU_VM="${XUBUNTU_VM:-xubuntu}"

command -v VBoxManage >/dev/null 2>&1 || {
  printf "VBoxManage est introuvable sur l'hôte.\n" >&2
  exit 1
}

ensure_hostonly() {
  local name=$1
  if ! VBoxManage list hostonlyifs \
    | awk '/^Name:/ {print $2}' \
    | grep -Fxq "$name"; then
    VBoxManage hostonlyif create
  fi
  VBoxManage list hostonlyifs \
    | awk '/^Name:/ {print $2}' \
    | grep -Fxq "$name" || {
      printf 'Impossible de créer automatiquement %s. Le créer dans VirtualBox.\n' "$name" >&2
      exit 1
    }
}

require_powered_off() {
  local vm=$1
  VBoxManage showvminfo "$vm" --machinereadable \
    | grep -Fxq 'VMState="poweroff"' || {
      printf 'La VM %s doit être complètement éteinte.\n' "$vm" >&2
      exit 1
    }
}

ensure_hostonly vboxnet0
ensure_hostonly vboxnet1
VBoxManage hostonlyif ipconfig vboxnet0 --ip=192.168.10.1 --netmask=255.255.255.0
VBoxManage hostonlyif ipconfig vboxnet1 --ip=192.168.20.1 --netmask=255.255.255.0
VBoxManage dhcpserver modify --ifname vboxnet0 --disable 2>/dev/null || true
VBoxManage dhcpserver modify --ifname vboxnet1 --disable 2>/dev/null || true

for vm in "$NAKEDEB_VM" "$ROCKY_VM" "$XUBUNTU_VM"; do
  require_powered_off "$vm"
done

VBoxManage modifyvm "$NAKEDEB_VM" \
  --nic2 hostonly --hostonlyadapter2 vboxnet0 --cableconnected2 on
VBoxManage modifyvm "$ROCKY_VM" \
  --nic2 hostonly --hostonlyadapter2 vboxnet0 --cableconnected2 on \
  --nic3 hostonly --hostonlyadapter3 vboxnet1 --cableconnected3 on
VBoxManage modifyvm "$XUBUNTU_VM" \
  --nic2 hostonly --hostonlyadapter2 vboxnet1 --cableconnected2 on

printf 'Réseaux et adaptateurs VirtualBox configurés.\n'
