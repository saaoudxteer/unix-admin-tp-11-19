#!/usr/bin/env bash
set -Eeuo pipefail

readonly PORT="${ROT13_PORT:-13000}"
TEMP_DIR="$(mktemp -d)"
readonly FIFO="$TEMP_DIR/reponse.fifo"

cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT INT TERM
mkfifo "$FIFO"

dialoguer() {
  local ligne
  printf 'Service ROT13 ; entrez une ligne :\n'
  if IFS= read -r ligne; then
    tr 'a-zA-Z' 'n-za-mN-ZA-M' <<<"$ligne"
  fi
}

printf 'Serveur en écoute sur le port %s...\n' "$PORT"
while true; do
  # Le FIFO est volontairement utilisé dans les deux sens par deux processus.
  # shellcheck disable=SC2094
  nc -l -4 "$PORT" <"$FIFO" | dialoguer >"$FIFO"
done
