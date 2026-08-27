#!/usr/bin/env bash
set -Eeuo pipefail

PV=/dev/sdb1
VG=NDebVG
LV=Home
APPLY=false

usage() {
  printf 'Usage : %s [--pv /dev/sdXN] [--vg nom] [--lv nom] [--apply]\n' "${0##*/}" >&2
  exit 2
}

while (($#)); do
  case $1 in
    --pv) [[ $# -ge 2 ]] || usage; PV=$2; shift 2 ;;
    --vg) [[ $# -ge 2 ]] || usage; VG=$2; shift 2 ;;
    --lv) [[ $# -ge 2 ]] || usage; LV=$2; shift 2 ;;
    --apply) APPLY=true; shift ;;
    *) usage ;;
  esac
done

printf "Plan : ajouter %s au VG %s puis étendre %s avec tout l'espace libre.\n" "$PV" "$VG" "$LV"
if [[ $APPLY == false ]]; then
  printf 'Simulation uniquement. Relancer avec sudo et --apply après vérification.\n'
  exit 0
fi

((EUID == 0)) || {
  printf 'Le mode --apply exige sudo.\n' >&2
  exit 1
}
[[ -b $PV ]] || {
  printf 'Périphérique bloc introuvable : %s\n' "$PV" >&2
  exit 1
}
vgs "$VG" >/dev/null
lvs "$VG/$LV" >/dev/null

if ! pvs --noheadings -o pv_name | awk '{$1=$1};1' | grep -Fxq "$PV"; then
  pvcreate "$PV"
fi

if [[ $(pvs --noheadings -o vg_name "$PV" | xargs) != "$VG" ]]; then
  vgextend "$VG" "$PV"
fi

lvextend --resizefs -l +100%FREE "/dev/$VG/$LV"
pvs
vgs
lvs
df -hT /home
