#!/usr/bin/env bash
# Genera una variante "-displayfix" de un compat tool de Proton ya instalado,
# forzando DISPLAY a la Xwayland nativa de niri en vez del DISPLAY global de
# xwayland-satellite (ver ../README.md para el porque).
#
# USO:
#   make-displayfix-proton.sh <nombre-compat-tool-base> [display] [display-name]
#
# EJEMPLOS:
#   make-displayfix-proton.sh proton-cachyos-slr
#   make-displayfix-proton.sh GE-Proton9-20 :1 "GE-Proton 9-20 (Display Fix)"
#
# El compat tool base puede estar instalado en cualquiera de las ubicaciones
# habituales de Steam (system-wide o ~/.local/share/Steam). El resultado se
# instala en ~/.local/share/Steam/compatibilitytools.d/<base>-displayfix/,
# listo para elegirlo desde Steam en Propiedades -> Compatibilidad.
set -euo pipefail

BASE_NAME="${1:?Uso: make-displayfix-proton.sh <nombre-compat-tool-base> [display] [display-name]}"
DISPLAY_NUM="${2:-:1}"
DISPLAY_LABEL="${3:-Proton ${BASE_NAME} (Display Fix ${DISPLAY_NUM})}"

SEARCH_DIRS=(
    "$HOME/.local/share/Steam/compatibilitytools.d/$BASE_NAME"
    "/usr/share/steam/compatibilitytools.d/$BASE_NAME"
    "/usr/local/share/steam/compatibilitytools.d/$BASE_NAME"
)

BASE_DIR=""
for d in "${SEARCH_DIRS[@]}"; do
    if [ -x "$d/proton" ]; then
        BASE_DIR="$d"
        break
    fi
done

if [ -z "$BASE_DIR" ]; then
    echo "ERROR: no encontre un compat tool instalado llamado '$BASE_NAME' (busque en:" >&2
    printf '  %s\n' "${SEARCH_DIRS[@]}" >&2
    echo ") con un ejecutable 'proton' dentro." >&2
    exit 1
fi

OUT_NAME="${BASE_NAME}-displayfix"
OUT_DIR="$HOME/.local/share/Steam/compatibilitytools.d/$OUT_NAME"

if [ -e "$OUT_DIR" ]; then
    echo "ERROR: $OUT_DIR ya existe. Borralo primero si queres regenerarlo." >&2
    exit 1
fi

# Hereda require_tool_appid del compat tool base si lo tiene declarado
# (normalmente el appid de Steam Linux Runtime soldier/sniper, 1391110/4183110
# segun la version); si no lo encuentra, usa el valor mas comun como default.
REQUIRE_APPID="4183110"
if [ -f "$BASE_DIR/toolmanifest.vdf" ]; then
    found=$(grep -oP '"require_tool_appid"\s*"\K[0-9]+' "$BASE_DIR/toolmanifest.vdf" 2>/dev/null || true)
    [ -n "$found" ] && REQUIRE_APPID="$found"
fi

mkdir -p "$OUT_DIR"

cat >"$OUT_DIR/proton" <<EOF
#!/usr/bin/env bash
# Wrapper de $BASE_NAME: fuerza DISPLAY=$DISPLAY_NUM (Xwayland nativa de niri,
# GPU completa) en vez del DISPLAY global de xwayland-satellite (software-only).
# Delega todo lo demas al proton real. Generado por make-displayfix-proton.sh,
# no editar a mano -- volver a correr el script si hace falta regenerarlo.
export DISPLAY=$DISPLAY_NUM
exec "$BASE_DIR/proton" "\$@"
EOF
chmod +x "$OUT_DIR/proton"

cat >"$OUT_DIR/compatibilitytool.vdf" <<EOF
"compatibilitytools"
{
  "compat_tools"
  {
    "$OUT_NAME"
    {
      "install_path" "."
      "display_name" "$DISPLAY_LABEL"
      "from_oslist"  "windows"
      "to_oslist"    "linux"
    }
  }
}
EOF

cat >"$OUT_DIR/toolmanifest.vdf" <<EOF
"manifest"
{
  "version" "2"
  "commandline" "/proton %verb%"
  "require_tool_appid" "$REQUIRE_APPID"
  "use_sessions" "1"
  "compatmanager_layer_name" "proton"
}
EOF

echo ">>> Creado: $OUT_DIR"
echo ">>> Reinicia Steam (o abre Configuracion -> Compatibilidad para refrescar la lista)."
echo ">>> Elegilo en Propiedades del juego -> Compatibilidad: '$DISPLAY_LABEL'"
