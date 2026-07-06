# swaync

## Overview

Configuration for [SwayNotificationCenter](https://github.com/ErikReider/SwayNotificationCenter) (swaync), the notification daemon and do-not-disturb/notification-center panel used across the session. It is spawned at niri startup and exposes both floating toast notifications and a control-center panel (opened from waybar's `custom/swaync` module).

## Design Philosophy

- **GTK theme override, not inheritance.** `"ignore-gtk-theme": true` is set explicitly so swaync's appearance is driven entirely by `style.css`, decoupling it from whatever GTK theme is active system-wide — the notification center should look identical regardless of GTK theme drift elsewhere.
- **Layer-shell-native, not a floating window.** `"layer-shell": true` with `"layer-shell-cover-screen": true` and margin control places swaync as a proper Wayland layer-shell surface rather than a regular toplevel window niri would have to apply window-rules to.
- **Semantic color variables over repeated hex.** `style.css` defines a full `@define-color` palette (`bg0..bg3`, `am0..am4`, `gr0`, `bl0`, `er0`, `glass`/`glass2`) once and every selector below references these names — a palette change is a one-block edit, not a find-and-replace across the file.
- **Rectangular, glass-panel aesthetic.** `--radius: 0px` and translucent `glass`/`glass2` background colors (`rgba(14, 12, 8, 0.90/0.92)`) match the CRT/frosted-glass language used across the rest of the ricing (kitty, waybar).

## Key Features

- Fixed-position control center (bottom-right, `500×600`), with independent floating-notification width (`500`) and no auto-repositioning.
- MPRIS widget with always-visible album art, blurred/darkened background layer behind the overlay, and carousel navigation between multiple active players.
- Severity-differentiated notification styling: `normal` (amber border/text), `low` (Phosphor Green, translucent background), `critical` (solid Plasma Red background, dark text for contrast).
- `"hide-on-clear": true` / `"hide-on-action": true` — the panel dismisses itself after the user acts, rather than staying open awaiting manual close.
- Built-in noise reduction: `"timeout-critical": 0` (critical notifications never auto-dismiss) versus `"timeout": 5` / `"timeout-low": 5` for normal/low severities.

## Configuration Breakdown

| File / section | Responsibility | Why it exists |
|---|---|---|
| `config.json` → top-level keys | Panel position/layer, timeouts, transition timing, keyboard shortcuts, control-center dimensions | Behavioral configuration read once at daemon start |
| `config.json` → `"widgets"` / `"widget-config"` | Declares which widgets appear (`title`, `dnd`, `notifications`, `mpris`) and per-widget options (album-art visibility, carousel looping, clear-all button text) | swaync's widget system is opt-in — a widget not listed here simply does not render, keeping the panel to only what's used |
| `style.css` → `:root` variables + `@define-color` block | Central palette and spacing constants | Single edit point for re-theming; every rule below consumes these instead of literal colors |
| `style.css` → `.widget-mpris*` rules | Media player card styling — album art sizing, blurred background layer, carousel dots, transport button hover states | Isolated because MPRIS is the most visually complex widget (nested overlay + background blur) |
| `style.css` → `.control-center*` / `.floating-notifications*` | Panel chrome and per-severity (`normal`/`low`/`critical`) notification card styling | Two distinct surfaces (persistent panel vs. transient toasts) sharing the same palette but different layout rules |
| `style.css` → `button`, `.close-button`, `scrollbar` | Interactive element states (hover/focus/active) | Kept generic/global since these patterns repeat across every widget |

## Dependencies

- `swaync` (SwayNotificationCenter) ≥ 0.12 — the `--mpris-*` CSS custom properties used here are read directly by swaync 0.12.6's MPRIS widget
- `swaync-client` — used by waybar's `custom/swaync` module to query state and toggle the panel
- A layer-shell-capable compositor (niri) — required for `"layer-shell": true` to have any effect
- `GeistMono Nerd Font` — the font family set in the global `*` selector

## Usage

Started at session launch via niri's `spawn-at-startup "swaync"`; runs as a persistent background daemon for the rest of the session, receiving notifications over its D-Bus interface and rendering both toast popups and the control-center panel on demand.

## Customization

- **Palette**: edit the `@define-color` values at the top of `style.css` — do not add new literal hex colors elsewhere in the file.
- **Widgets shown**: `"widgets"` array in `config.json` — remove or reorder entries; each requires its corresponding block under `"widget-config"` if it needs non-default options.
- **Timeouts**: `"timeout"`, `"timeout-low"`, `"timeout-critical"` in `config.json` (seconds; `0` means "never auto-dismiss").
- **Panel size/position**: `"positionX"`/`"positionY"`, `"control-center-width"`/`"-height"`, `"notification-window-width"`.

## Performance Considerations

- The MPRIS album-art background blur (`filter: blur(7px) grayscale(0.9) brightness(0.25)`) is a GTK/GSK compositing cost paid only while a player is active and the panel/toast is visible — it does not run when no MPRIS session exists.
- `"transition-time": 200` (ms) bounds how long show/hide animations run; shorter values reduce perceived latency at the cost of abruptness.
- Fixed panel dimensions (`control-center-width`/`-height`) avoid layout-reflow cost from dynamic resizing based on content.

## Notes

- `"ignore-gtk-theme": true` means changes to the system GTK theme (via `theme/gtk-config/`) will **not** propagate to swaync automatically — any palette change intended to reach swaync must be applied to `style.css` directly.
- The `--mpris-*` CSS custom properties are swaync-version-specific (documented here as tested against 0.12.6); if upgrading swaync causes MPRIS styling to silently stop applying, check whether the variable names changed upstream.
- Critical notifications never auto-dismiss (`"timeout-critical": 0`) — this is intentional (errors should require acknowledgment) but means a script emitting spurious critical-urgency notifications will visibly stack up rather than fade away.
