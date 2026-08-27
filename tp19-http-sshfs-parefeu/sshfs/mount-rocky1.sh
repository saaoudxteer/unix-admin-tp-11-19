#!/usr/bin/env bash
set -Eeuo pipefail

readonly ROCKY_HOST="${ROCKY_HOST:-rocky1.lab.test}"
readonly REMOTE_DIR="/space/users/$USER/public_html"
readonly MOUNT_POINT="$HOME/public_html_rocky1"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
readonly LOG_FILE="$STATE_DIR/tp19-sshfs.log"

mkdir -p "$STATE_DIR" "$MOUNT_POINT"
log() {
  printf '%s mount: %s\n' "$(date --iso-8601=seconds)" "$*" >>"$LOG_FILE"
}

if mountpoint -q "$MOUNT_POINT"; then
  log 'déjà monté'
  exit 0
fi

if ! ssh -o BatchMode=yes -o ConnectTimeout=4 "$USER@$ROCKY_HOST" true 2>/dev/null; then
  log "hôte indisponible ou clé refusée : $ROCKY_HOST"
  exit 0
fi

if output=$(sshfs \
  -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,ConnectTimeout=5 \
  "$USER@$ROCKY_HOST:$REMOTE_DIR" "$MOUNT_POINT" 2>&1); then
  log "$REMOTE_DIR monté sur $MOUNT_POINT"
else
  log "échec : $output"
fi

