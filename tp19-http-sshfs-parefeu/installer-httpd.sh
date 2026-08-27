#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

((EUID == 0)) || {
  printf 'Exécuter ce script avec sudo.\n' >&2
  exit 1
}
(($# > 0)) || {
  printf 'Usage : sudo %s utilisateur [utilisateur...]\n' "${0##*/}" >&2
  exit 2
}
command -v dnf >/dev/null 2>&1 || {
  printf 'Ce script est prévu pour Rocky Linux.\n' >&2
  exit 1
}

dnf install -y httpd policycoreutils-python-utils
install -d -o root -g root -m 0711 /space /space/users

for user in "$@"; do
  getent passwd "$user" >/dev/null || {
    printf 'Utilisateur inconnu : %s\n' "$user" >&2
    exit 1
  }
  group=$(id -gn "$user")
  install -d -o "$user" -g "$group" -m 0711 "/space/users/$user"
  install -d -o "$user" -g "$group" -m 0755 "/space/users/$user/public_html"
  if [[ ! -e /space/users/$user/public_html/index.html ]]; then
    printf '<!doctype html>\n<html lang="fr"><meta charset="utf-8"><title>%s</title><h1>Page de %s</h1></html>\n' \
      "$user" "$user" >"/space/users/$user/public_html/index.html"
    chown "$user:$group" "/space/users/$user/public_html/index.html"
    chmod 0644 "/space/users/$user/public_html/index.html"
  fi
done

install -o root -g root -m 0644 \
  "$SCRIPT_DIR/httpd/user-space.conf" /etc/httpd/conf.d/user-space.conf
if semanage fcontext -l | grep -Fq '/space/users'; then
  semanage fcontext -m -t httpd_sys_content_t '/space/users(/.*)?'
else
  semanage fcontext -a -t httpd_sys_content_t '/space/users(/.*)?'
fi
restorecon -RFv /space/users
apachectl configtest
systemctl enable --now httpd
systemctl --no-pager --full status httpd
