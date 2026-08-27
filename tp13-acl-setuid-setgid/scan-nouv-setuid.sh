#!/usr/bin/env bash
set -Eeuo pipefail

readonly STATE_DIR="${1:-$PWD}"
readonly TRACE_1="$STATE_DIR/trace1.txt"
readonly TRACE_2="$STATE_DIR/trace2.txt"
SORT_1="$(mktemp)"
SORT_2="$(mktemp)"
trap 'rm -f -- "$SORT_1" "$SORT_2"' EXIT

mkdir -p "$STATE_DIR"
printf 'Recherche des setuid/setgid en cours...\n'
find / \( -perm -4000 -o -perm -2000 \) \
  -printf '%m %u:%g %p\n' 2>/dev/null >"$TRACE_2" || true

if [[ ! -f $TRACE_1 ]]; then
  mv -- "$TRACE_2" "$TRACE_1"
  printf 'Opération terminée ; relancez une prochaine fois pour comparer.\n'
  exit 0
fi

sort "$TRACE_1" >"$SORT_1"
sort "$TRACE_2" >"$SORT_2"

if diff -u "$SORT_1" "$SORT_2"; then
  printf 'Pas de nouveaux setuid/setgid détectés.\n'
else
  printf 'Des changements setuid/setgid ont été détectés.\n'
fi

mv -- "$TRACE_2" "$TRACE_1"
