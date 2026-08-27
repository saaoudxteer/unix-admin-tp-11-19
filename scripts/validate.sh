#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

printf '1/4 Syntaxe Bash...\n'
while IFS= read -r -d '' script; do
  bash -n "$script"
done < <(find "$REPO_ROOT" -type f -name '*.sh' -print0)

if command -v shellcheck >/dev/null 2>&1; then
  printf '2/4 ShellCheck...\n'
  while IFS= read -r -d '' script; do
    shellcheck -x "$script"
  done < <(find "$REPO_ROOT" -type f -name '*.sh' -print0)
else
  printf '2/4 ShellCheck absent : étape ignorée.\n'
fi

printf '3/4 Sources C...\n'
if command -v gcc >/dev/null 2>&1; then
  while IFS= read -r -d '' source; do
    gcc -Wall -Wextra -Werror -std=c11 -fsyntax-only "$source"
  done < <(find "$REPO_ROOT" -type f -name '*.c' -print0)
else
  printf 'gcc absent : étape ignorée.\n'
fi

printf '4/4 Construction du paquet de démonstration...\n'
if command -v gcc >/dev/null 2>&1 && command -v ar >/dev/null 2>&1; then
  "$REPO_ROOT/tp15-paquets-deb/gen-demo-deb.sh" "$TEMP_DIR"
  test -s "$TEMP_DIR/euid-demo_1.0_$(dpkg --print-architecture).deb"
else
  printf 'Outils de construction absents : étape ignorée.\n'
fi

printf 'Validation terminée avec succès.\n'
