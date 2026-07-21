# Impr-proton-niri

### Jugar juegos Windows (Steam/Proton) en niri sin corrupcion grafica ni updaters rotos

## El problema

niri (como la mayoria de compositors wlroots) no trae Xwayland propio: las apps X11
(Steam mismo, y por herencia todo lo que corre bajo Wine/Proton) necesitan
[`xwayland-satellite`](https://github.com/Supreeeme/xwayland-satellite) para existir
como ventanas. Eso resuelve "que las apps X11 abran", pero deja tres problemas
independientes en el camino de jugar con Proton:

1. **xwayland-satellite es software-only (SHM, sin DMA-BUF/GPU).** Suficiente para
   Steam mismo, insuficiente para el juego: hace falta una Xwayland con GPU real.
   Este repo asume que ya existe una segunda Xwayland nativa de niri corriendo en un
   `DISPLAY` propio con aceleracion completa (ver `niri/environment.kdl` en
   `Impr-niri`) — este componente se encarga de forzar que Proton la use.
2. **Apps WPF (.NET) se pintan completamente en negro bajo Wine.** Muy comun en
   launchers de juegos hechos con WPF (Electron no tiene este problema, WPF si).
3. **SteamLinuxRuntime (pressure-vessel) monta `/` como un tmpfs del tamano de la
   mitad de la RAM.** Como `Z:\` en Wine mapea a `/`, cualquier app que chequee
   espacio libre en `Z:\` (instaladores, updaters) puede fallar con un falso
   "insufficient disk space" — aunque el disco real tenga cientos de GB libres.

Cada uno tiene un fix mecanico y reproducible. Los scripts de `scripts/` los aplican
sin tener que rehacer la investigacion cada vez.

## Prerrequisito: `niri/autostart.kdl` y `niri/environment.kdl`

Antes de tocar nada de Steam, confirma que niri ya tiene:

- `xwayland-satellite` arrancando en `autostart.kdl` (DISPLAY global, para Steam y
  apps X11 en general — normalmente `:5` en esta maquina).
- Una **segunda** Xwayland con GPU completa en un DISPLAY distinto (`:1` en esta
  maquina), la que usan los juegos. Ver `Impr-niri/environment.kdl`, comentario
  "Los juegos usan DISPLAY=:1 (XWayland de niri, GPU completa)".

Sin esto, `make-displayfix-proton.sh` no tiene a donde apuntar: el numero de
DISPLAY que le pases tiene que ser el de esa segunda Xwayland.

## Los tres scripts

### `make-displayfix-proton.sh <compat-tool-base> [display] [display-name]`

Genera una copia liviana (3 archivos de texto, nada de binarios) de un compat tool
de Proton ya instalado, que fuerza `DISPLAY=<display>` antes de delegar todo lo
demas al Proton real. Resultado en
`~/.local/share/Steam/compatibilitytools.d/<compat-tool-base>-displayfix/`.

```bash
./scripts/make-displayfix-proton.sh proton-cachyos-slr
# -> compat tool "proton-cachyos-slr-displayfix", listo para elegir en
#    Propiedades del juego -> Compatibilidad
```

Repetir por cada version de Proton distinta que uses para jugar (GE-Proton,
proton-cachyos, el Proton oficial de Valve, etc.) — cada una necesita su propia
variante `-displayfix`.

### `disable-wpf-hwaccel.sh <appid> <compat-tool>`

Escribe `HKCU\Software\Microsoft\Avalon.Graphics\DisableHWAcceleration=1` en el
prefix de Proton de ese appid. Arregla la ventana en negro de launchers WPF. Se
corre una sola vez por prefix (sobrevive a reinicios; solo hay que repetirlo si se
borra el prefix con "Eliminar datos locales de Steam Play").

```bash
./scripts/disable-wpf-hwaccel.sh 2409806652 proton-cachyos-slr-displayfix
```

### `run-proton-direct.sh <appid> <compat-tool> <verbo> <ruta-al-exe> [args...]`

Corre un ejecutable con ese compat tool **sin pasar por el contenedor de
SteamLinuxRuntime** (`_v2-entry-point`), para que `Z:\` mapee al filesystem real en
vez del tmpfs del contenedor. Pensado para lanzar **launchers/updaters/instaladores**
a mano fuera de Steam (por ejemplo, para forzar que un launcher revise version y se
auto-parchee sin la corrupcion de espacio-en-disco). Para jugar de verdad, lanza
desde Steam normalmente — ese camino si quiere pasar por el contenedor (overlay,
integracion, etc.).

```bash
./scripts/run-proton-direct.sh 2409806652 proton-cachyos-slr-displayfix \
    waitforexitandrun /home/ziegler/Arcade/Aottg2Launcher/Aottg2Launcher.exe
```

### `apply-nonsteam-shortcut.py --name "..." [--exe ...] [--startdir ...] [--launch-options ...] [--compat-tool ...] [--dry-run]`

Fija Exe/StartDir/LaunchOptions y el compat tool de un atajo no-Steam **ya
existente** (no lo crea desde cero — ver el porqué en el docstring del script).
Requiere `python-vdf` (`pacman -S python-vdf`) y que **Steam este cerrado del
todo** (si esta abierto, reescribe `shortcuts.vdf` al salir y se pierde el cambio).
Hace backup con timestamp de `shortcuts.vdf` y `config.vdf` antes de escribir; en
esta maquina, un roundtrip sin cambios da un archivo **byte-identico** al
original (verificado).

```bash
# 1. UI de Steam, una sola vez: "Agregar un juego no-Steam" -> elegir el .exe
# 2. Cerrar Steam del todo
./scripts/apply-nonsteam-shortcut.py \
    --name "Attack On Titan Tribute Game" \
    --exe "/home/ziegler/Arcade/Aottg2Launcher/Release/MainApp/Aottg2.exe" \
    --startdir "/home/ziegler/Arcade/Aottg2Launcher/Release/MainApp/" \
    --launch-options '"/home/ziegler/Arcade/aottg2-launch-wrapper.sh" %command% -force-d3d11' \
    --compat-tool proton-cachyos-slr-displayfix \
    --dry-run   # sacar --dry-run cuando el diff se vea bien
```

## Flujo completo para un juego nuevo

1. Confirmar prerrequisitos de niri (seccion de arriba).
2. `make-displayfix-proton.sh <compat-tool-que-vayas-a-usar>` (si no existe ya esa
   variante).
3. En Steam: "Agregar un juego no-Steam" apuntando al ejecutable real del juego (no
   al launcher, si el juego tiene uno separado — ver nota abajo).
4. `apply-nonsteam-shortcut.py` para fijar StartDir/LaunchOptions/CompatTool.
5. Si el juego renderiza corrupto (bandas/scanlines sobre negro): sospechar
   Direct3D 12 via vkd3d-proton en GPUs viejas/integradas. Forzar D3D11 agregando
   `-force-d3d11` (o el flag equivalente del motor) a LaunchOptions.
6. Si el juego tiene un launcher separado con auto-updater propio: el atajo de
   Steam debe apuntar directo al ejecutable del JUEGO (los launchers tipicamente no
   reenvian argumentos como `-force-d3d11` al proceso hijo). Para mantenerlo
   actualizado sin abrir el launcher a mano cada vez, envolver `%command%` en un
   script que corra `run-proton-direct.sh` contra el launcher antes de arrancar el
   juego — ver el README de AoTTG2 (ejemplo real abajo) como referencia completa
   de este patron aplicado a un caso real.

## Ejemplo real

El caso de AoTTG2 (launcher WPF + updater con el bug de espacio en disco + juego
Unity con D3D12 roto) esta documentado end-to-end, con los cuatro scripts en accion,
en su propio repo local: `~/Arcade` (separado de este, porque es juego-especifico,
no parte del entorno reproducible de la maquina) — depende de este componente
via `PROTON_NIRI_SCRIPTS`.
