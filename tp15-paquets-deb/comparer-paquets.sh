#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# != 2 || ! -r $1 || ! -r $2 ]]; then
  printf 'Usage : %s liste_avant liste_apres\n' "${0##*/}" >&2
  exit 2
fi

comm -13 <(LC_ALL=C sort -u "$1") <(LC_ALL=C sort -u "$2")

