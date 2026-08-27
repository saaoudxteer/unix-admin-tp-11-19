#!/usr/bin/env bash
set -Eeuo pipefail

printf 'Identité observée depuis le script :\n'
id
printf "Le setuid d'un script interprété est ignoré par Linux.\n"
