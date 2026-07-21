#!/usr/bin/env bash
# Corre un ejecutable Windows con un compat tool de Proton SALTANDOSE el
# contenedor de SteamLinuxRuntime (_v2-entry-point / pressure-vessel).
#
# Por que: dentro de ese contenedor, "/" es un tmpfs del tamano de la mitad de
# la RAM de la maquina (comportamiento normal de pressure-vessel). Como Z:\ en
# Wine mapea a "/", cualquier app que revise espacio libre en Z:\ (instaladores,
# updaters tipo GameLauncherCore/Velopack/etc.) puede fallar con un falso
# "insufficient disk space" aunque el disco real tenga cientos de GB libres.
# Confirmalo con:
#   "$STEAM/steamapps/common/SteamLinuxRuntime_4/_v2-entry-point" --verb=run -- df -h /
# Saltarse el contenedor deja que Z:\ mapee al filesystem real. Sirve para
# launchers/updaters e instaladores; para el JUEGO en si generalmente conviene
# lanzarlo desde Steam normalmente (con el contenedor), que es lo que agrega
# el overlay/reaper/RGP y demas integracion -- este script es para la parte de
# mantenimiento (parchear, reparar, instalar), no para jugar.
#
# USO:
#   run-proton-direct.sh <appid> <compat-tool-name> <verbo> <ruta-al-exe> [args...]
#
# EJEMPLO (comprobar/actualizar un launcher sin la UI, ver ../README.md):
#   run-proton-direct.sh 2409806652 proton-cachyos-slr-displayfix \
#       waitforexitandrun /home/ziegler/Arcade/Aottg2Launcher/Aottg2Launcher.exe
set -euo pipefail

APPID="${1:?Uso: run-proton-direct.sh <appid> <compat-tool-name> <verbo> <ruta-al-exe> [args...]}"
COMPAT_TOOL="${2:?falta el nombre del compat tool}"
VERB="${3:?falta el verbo (run / waitforexitandrun / ...)}"
EXE="${4:?falta la ruta al ejecutable}"
shift 4 || true

STEAM="$HOME/.local/share/Steam"

PROTON_BIN=""
for d in \
    "$STEAM/compatibilitytools.d/$COMPAT_TOOL" \
    "/usr/share/steam/compatibilitytools.d/$COMPAT_TOOL"
do
    if [ -x "$d/proton" ]; then
        PROTON_BIN="$d/proton"
        break
    fi
done

if [ -z "$PROTON_BIN" ]; then
    echo "ERROR: no encontre el compat tool '$COMPAT_TOOL'" >&2
    exit 1
fi

export STEAM_COMPAT_DATA_PATH="$STEAM/steamapps/compatdata/$APPID"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM"
export SteamAppId="$APPID" STEAM_COMPAT_APP_ID="$APPID" SteamGameId="$APPID"

exec "$PROTON_BIN" "$VERB" "$EXE" "$@"
