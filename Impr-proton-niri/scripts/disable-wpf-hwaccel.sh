#!/usr/bin/env bash
# Arregla la ventana completamente en negro de apps .NET/WPF corriendo bajo
# Wine/Proton (comun en launchers de juegos hechos con WPF): el renderizado
# por hardware de WPF falla bajo Wine. Escribe la clave de registro que lo
# desactiva, forzando el rasterizador de software. Se hace una sola vez por
# prefix -- sobrevive a reinicios, solo hay que repetirlo si se borra el prefix.
#
# USO:
#   disable-wpf-hwaccel.sh <appid> <compat-tool-name>
#
# EJEMPLO:
#   disable-wpf-hwaccel.sh 2409806652 proton-cachyos-slr-displayfix
set -euo pipefail

APPID="${1:?Uso: disable-wpf-hwaccel.sh <appid> <compat-tool-name>}"
COMPAT_TOOL="${2:?falta el nombre del compat tool}"

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

"$PROTON_BIN" run reg.exe add 'HKCU\Software\Microsoft\Avalon.Graphics' \
    /v DisableHWAcceleration /t REG_DWORD /d 1 /f

echo ">>> Verificando..."
if grep -q -A3 Avalon "$STEAM_COMPAT_DATA_PATH/pfx/user.reg" 2>/dev/null; then
    grep -A3 Avalon "$STEAM_COMPAT_DATA_PATH/pfx/user.reg"
    echo ">>> OK: clave escrita en el prefix."
else
    echo "AVISO: no encontre la clave en user.reg, revisa a mano." >&2
    exit 1
fi
