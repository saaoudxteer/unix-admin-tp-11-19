#!/usr/bin/env bash
set -Eeuo pipefail

readonly USERS=(alice bruno charles daisy eric)
readonly FULL_NAMES=(
  'Alice Toirdrole'
  'Bruno Dagen'
  'Charles Attan'
  'Daisy Diossy'
  'Eric Hochet'
)

((EUID == 0)) || {
  printf 'Exécuter ce script avec sudo.\n' >&2
  exit 1
}
command -v setfacl >/dev/null 2>&1 || {
  printf 'Installer le paquet acl avant de continuer.\n' >&2
  exit 1
}

readonly LAB_OWNER="${SUDO_USER:-root}"
OWNER_HOME="$(getent passwd "$LAB_OWNER" | cut -d: -f6)"
OWNER_GROUP="$(id -gn "$LAB_OWNER")"
readonly OWNER_HOME OWNER_GROUP
readonly LAB_ROOT="${LAB_ROOT:-$OWNER_HOME/tp13-lab}"

for index in "${!USERS[@]}"; do
  user=${USERS[$index]}
  if ! getent passwd "$user" >/dev/null; then
    adduser --disabled-password --gecos "${FULL_NAMES[$index]}" "$user"
  fi
done

getent group guitaristes >/dev/null || addgroup guitaristes
getent group chanteurs >/dev/null || addgroup chanteurs
usermod -aG guitaristes alice
usermod -aG guitaristes bruno
usermod -aG chanteurs bruno
usermod -aG chanteurs charles

install -d -o "$LAB_OWNER" -g "$OWNER_GROUP" -m 0755 "$LAB_ROOT"
install -d -o "$LAB_OWNER" -g "$OWNER_GROUP" -m 0755 "$LAB_ROOT/albums"
install -d -o "$LAB_OWNER" -g guitaristes -m 2770 "$LAB_ROOT/tablatures"
install -d -o "$LAB_OWNER" -g chanteurs -m 2750 "$LAB_ROOT/paroles"

for user in "${USERS[@]}"; do
  setfacl -m "u:$user:--x" "$OWNER_HOME"
done
setfacl -m u:daisy:r-x,m:rwx "$LAB_ROOT/tablatures"
setfacl -m u:eric:rwx,m:rwx "$LAB_ROOT/paroles"

printf 'Album de démonstration\n' >"$LAB_ROOT/albums/README.txt"
printf 'Tablature de démonstration\n' >"$LAB_ROOT/tablatures/README.txt"
printf 'Paroles de démonstration\n' >"$LAB_ROOT/paroles/README.txt"
chown "$LAB_OWNER:$OWNER_GROUP" "$LAB_ROOT/albums/README.txt"
chown "$LAB_OWNER:guitaristes" "$LAB_ROOT/tablatures/README.txt"
chown "$LAB_OWNER:chanteurs" "$LAB_ROOT/paroles/README.txt"
chmod 0644 "$LAB_ROOT"/*/README.txt

printf 'Laboratoire créé dans %s\n' "$LAB_ROOT"
getfacl -p "$LAB_ROOT" "$LAB_ROOT"/*
