#!/usr/bin/env bash
set -Eeuo pipefail

readonly MOUNT_POINT="$HOME/public_html_rocky1"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
readonly LOG_FILE="$STATE_DIR/tp19-sshfs.log"
mkdir -p "$STATE_DIR"

log() {
  printf '%s unmount: %s\n' "$(date --iso-8601=seconds)" "$*" >>"$LOG_FILE"
}

if ! mountpoint -q "$MOUNT_POINT"; then
  log 'aucun montage actif'
  exit 0
fi

if command -v fusermount3 >/dev/null 2>&1; then
  unmount_command=(fusermount3 -u "$MOUNT_POINT")
else
  unmount_command=(fusermount -u "$MOUNT_POINT")
fi

if output=$("${unmount_command[@]}" 2>&1); then
  log "$MOUNT_POINT démonté"
else
  log "échec : $output"
fi

