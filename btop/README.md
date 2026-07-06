# btop

## Overview

Configuration for [btop++](https://github.com/aristocratos/btop), the resource monitor (CPU/memory/network/process/disk/battery), providing the Imperator color theme and a curated set of behavioral defaults. Launched via niri's `Mod+Shift+B { spawn "kitty" "btop"; }`.

## Design Philosophy

- **Presets over manual layout switching.** Three named presets (`cpu:1:default,proc:0:default`, `cpu:0:default,mem:0:default,net:0:default`, `cpu:0:block,net:0:tty`) are predefined so switching monitoring focus (process-heavy view vs. resource-overview vs. low-color-depth fallback) is a single keypress, not a manual box-by-box reconfiguration.
- **Absolute theme path, not a relative lookup.** `color_theme` points at the fully-qualified `~/.config/btop/themes/Imperator.theme` rather than relying on btop's package-relative theme search path, guaranteeing the personal theme is found regardless of how btop itself was installed.
- **Synchronized terminal output over maximal redraw rate.** `terminal_sync = true` opts into terminal synchronized-output escape sequences specifically to reduce flicker on supported terminals (kitty included) — a deliberate tradeoff of a small amount of latency for visibly smoother updates.

## Key Features

- Full Imperator color theme (`themes/Imperator.theme`) applied over btop's box-based UI.
- Three quick-switch layout presets covering process-focus, balanced-overview, and a `tty`/`block` low-fidelity fallback.
- Per-process CPU graphs, gradient-shaded process list, and CPU-core-colored process coloring (`proc_colors`, `proc_gradient`, `proc_cpu_graphs` all enabled).
- Battery, GPU (NVIDIA/AMD/Intel), and PCIe-throughput monitoring enabled, with per-GPU custom naming slots available.
- `braille` graph symbols by default for maximum graph resolution, with per-box overrides available (`graph_symbol_cpu`/`_gpu`/`_mem`/`_net`/`_proc`).

## Configuration Breakdown

| Section (representative keys) | Responsibility | Impact |
|---|---|---|
| `color_theme`, `theme_background`, `truecolor` | Theme selection and color-depth behavior | `theme_background = false` lets the terminal's own background show through instead of btop painting its own, preserving kitty's frosted-glass effect behind btop |
| `presets`, `shown_boxes` | Layout preset definitions and the currently active box selection | Controls which monitoring boxes (`cpu`, `mem`, `net`, `proc`, `gpu0-5`) are visible and in what arrangement |
| `update_ms`, `background_update` | Refresh interval and whether menus keep updating the background UI | `update_ms = 2000` balances graph smoothness against sampling/redraw overhead |
| `proc_*` keys | Process list behavior — sorting, tree view, per-core vs. aggregate CPU%, memory display units, gradient/color coding | Tunes the process box independently of the resource-graph boxes |
| `cpu_*`/`show_cpu_watts`/`check_temp`/`cpu_sensor` | CPU box detail level — per-core temps, frequency display/calculation mode, power draw (requires elevated capabilities) | `show_cpu_watts` needs `make setcap`/`make setuid`/root to actually read power data — otherwise silently shows nothing for that field |
| `mem_graphs`, `show_disks`, `use_fstab`, `zfs_*` | Memory/disk box behavior — graph vs. meter display, disk enumeration source, ZFS-specific accounting | `use_fstab = true` sources the disk list from `/etc/fstab` and implicitly disables `only_physical` |
| `net_auto`, `net_sync`, `net_download`/`net_upload` | Network graph scaling — auto-rescaling vs. fixed ceilings, and whether up/down share one scale | `net_auto = true` makes the fixed values effectively inert unless auto-scaling is later disabled |
| `show_battery`, `selected_battery`, `show_battery_watts` | Battery status display | Relevant on laptop hardware; auto-detects the battery by default |

## Dependencies

- `btop` (btop++) ≥ 1.4.7 (config format version-pinned via the file's own header comment)
- For `show_cpu_watts`: elevated capabilities via `make setcap`, `make setuid`, or running as root — otherwise the field is silently blank
- Optional: NVIDIA/AMD GPU drivers with the respective monitoring libraries (`nvml`, `rsmi`) for GPU box data

## Usage

Deployed to `~/.config/btop/btop.conf`, with the theme file at `~/.config/btop/themes/Imperator.theme` (or the absolute path configured in `color_theme` must match wherever the theme actually lives). `save_config_on_exit = true` means btop rewrites this file on every clean exit — in-session UI changes (via btop's own options menu) persist automatically without manually re-editing the config.

## Customization

- **Which boxes are shown / preset switching**: `shown_boxes` and the `presets` string — presets use the format `box:position:graph_symbol`, comma-separated per preset, space-separated between presets.
- **Theme**: swap `color_theme` to a different `.theme` file path, or edit `themes/Imperator.theme` directly for palette tweaks.
- **Update frequency**: `update_ms` — lower values increase responsiveness at a proportional CPU cost for the sampling/redraw cycle itself.
- **Process sort/display**: `proc_sorting`, `proc_tree`, `proc_per_core`, `proc_mem_bytes`.

## Performance Considerations

- `update_ms = 2000` is btop's own recommended floor for smooth graph sampling — lowering it increases btop's own CPU usage roughly proportionally, which is somewhat self-defeating in a *resource monitor*.
- `terminal_sync = true` trades a small latency cost for reduced screen tearing/flicker on synchronized-output-capable terminals; on terminals without support it has no effect (gracefully ignored).
- `proc_cpu_graphs`/`proc_gradient`/`proc_colors` add modest per-frame rendering cost in the process box proportional to the number of visible rows, not the total process count.
- `nvml_measure_pcie_speeds`/`rsmi_measure_pcie_speeds` (both `true`) can measurably impact performance on certain GPU models per btop's own documentation comment — disable if the GPU box itself becomes a monitoring overhead concern.

## Notes

- `color_theme` uses an **absolute, user-specific path** (`/home/ziegler/.config/btop/themes/Imperator.theme`) — deploying under a different username/home directory requires updating this line, or btop will fail to find the theme and fall back to its built-in default.
- `show_cpu_watts = true` will show no data at all without the extra capability grant (`make setcap`) — this is not a bug in the config, it's a kernel-permission requirement upstream.
- `disable_presets = "Off"` — all three presets remain switchable at runtime; setting this to `"Custom"` or `"All"` would disable the preset-cycling feature entirely.
