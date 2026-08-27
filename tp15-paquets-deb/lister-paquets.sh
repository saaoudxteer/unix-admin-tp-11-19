#!/usr/bin/env bash
set -Eeuo pipefail

readonly OUTPUT_FILE="${1:-liste-paquets.txt}"
dpkg-query -W -f='${binary:Package}\n' | LC_ALL=C sort -u >"$OUTPUT_FILE"
printf '%s paquets enregistrés dans %s\n' "$(wc -l <"$OUTPUT_FILE")" "$OUTPUT_FILE"

