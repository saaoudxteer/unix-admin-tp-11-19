#!/usr/bin/env bash
set -Eeuo pipefail

printf '=== Périphériques ===\n'
lsblk -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINTS
printf '\n=== Physical Volumes ===\n'
sudo pvs -o pv_name,vg_name,pv_size,pv_free
printf '\n=== Volume Groups ===\n'
sudo vgs -o vg_name,vg_size,vg_free,pv_count,lv_count
printf '\n=== Logical Volumes ===\n'
sudo lvs -o lv_name,vg_name,lv_size,lv_path
printf '\n=== Systèmes de fichiers ===\n'
df -hT / /home

