#!/usr/bin/env bash
set -Eeuo pipefail

readonly OUTPUT_FILE="${1:-tp11-system-report.txt}"

{
  printf '=== Date ===\n'
  date --iso-8601=seconds
  printf '\n=== Système ===\n'
  cat /etc/os-release
  uname -a
  printf '\n=== Processeurs et mémoire ===\n'
  nproc
  awk '/MemTotal|SwapTotal/ {print}' /proc/meminfo
  printf '\n=== Stockage ===\n'
  lsblk -o NAME,TYPE,FSTYPE,SIZE,MOUNTPOINTS
  df -hT /
  printf '\n=== Réseau ===\n'
  ip -br address
  ip route
  printf '\n=== Intégration VirtualBox ===\n'
  lsmod | grep -E '^vbox' || printf 'Aucun module vbox détecté.\n'
  mount | grep vboxsf || printf 'Aucun dossier vboxsf monté.\n'
  id
} >"$OUTPUT_FILE"

printf 'Rapport écrit dans %s\n' "$OUTPUT_FILE"

