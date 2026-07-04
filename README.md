# IMPERATOR

> *"The first step in avoiding a trap is knowing it exists."*
> — Thufir Hawat, Mentat of House Atreides

A desktop theme inspired by a personal interpretation of **House Corrino** from the Dune universe. Not its ostentation — its silent oppression. Ten thousand years of imperial power, Mentat records burning on amber monitors, the filtered light of Arrakis pressing through sandstone walls.

The palette does not imitate the Golden Lion Throne's splendor.  
It imitates the **Sardaukar terminal before the assault**.

---

## Design Philosophy

The amber CRT monitor was the screen of the cold war — bunkers, command centers, the terminals where the fate of planets was decided. In the Corrino universe, that same phosphor tone illuminates the cells of Salusa Secundus, the CHOAM ledgers, the troop movement maps of the Padishah Emperor's strategists.

**Four rules:**

1. **Organic black, not digital.** The background is not `#000000`. It is `#0E0C08` — black with soot pigment, like the basalt of Giedi Prime.
2. **No neon.** Maximum saturation is reserved for pure gold `#FFD700`, exclusively for user-defined functions — what the Mentat considers most valuable.
3. **Hierarchy through luminance.** The most important elements shine brightest. The subordinate recedes into muted amber.
4. **One cold accent.** Purple `#9870A0` — the color of decorators, annotations, what code *describes* but is not. Unique in the entire palette.

---

## Palette

```
BACKGROUNDS   #0E0C08  #141008  #1A1408  #241C0C  #1E1808
TEXT          #3A2E10  #5E4E28  #766035  #8A7040  #B8860B  #D4A843
AMBER         #A07820  #AA9050  #B09030  #C8960C  #F0B030  #D48840  #FFD700
CONTRAST      #8DB8A0  #72C8B4  #9870A0  #5B8DA8
ERROR         #FF6B2B
```

Full reference: [`Imperator-palette.md`](./assets/Imperator-palette.md)

---

## Components

| Component | Description |
|---|---|
| [`nvim/`](./nvim/) | Neovim colorscheme — syntax, LSP, plugins |
| [`kitty/`](./kitty/) | Terminal palette — 16 ANSI colors remapped to amber (git submodule: [Impr-Kitty](https://github.com/lordziegler/Impr-Kitty)) |
| [`konsole/`](./konsole/) | Konsole profile + colorscheme (deployed to `~/.local/share/konsole/`, not `~/.config/`) |
| [`waybar/`](./waybar/) | **Spicebar** — Wayland status bar with Pomodoro, planetary workspaces, MPRIS, calendar (calcurse+vdirsyncer pipeline) (git submodule: [Spicebar](https://github.com/lordziegler/Spicebar)) |
| [`fuzzel/`](./fuzzel/) | Application launcher |
| [`niri/`](./niri/) | Wayland compositor — config, binds, autostart, scripts |
| [`swaync/`](./swaync/) | Notification center |
| [`wlogout/`](./wlogout/) | Power/session menu |
| [`swaylock/`](./swaylock/) | Lock screen |
| [`theme/`](./theme/) | GTK2/3/4 theme + icon theme + qt6ct + Trolltech.conf (Qt5) + xsettingsd + environment.d — the actual live theming source of truth |
| [`systemd-user/`](./systemd-user/) | User-authored systemd units (night light via wlsunset) |
| [`newsboat/`](./newsboat/) | RSS reader config + feed list |
| [`starship/`](./starship/) | Shell prompt |
| [`spicetify/`](./spicetify/) | Spotify client theme |
| [`fastfetch/`](./fastfetch/) | System info display |
| [`btop/`](./btop/) | Resource monitor |
| [`yazi/`](./yazi/) | Terminal file manager (git submodule: [impr-yazi](https://github.com/lordziegler/impr-yazi)) |
| [`impr-obsidian/`](./impr-obsidian/) | Obsidian theme |
| [`imperator-vscode-theme/`](./imperator-vscode-theme/) | VS Code extension |
| [`sddm/`](./sddm/) | SDDM login screen theme (`glyph`) |
| [`limine/`](./limine/) | Bootloader theme |

Not part of the current stack (Hyprland-era, superseded by the Niri setup above — kept out of this table to avoid confusion): `rofi` → replaced by `fuzzel`; `hyprlock` → replaced by `swaylock`; `swww` → replaced by `awww`; `omz` → replaced by plain zsh config; `calcurse` → (calendar pipeline is vdirsyncer → calcurse only).

---

## Installation

Each component is self-contained. Copy or symlink the directory you need to its standard config path.

**Neovim** is the only component requiring extra steps:

```sh
# Files should already be in ~/.config/nvim/
# On first launch, lazy.nvim installs dependencies automatically
nvim
```

To apply the colorscheme manually:

```vim
:colorscheme imperator
```

---

## Credits

This project builds on the work of others. Full attribution below.

**[cybrdots](https://github.com/cybrcore/cybrdots)** by [scherrer-txt](https://github.com/cybrcore)
The Neovim theme structure (`lua/imperator/`) was derived from [cybr-nvim](https://github.com/cybrcore/cybr-nvim).
Original source licensed under GPL-3.0. All colors have been replaced with the Imperator palette.

**[glyph-sddm](https://github.com/xCaptaiN09/glyph-sddm)** by [xCaptaiN09](https://github.com/xCaptaiN09)
The SDDM login screen theme included in [`glyph-sddm/`](./glyph-sddm/) is the original work of xCaptaiN09.
Licensed under MIT. Colors adapted to the Imperator palette.

---

## License

Personal use. The palette and configuration files are free to distribute.  
House Corrino does not share its gold — but I do.
