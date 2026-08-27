#!/usr/bin/env bash
set -Eeuo pipefail

printf 'Utilisateurs sans mot de passe dans /etc/shadow :\n'
if ((EUID == 0)); then
  awk -F: '$2 == "" {print "  " $1}' /etc/shadow
else
  printf '  Relancer avec sudo pour lire /etc/shadow.\n'
fi

printf '\nUtilisateurs dont UID = GID :\n'
awk -F: '$3 == $4 {printf "  %-20s uid=%s gid=%s\n", $1, $3, $4}' /etc/passwd

