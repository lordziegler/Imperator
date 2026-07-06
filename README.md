# Imperator

### A modular, reproducible desktop environment for Niri on Arch/CachyOS

## Overview

Imperator is a personal system-configuration repository for a Wayland desktop built on [Niri](https://github.com/YaLTeR/niri), a scrollable-tiling compositor, running on Arch/CachyOS. It is not a single dotfile collection but a coherent environment specification: compositor configuration, shell environment, application theming, notification/session UI, boot and login theming, and the KDE Frameworks daemon layer that bridges GTK theming into a Plasma-Shell-less session.

The repository solves a specific problem: reproducing a fully themed, fully functional Niri desktop on a new machine or after a clean reinstall, without reinstalling unnecessary packages or re-deriving configuration decisions from memory. Every component's `README.md` documents its own design rationale in place, so the configuration is self-explaining rather than dependent on external notes.

The visual identity (an amber/obsidian palette, named "Imperator") is a Dune-inspired dark theme applied consistently across terminal, compositor, GTK/Qt toolkits, notifications, launcher, boot loader, and login screen. The palette is defined once (`assets/Imperator-palette_1.md`) and consumed independently by each tool in that tool's own color-format idiom — there is no shared runtime theming engine; consistency is maintained across per-tool color definitions derived from the same source palette.

## System Philosophy

- **Reproducibility over convenience.** Every component that can be deployed as a symlink from this repository into its live config path is deployed that way, so the repository is always the single source of truth — editing a live config and editing the repository are the same action.
- **Modularity by concern, not by convenience.** Multi-file components (Niri's `.kdl` includes, zsh's `aliases`/`exports`/`functions`/`plugins` split, the `theme/` toolkit-by-toolkit breakdown) separate configuration by responsibility so a change to one concern cannot silently affect another.
- **Minimal daemon footprint.** The environment deliberately avoids running a full desktop shell (no `plasmashell`, no `kwin`, no GNOME Shell) — only the specific KDE Frameworks daemons required for GTK theme propagation (`kded6`, `kde-gtk-config`, `plasma-kactivitymanagerd`) are kept running. `theme/kde-minimal-deps.md` documents this boundary explicitly, distinguishing packages that are load-bearing from packages that install as dependencies but never activate (e.g. `xdg-desktop-portal-kde`, pulled in by `plasma-integration` but inert — the actual active portal backend is `xdg-desktop-portal-gtk`).
- **Explicit control over defaults.** Where a tool ships a default behavior that would obscure a decision (Qt platform theme selection, portal backend selection, autostart-vs-systemd-unit placement for background daemons), the relevant component's README records which option is actually active and why, rather than leaving it to be rediscovered by inspection later.
- **Low-friction maintenance, scoped honestly.** Components with independent upstream history (their own Git repositories) are tracked as Git submodules against their own remotes — this is now the default for nearly every top-level directory. The handful without a remote yet (`imperator-vscode-theme/`, `impr-obsidian/`, `spicetify/`, `swaylock/`, `limine/`) are intentionally left as plain, untracked directories on disk — present and functional, but not yet folded into version control.

## Architecture

The environment is layered as follows:

1. **Compositor layer (`niri/`).** Niri owns window management, workspace layout, input handling, output configuration, and keybindings. It has no built-in theming, status bar, launcher, or notification daemon — all of that is delegated to independent processes, either spawned as `autostart.kdl` child processes or run as `systemd --user` units.
2. **Session daemon layer (`systemd-user/`).** Background services that must survive compositor restarts, or that have their own lifecycle needs (a startup delay, restart-on-failure), are defined as user systemd units rather than Niri autostart entries. This is a codified rule in the repository, not an ad hoc choice: `wlsunset.service` is the reference example, using `ExecStartPre=/bin/sleep 3` to avoid a startup race against the compositor.
3. **Shell/user environment layer (`zsh/`).** Interactive shell configuration (Oh My Zsh, prompt, aliases, fuzzy-finder integration) sits outside the compositor entirely and is reproducible independently of the graphical session.
4. **Toolkit theming layer (`theme/`).** GTK2/3/4, Qt5 (via `Trolltech.conf`), Qt6 (via `qt6ct`, kept as a dormant fallback since `QT_QPA_PLATFORMTHEME=kde` is the actually active theme engine through `plasma-integration`), icon theme (inheriting Breeze Dark with only `places/*` overridden), and `xsettingsd` for X11/XWayland GTK propagation. This layer is what the KDE Frameworks daemons in the philosophy section actually bridge into a running session.
5. **Application/service integration layer.** Per-application configuration for terminal (`kitty`), status bar (`waybar`/Spicebar), launcher (`fuzzel`), notifications (`swaync`), session/power menu (`wlogout`), lock screen (`swaylock`), file manager (`yazi`), editor (`nvim`), and various CLI tools (`bat`, `broot`, `btop`, `cava`, `fastfetch`, `newsboat`, `starship`). Each is self-contained and independently deployable.
6. **Pre-session layer (`sddm/`, `limine/`).** Login screen and boot loader theming, both of which render before any user session or compositor exists and therefore cannot depend on the runtime theming layer above — each carries its own standalone palette definition.
7. **Automation/helper scripts.** Distributed alongside the components they serve rather than centralized (e.g. `niri/scripts/`, `swaylock`'s Cairo-based wallpaper generator, `limine/limine-preview.sh`'s QEMU test harness) — each script is scoped to the one component it supports.

## Repository Layout

The repository is organized **by application/domain**, one top-level directory per tool, mirroring the tool's own config-directory name (`niri/`, `kitty/`, `waybar/`, and so on map directly to their respective config paths). This is a deliberate choice over organizing by function or by file type: it keeps every file relevant to one tool in one place, so deploying, auditing, or removing a single component never requires cross-referencing unrelated directories.

Twenty directories are Git submodules rather than plain directories — `bat/`, `broot/`, `btop/`, `cava/`, `fastfetch/`, `fuzzel/`, `kitty/`, `konsole/`, `newsboat/`, `niri/`, `nvim/`, `satty/`, `sddm/`, `starship/`, `swaync/`, `systemd-user/`, `theme/`, `waybar/`, `wlogout/`, `yazi/` — because each has its own independent upstream Git history and its own GitHub remote (see `.gitmodules` for the full path-to-remote mapping). Only `imperator-vscode-theme/`, `impr-obsidian/`, `spicetify/`, `swaylock/`, and `limine/` remain plain, untracked directories: they exist on disk and are fully functional, but have no GitHub remote yet. Treat any component without its own remote as "on-disk, pending" rather than assuming parity with the submodules.

`assets/` holds repository-wide, non-executable reference material (the palette specification, the project icon) that no single component owns exclusively. A root-level `limine-preview.sh` duplicates the one inside `limine/` — the copy inside `limine/` is authoritative since it sits next to the config it previews.

## Core Components

| Domain | Directory | Controls |
|---|---|---|
| Compositor | `niri/` (submodule) | Window management, workspace layout, input, outputs, keybinds, autostart chain |
| Session daemons | `systemd-user/` (submodule) | Background services requiring systemd lifecycle semantics (currently: night-light via `wlsunset`) |
| Shell | `zsh/` (submodule) | Interactive shell, prompt integration, aliases, fuzzy-finder theming |
| Toolkit theming | `theme/` (submodule) | GTK2/3/4, Qt5/Qt6, icon theme, `xsettingsd`, environment variables for toolkit-wide consistency |
| Terminal | `kitty/` (submodule) | Terminal emulator palette and behavior |
| Status bar | `waybar/` (submodule, "Spicebar") | Workspace indicators, Pomodoro timer, MPRIS, calendar pipeline (vdirsyncer → calcurse) |
| File manager | `yazi/` (submodule) | Keybindings, MIME/glob open rules, plugin lockfile |
| Launcher | `fuzzel/` (submodule) | Application launcher appearance and match behavior |
| Notifications | `swaync/` (submodule) | Notification center layout, severity-based styling, MPRIS widget |
| Session menu | `wlogout/` (submodule) | Power/session action menu |
| Lock screen | `swaylock/` (plain, no remote yet) | Lock indicator plus a generated background/clock overlay |
| Editor | `nvim/` (submodule) | Neovim configuration, including the `imperator` colorscheme engine and LSP/lint/format stack |
| Terminal apps | `bat/`, `broot/`, `btop/`, `cava/`, `fastfetch/`, `newsboat/`, `starship/` (all submodules) | Pager, tree navigator, resource monitor, audio visualizer, system-info banner, RSS reader, shell prompt |
| Alternate terminal | `konsole/` (submodule) | Fallback/alternate terminal profile, deployed to a non-standard path (`~/.local/share/konsole/`) |
| Editor/app themes outside the shell | `imperator-vscode-theme/`, `impr-obsidian/`, `spicetify/` (plain, no remote yet) | VS Code extension, Obsidian theme, Spotify client theme |
| Pre-session | `sddm/` (submodule), `limine/` (plain, no remote yet) | Login screen theme, boot loader theme |
| Reference | `assets/` | Palette specification, project icon |

## Workflow

- **Bootstrap.** There is no single top-level install script; each component documents its own deployment in its `README.md` (and, for `zsh/`, a dedicated `REINSTALL.md` covering shell/plugin/tool bootstrap from a bare distro install). The general pattern is: install the tool, then symlink the repository's directory (or the specific file) to the tool's expected config path. `sddm/` is the one exception requiring a privileged `install.sh`, since its target paths (`/usr/share/sddm/themes/`, `/etc/sddm.conf.d/`) are outside the user's home and cannot be user-space symlinked.
- **Update strategy.** For symlinked components, editing the live config *is* editing the repository — no separate sync step exists or is needed. For submodule components, updates happen independently in each submodule's own repository and are pulled into this repository as a pointer bump (`git submodule update --remote`, or a manual pull inside the submodule followed by committing the updated gitlink in the parent repository).
- **Customization model.** Each component's `README.md` has a "Customization" section identifying the specific file and variable to change for common adjustments (palette values, keybindings, layout parameters) — consult the component's own README before editing rather than searching by convention.
- **Expected intervention points.** Machine-specific values (absolute paths, hardware-dependent settings) are called out as Notes in the relevant component's README rather than parameterized — see Limitations below.

## Dependencies and Assumptions

- **Distribution:** Arch Linux or CachyOS (Arch-based). Package names and paths throughout the repository's documentation assume `pacman`.
- **Compositor:** Niri, a Wayland-only scrollable-tiling compositor. XWayland application support depends on `xwayland-satellite`, started from `niri/autostart.kdl`.
- **Toolkit bridge:** A minimal KDE Frameworks stack (`plasma-integration`, `kde-gtk-config`, `kded`/`kded6`, `plasma-kactivitymanagerd`) is required for GTK applications to pick up the theme without running Plasma Shell — see `theme/kde-minimal-deps.md` for the exact package boundary and a post-install verification checklist.
- **Portal backend:** `xdg-desktop-portal` + `xdg-desktop-portal-gtk` (not `-kde`, despite it being present as a transitive dependency).
- **Secrets/keyring:** `gnome-keyring`, not `kwalletmanager`.
- **Fonts/icons:** Nerd Font variants are assumed wherever glyph icons appear (status bar, launcher, terminal prompt). The icon theme inherits Breeze Dark rather than shipping a full icon set.
- **Per-component runtime dependencies** (the fuzzy-finder/navigation stack `eza`/`bat`/`zoxide`/`fzf`/`broot`, the calendar pipeline `vdirsyncer`+`calcurse`, `wlsunset`, `mtools`/`qemu-system-x86_64`/OVMF for the boot-theme preview harness, etc.) are documented per-component rather than centralized, since no two components share the same dependency surface.
- The environment assumes a single-user desktop machine, not a multi-user or server deployment target.

## Performance Considerations

- The daemon set is deliberately minimized: no Plasma Shell, no KWin, no GNOME Shell — only the specific KDE Frameworks processes needed for GTK theme propagation are kept resident, reducing background process count and idle memory versus running a full desktop environment underneath the compositor.
- Background services with their own lifecycle needs are systemd user units (with dependency ordering and restart semantics), not `autostart.kdl` child processes, avoiding compositor-restart-induced daemon loss and busy-loop or race-prone startup ordering.
- Boot- and login-stage theming (`limine/`, `sddm/`) render once per boot/login cycle; their rendering cost is bounded to that window and has no bearing on runtime desktop performance.
- Shell startup cost (`zsh/`) is a one-time parse/eval of static variable and alias definitions per new shell, not a per-command cost; history size is explicitly bounded rather than left to grow unbounded.
- Where a tool's own theming mechanism can be used instead of a compositor-level effect (e.g. compositor-delegated blur hints in `kitty/`, CSS-driven severity styling in `swaync/`), that mechanism is preferred over introducing an additional compositing pass.

## Customization Strategy

- **Change the palette at the source, then propagate by hand.** `assets/Imperator-palette_1.md` is the canonical palette reference. Because each tool consumes color in its own format (ANSI escape tables, GTK CSS, Qt palette files, JSON-embedded hex strings), there is no single file that regenerates every component's theme — a palette change must be applied to each consuming component's own color definition, using the source-of-truth document as the reference values.
- **Respect the submodule boundary.** Do not edit a submodule directory (see `.gitmodules` for the full list) expecting the change to be captured by a commit in this repository alone — those directories are independent Git repositories; a change must be committed and pushed inside the submodule itself, and the resulting pointer bump committed separately in this repository.
- **Prefer the systemd-vs-autostart rule when adding a new background service.** If it needs to survive compositor restarts or has startup-ordering requirements, add a `systemd-user/` unit; if it is a one-shot child process the compositor should own, add it to `niri/autostart.kdl`.
- **Do not fold an untracked component into Git without confirming intent first.** The current scope (only components with their own upstream remote are tracked as submodules) is deliberate; adding a directory to this repository's own history is a scope change, not a mechanical action.
- **Read the component's own README before modifying it.** Every component's "Notes" section records known sharp edges (hardcoded absolute paths, machine-specific values, upstream-inherited files not meant to be edited directly) that are not obvious from the configuration file alone.

## Intended Audience

Advanced Linux users running Arch or an Arch derivative with a Wayland compositor, specifically Niri, who want a fully reproducible, symlink-based configuration rather than a copy-paste dotfiles collection. Familiarity with Git submodules, systemd user units, and manual toolkit theming (GTK/Qt without a full desktop environment) is assumed throughout; no component's documentation explains these mechanisms from first principles.

## Limitations

- **Not distribution-portable.** Package names, service names, and the KDE Frameworks dependency chain in `theme/kde-minimal-deps.md` are Arch/CachyOS-specific; adapting to another distribution requires re-deriving equivalent package names.
- **Not compositor-portable.** The compositor-specific pieces (`niri/`, session-action bindings inside `wlogout/`, autostart ordering) assume Niri specifically; the theming layer (`theme/`, per-application configs) is more portable to other Wayland compositors, but window-management behavior is not.
- **Hardcoded, machine-specific absolute paths exist in several components** (documented per-component in each README's Notes section — e.g. wallpaper paths, a hardcoded editor path in `yazi/`, font/logo paths in `fastfetch/`) and must be updated manually on a new machine rather than being auto-detected.
- **No centralized secrets or machine-local override file at the repository level.** `zsh/` has its own `local.zsh` escape hatch for per-machine shell differences; no equivalent mechanism exists for other components — per-machine deviations elsewhere must be tracked manually or kept out of the repository entirely.
- **Version control coverage is nearly complete, but not total.** Twenty components are tracked as Git submodules (see `.gitmodules`); only `imperator-vscode-theme/`, `impr-obsidian/`, `spicetify/`, `swaylock/`, and `limine/` remain present on disk and deployed, but not yet committed here (no GitHub remote exists for them yet). Do not assume `git log` on this repository reflects the history of the full desktop configuration.

## Notes

- The project name and palette are a deliberate aesthetic choice (House Corrino, from Dune) applied uniformly across every themed surface — see `assets/Imperator-palette_1.md` for the full color reference and the design rationale behind specific choices (e.g. an off-black background rather than pure `#000000`, a single reserved cold accent color).
- Several components are adapted from third-party upstream work with their own licenses, preserved in place rather than rewritten: the Neovim colorscheme structure (from `cybr-nvim`, GPL-3.0) and the SDDM theme (from `glyph-sddm`, MIT). Both are noted in their respective component READMEs; only the palette and typography values were changed to match Imperator.
- A prior iteration of this environment used Hyprland with `rofi`, `hyprlock`, and `swww`; those have been fully superseded by Niri, `fuzzel`, and `swaylock` respectively and are not present in this repository.
- `theme/kde-minimal-deps.md` exists specifically to prevent a future reinstall from defaulting to the full `plasma-desktop`/`plasma-workspace` package groups — it documents the exact minimal daemon set this environment actually depends on, verified against live system state rather than assumed from package metadata.
