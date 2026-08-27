#!/usr/bin/env bash
set -Eeuo pipefail

readonly USERS_FILE="${1:-users.csv}"
((EUID == 0)) || {
  printf 'Exécuter ce script avec sudo.\n' >&2
  exit 1
}
[[ -r $USERS_FILE ]] || {
  printf 'Fichier illisible : %s\n' "$USERS_FILE" >&2
  exit 1
}

while IFS=: read -r login uid gid full_name extra; do
  [[ -n $login && $login != \#* ]] || continue
  [[ -n $uid && -n $gid && -n $full_name && -z $extra ]] || {
    printf 'Ligne invalide pour %s.\n' "$login" >&2
    exit 1
  }

  existing_group=$(getent group "$gid" | cut -d: -f1 || true)
  if [[ -n $existing_group && $existing_group != "$login" ]]; then
    printf 'Le GID %s appartient déjà au groupe %s.\n' "$gid" "$existing_group" >&2
    exit 1
  fi
  getent group "$login" >/dev/null || groupadd -g "$gid" "$login"

  if getent passwd "$login" >/dev/null; then
    current_uid=$(id -u "$login")
    current_gid=$(id -g "$login")
    [[ $current_uid == "$uid" && $current_gid == "$gid" ]] || {
      printf 'Identifiants incohérents pour %s : %s:%s.\n' "$login" "$current_uid" "$current_gid" >&2
      exit 1
    }
    printf 'Déjà conforme : %s (%s:%s)\n' "$login" "$uid" "$gid"
  else
    useradd -m -u "$uid" -g "$gid" -c "$full_name" -s /bin/bash "$login"
    passwd -l "$login" >/dev/null
    printf 'Créé : %s (%s:%s)\n' "$login" "$uid" "$gid"
  fi
done <"$USERS_FILE"

