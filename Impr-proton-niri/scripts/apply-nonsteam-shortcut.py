#!/usr/bin/env python3
"""Aplica Exe/StartDir/LaunchOptions/CompatTool a un atajo no-Steam ya creado.

No CREA el atajo desde cero (el algoritmo de Steam para generar el appid a
partir de exe+nombre no esta documentado de forma estable entre versiones, y
reimplementarlo mal puede generar un atajo fantasma). El flujo es:

  1. En Steam (con la UI): "Agregar un juego no-Steam" -> elegir el .exe.
     Esto crea la entrada y le asigna un appid; alcanza con hacerlo una vez.
  2. Cerrar Steam del todo.
  3. Correr este script para fijar Exe/StartDir/LaunchOptions y el compat
     tool exactos -- lo tedioso de repetir a mano en Propiedades.

Hace backup con timestamp de shortcuts.vdf y config.vdf antes de escribir.
Requiere el paquete `python-vdf` (ya viene en CachyOS: pacman -S python-vdf).

USO:
  apply-nonsteam-shortcut.py --name "<AppName exacto>" \\
      [--exe "<ruta al ejecutable>"] [--startdir "<directorio>"] \\
      [--launch-options "<opciones>"] [--compat-tool "<nombre-compat-tool>"] \\
      [--steam-root ~/.local/share/Steam] [--dry-run]
"""
import argparse
import glob
import os
import shutil
import subprocess
import sys
import time

try:
    import vdf
except ImportError:
    sys.exit("ERROR: falta el modulo python-vdf (pacman -S python-vdf)")


def steam_is_running() -> bool:
    result = subprocess.run(["pgrep", "-x", "steam"], stdout=subprocess.DEVNULL)
    return result.returncode == 0


def find_shortcuts_files(steam_root: str) -> list[str]:
    return sorted(glob.glob(os.path.join(steam_root, "userdata", "*", "config", "shortcuts.vdf")))


def backup(path: str) -> str:
    stamp = time.strftime("%Y%m%d-%H%M%S")
    dst = f"{path}.bak.{stamp}"
    shutil.copy2(path, dst)
    return dst


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--name", required=True, help="AppName exacto del atajo, tal como aparece en Steam")
    p.add_argument("--exe", help="Ruta al ejecutable (se guarda entre comillas)")
    p.add_argument("--startdir", help="Directorio de inicio")
    p.add_argument("--launch-options", help="Opciones de lanzamiento")
    p.add_argument("--compat-tool", help="Nombre interno del compat tool (carpeta en compatibilitytools.d)")
    p.add_argument("--steam-root", default=os.path.expanduser("~/.local/share/Steam"))
    p.add_argument("--dry-run", action="store_true", help="Muestra los cambios sin escribir nada")
    args = p.parse_args()

    if not args.dry_run and steam_is_running():
        sys.exit("ERROR: Steam esta corriendo. Cerralo del todo antes de correr este script "
                  "(reescribe shortcuts.vdf al salir y se perderian los cambios).")

    shortcut_files = find_shortcuts_files(args.steam_root)
    if not shortcut_files:
        sys.exit(f"ERROR: no encontre ningun shortcuts.vdf bajo {args.steam_root}/userdata/*/config/")
    if len(shortcut_files) > 1:
        print("AVISO: hay multiples usuarios de Steam en esta maquina, uso el primero:", file=sys.stderr)
        for f in shortcut_files:
            print(f"  {f}", file=sys.stderr)
    shortcuts_path = shortcut_files[0]
    config_path = os.path.join(args.steam_root, "config", "config.vdf")

    with open(shortcuts_path, "rb") as f:
        shortcuts = vdf.binary_load(f)

    entries = shortcuts.get("shortcuts", {})
    match_key = None
    for key, entry in entries.items():
        if entry.get("AppName") == args.name:
            match_key = key
            break

    if match_key is None:
        names = ", ".join(repr(e.get("AppName")) for e in entries.values())
        sys.exit(
            f"ERROR: no encontre un atajo con AppName={args.name!r}.\n"
            f"Atajos existentes: {names or '(ninguno)'}\n"
            "Creá el atajo primero desde Steam (Agregar un juego no-Steam)."
        )

    entry = entries[match_key]
    appid_signed = entry["appid"]
    appid_unsigned = appid_signed & 0xFFFFFFFF

    changes = []
    if args.exe:
        wanted = args.exe if args.exe.startswith('"') else f'"{args.exe}"'
        if entry.get("Exe") != wanted:
            changes.append(("Exe", entry.get("Exe"), wanted))
            entry["Exe"] = wanted
    if args.startdir:
        if entry.get("StartDir") != args.startdir:
            changes.append(("StartDir", entry.get("StartDir"), args.startdir))
            entry["StartDir"] = args.startdir
    if args.launch_options is not None:
        if entry.get("LaunchOptions") != args.launch_options:
            changes.append(("LaunchOptions", entry.get("LaunchOptions"), args.launch_options))
            entry["LaunchOptions"] = args.launch_options

    compat_change = None
    config_data = None
    if args.compat_tool:
        with open(config_path, "r", encoding="utf-8") as f:
            config_data = vdf.load(f)
        try:
            mapping = config_data["InstallConfigStore"]["Software"]["Valve"]["Steam"]["CompatToolMapping"]
        except KeyError:
            sys.exit(f"ERROR: no encontre InstallConfigStore>Software>Valve>Steam>CompatToolMapping en {config_path}")
        appid_str = str(appid_unsigned)
        current = mapping.get(appid_str, {}).get("name")
        if current != args.compat_tool:
            compat_change = (current, args.compat_tool)
            mapping[appid_str] = {"name": args.compat_tool, "config": "", "priority": "250"}

    print(f">>> Atajo: {args.name!r} (appid {appid_unsigned})")
    if not changes and not compat_change:
        print(">>> Nada que cambiar, ya esta todo como se pidio.")
        return 0

    for field, old, new in changes:
        print(f"  {field}:")
        print(f"    - {old!r}")
        print(f"    + {new!r}")
    if compat_change:
        print("  CompatTool:")
        print(f"    - {compat_change[0]!r}")
        print(f"    + {compat_change[1]!r}")

    if args.dry_run:
        print(">>> --dry-run: no se escribio nada.")
        return 0

    if changes:
        bak = backup(shortcuts_path)
        print(f">>> Backup: {bak}")
        with open(shortcuts_path, "wb") as f:
            vdf.binary_dump(shortcuts, f)
        print(f">>> Escrito: {shortcuts_path}")

    if compat_change:
        bak = backup(config_path)
        print(f">>> Backup: {bak}")
        with open(config_path, "w", encoding="utf-8") as f:
            vdf.dump(config_data, f, pretty=True)
        print(f">>> Escrito: {config_path}")

    print(">>> Listo. Abri Steam y confirma en Propiedades que quedo como se espera.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
