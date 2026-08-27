#!/usr/bin/env bash
set -Eeuo pipefail

readonly USER_SHELL="/bin/bash"

usage() {
  printf 'Usage : sudo %s -c|-d fichier_users\n' "${0##*/}" >&2
  exit 2
}

normaliser() {
  iconv -c -f UTF-8 -t ASCII//TRANSLIT \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cd 'a-z0-9'
}

fabriquer_login() {
  local prenoms=$1
  local noms=$2
  local prenoms_norm noms_norm

  prenoms_norm=$(printf '%s' "$prenoms" | normaliser)
  noms_norm=$(printf '%s' "$noms" | normaliser)
  [[ -n $prenoms_norm && -n $noms_norm ]] || return 1
  printf '%s%s\n' "$noms_norm" "${prenoms_norm:0:1}"
}

login_de_l_identite() {
  local identite=$1
  getent passwd | awk -F: -v identite="$identite" '$5 == identite {print $1}'
}

login_disponible() {
  local base=$1
  local candidat=$base
  local numero=1

  while getent passwd "$candidat" >/dev/null; do
    candidat="${base}${numero}"
    ((numero += 1))
  done
  printf '%s\n' "$candidat"
}

creer_user() {
  local prenoms=$1
  local noms=$2
  local identite="$prenoms $noms"
  local existant base login

  existant=$(login_de_l_identite "$identite" | head -n 1)
  if [[ -n $existant ]]; then
    printf 'Déjà présent : %-30s -> %s\n' "$identite" "$existant"
    return
  fi

  base=$(fabriquer_login "$prenoms" "$noms")
  login=$(login_disponible "$base")
  useradd -c "$identite" -m -s "$USER_SHELL" -p '' "$login"
  printf 'Créé         : %-30s -> %s\n' "$identite" "$login"
}

supprimer_user() {
  local prenoms=$1
  local noms=$2
  local identite="$prenoms $noms"
  local trouve=false
  local login

  while IFS= read -r login; do
    [[ -n $login ]] || continue
    trouve=true
    userdel -r "$login"
    printf 'Supprimé     : %-30s -> %s\n' "$identite" "$login"
  done < <(login_de_l_identite "$identite")

  if [[ $trouve == false ]]; then
    printf 'Absent       : %s\n' "$identite"
  fi
}

((EUID == 0)) || {
  printf 'Ce script doit être exécuté avec sudo.\n' >&2
  exit 1
}

[[ $# == 2 ]] || usage
readonly ACTION=$1
readonly USERS_FILE=$2
[[ $ACTION == -c || $ACTION == -d ]] || usage
[[ -r $USERS_FILE ]] || {
  printf 'Fichier illisible : %s\n' "$USERS_FILE" >&2
  exit 1
}

while IFS=: read -r prenoms noms reste; do
  [[ -n ${prenoms// } || -n ${noms// } ]] || continue
  [[ $prenoms != \#* ]] || continue
  if [[ -z $prenoms || -z $noms || -n $reste ]]; then
    printf 'Ligne invalide : %s:%s%s\n' "$prenoms" "$noms" "${reste:+:$reste}" >&2
    exit 1
  fi

  if [[ $ACTION == -c ]]; then
    creer_user "$prenoms" "$noms"
  else
    supprimer_user "$prenoms" "$noms"
  fi
done <"$USERS_FILE"

