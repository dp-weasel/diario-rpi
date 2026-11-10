#!/usr/bin/env bash
# Genera el sitio de producción y lo publica en /var/www/diario.
# Lo ejecuta diario-build.service (al guardar una entrada o al desplegar).
#
# Se construye primero en una carpeta temporal y después se sincroniza con
# rsync --delay-updates: si el build falla, el sitio publicado no se toca.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTINO="${DESTINO:-/var/www/diario}"
TEMPORAL="${CACHE_DIRECTORY:-${TMPDIR:-/tmp}}/salida"

cd "$REPO"
rm -rf "$TEMPORAL"
hugo build --environment production --minify --quiet --destination "$TEMPORAL"
# -rlt (sin -g/-o/-p): los archivos heredan el grupo www-data de la carpeta (setgid)
rsync -rlt --delete --delay-updates --chmod=D2750,F640 "$TEMPORAL"/ "$DESTINO"/
rm -rf "$TEMPORAL"
echo "Sitio publicado en $DESTINO ($(find "$DESTINO" -name index.html | wc -l) páginas)"
