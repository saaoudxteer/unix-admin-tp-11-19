#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
requested_output_dir="${1:-$PWD}"
essential_flag=${2:-}
[[ -z $essential_flag || $essential_flag == --essential ]] || {
  printf 'Usage : %s [repertoire_sortie] [--essential]\n' "${0##*/}" >&2
  exit 2
}
if [[ $essential_flag == --essential ]]; then
  essential_value=yes
else
  essential_value=no
fi
mkdir -p -- "$requested_output_dir"
OUTPUT_DIR="$(cd -- "$requested_output_dir" && pwd)"
ARCH="$(dpkg --print-architecture)"
readonly SCRIPT_DIR OUTPUT_DIR ARCH
readonly PACKAGE_FILE="$OUTPUT_DIR/euid-demo_1.0_${ARCH}.deb"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf -- "$BUILD_DIR"' EXIT

command -v gcc >/dev/null 2>&1 || {
  printf 'gcc est requis. Installer le paquet build-essential.\n' >&2
  exit 1
}
command -v ar >/dev/null 2>&1 || {
  printf 'ar est requis. Installer le paquet binutils.\n' >&2
  exit 1
}

mkdir -p "$BUILD_DIR/data/usr/bin" "$BUILD_DIR/control"
gcc -Wall -Wextra -Werror -std=c11 \
  "$SCRIPT_DIR/src/euid-demo.c" -o "$BUILD_DIR/data/usr/bin/euid-demo"
chmod 0755 "$BUILD_DIR/data/usr/bin/euid-demo"

(
  cd "$BUILD_DIR/data"
  md5sum usr/bin/euid-demo >"$BUILD_DIR/control/md5sums"
)

cat >"$BUILD_DIR/control/postinst" <<'POSTINST'
#!/bin/sh
set -e
chown root:root /usr/bin/euid-demo
chmod 4755 /usr/bin/euid-demo
POSTINST
chmod 0755 "$BUILD_DIR/control/postinst"

cat >"$BUILD_DIR/control/control" <<CONTROL
Package: euid-demo
Version: 1.0
Architecture: $ARCH
Essential: $essential_value
Maintainer: Mohamed Saaoudi <118655600+saaoudxteer@users.noreply.github.com>
Installed-Size: 20
Depends: libc6
Section: admin
Priority: optional
Description: safe setuid UID/EUID demonstration
 This educational package displays real and effective user identifiers.
 It does not start a shell or modify user data.
CONTROL

printf '2.0\n' >"$BUILD_DIR/debian-binary"
(
  cd "$BUILD_DIR/data"
  tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
    -cJf "$BUILD_DIR/data.tar.xz" ./usr/bin/euid-demo
)
(
  cd "$BUILD_DIR/control"
  tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
    -cJf "$BUILD_DIR/control.tar.xz" ./control ./md5sums ./postinst
)
(
  cd "$BUILD_DIR"
  ar r "$PACKAGE_FILE" debian-binary control.tar.xz data.tar.xz >/dev/null
)

printf 'Paquet créé : %s\n' "$PACKAGE_FILE"
