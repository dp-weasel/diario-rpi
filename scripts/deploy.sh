#!/usr/bin/env bash
# Despliega en la Raspberry lo que está en master de GitHub.
# Se ejecuta desde el PC:
#
#   ./scripts/deploy.sh            (host ssh por defecto: rpi)
#   DIARIO_HOST=otro ./scripts/deploy.sh
set -euo pipefail

HOST="${DIARIO_HOST:-rpi}"
REPO_URL="https://github.com/dp-weasel/diario-rpi.git"
DIR=/opt/diario-rpi

# Avisar si master local tiene cambios sin subir (la Raspberry baja de GitHub).
git fetch -q origin master
if [ "$(git rev-parse master)" != "$(git rev-parse origin/master)" ]; then
  echo "AVISO: master local y origin/master no coinciden. Se despliega origin/master."
fi

ssh "$HOST" "bash -s" <<REMOTO
set -euo pipefail
if [ ! -d "$DIR/.git" ]; then
  echo "==> Primera instalación: clonando en $DIR"
  sudo install -d -o "\$(id -un)" -g "\$(id -gn)" "$DIR"
  git clone --quiet --branch master "$REPO_URL" "$DIR"
else
  echo "==> Actualizando $DIR"
  git -C "$DIR" pull --ff-only --quiet origin master
fi
echo "Versión: \$(git -C "$DIR" log -1 --format='%h %s')"
"$DIR/scripts/install.sh"
REMOTO
