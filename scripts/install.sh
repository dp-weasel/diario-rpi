#!/usr/bin/env bash
# Instala o actualiza el diario en la Raspberry. Es idempotente: se puede
# ejecutar en cada despliegue. Requiere sudo.
#
#   /opt/diario-rpi/scripts/install.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
USUARIO="$(id -un)"
DESTINO=/var/www/diario
HTPASSWD=/etc/apache2/diario.htpasswd
HUGO_MIN="$(sed -n 's/^ *min *= *"\(.*\)"/\1/p' "$REPO/config/_default/hugo.toml")"

paso() { printf '\n==> %s\n' "$*"; }

paso "Comprobando requisitos"
command -v hugo  >/dev/null || { echo "Falta hugo (versión $HUGO_MIN)"; exit 1; }
command -v rsync >/dev/null || { echo "Falta rsync"; exit 1; }
[ -f "$REPO/themes/PaperMod/theme.toml" ] || { echo "Falta el tema: git submodule update --init"; exit 1; }
hugo version

paso "Carpeta del sitio: $DESTINO (dueño $USUARIO, grupo www-data, sin acceso para otros)"
sudo install -d -o "$USUARIO" -g www-data -m 2750 "$DESTINO"

paso "Servicio de systemd"
sudo install -m 644 "$REPO/deploy/systemd/diario-build.service" \
                    "$REPO/deploy/systemd/diario-build.path" /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now --quiet diario-build.path

paso "Generando el sitio"
sudo systemctl start diario-build.service
journalctl -u diario-build.service -n 1 -o cat --no-pager

paso "Apache"
sudo install -m 644 "$REPO/deploy/apache/diario.conf" /etc/apache2/sites-available/diario.conf
sudo a2ensite -q diario
sudo apache2ctl configtest
sudo systemctl reload apache2

if ! sudo test -s "$HTPASSWD"; then
  printf '\n!!  Falta la contraseña. Mientras no exista, el sitio responde con error 500\n'
  printf '!!  (no muestra contenido). Crearla con:\n'
  printf '!!    sudo htpasswd -c %s %s\n' "$HTPASSWD" "$USUARIO"
fi

paso "Listo: https://diario.raspi.lan"
