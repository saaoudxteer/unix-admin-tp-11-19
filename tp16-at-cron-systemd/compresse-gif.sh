#!/usr/bin/env bash
set -Eeuo pipefail

readonly SEARCH_DIR="${1:-$HOME}"
[[ -d $SEARCH_DIR ]] || {
  printf 'Répertoire introuvable : %s\n' "$SEARCH_DIR" >&2
  exit 1
}

printf 'Compression des images GIF dans %s...\n' "$SEARCH_DIR"
find "$SEARCH_DIR" -type f -iname '*.gif' -print0 \
  | while IFS= read -r -d '' image; do
      printf '  %s\n' "$image"
      gzip -9 -- "$image"
    done

