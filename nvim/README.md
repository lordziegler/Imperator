# nvim

## Overview

Neovim configuration built on `lazy.nvim`, pairing a full LSP/completion/formatting/linting stack with a custom colorscheme (`imperator`) implemented as a local plugin under `lua/imperator/`. It is the primary editing environment for the whole ricing and the reference implementation the other app themes (kitty ANSI, bat, VS Code) are checked against for palette consistency.

## Design Philosophy

- **Config-as-code, not config-as-data.** The colorscheme is a real Lua module (`imperator.setup()` / `imperator.load()`) with a typed palette and override mechanism, not a static list of `highlight` commands — this lets other plugins query `require("imperator").colors()` instead of hardcoding hex values.
- **Load order discipline.** `vim.g.mapleader` is set, then `config.options`/`config.keymaps`, then the `lazy.nvim` bootstrap — in that exact order, because leader-key and option state must exist before any plugin spec is evaluated.
- **Minimal core, plugin-delegated behavior.** `options.lua` only sets Vim-native behavior (indentation, search, UI); nothing plugin-specific leaks into it.
- **Reproducibility over convenience.** `lazy-lock.json` pins exact plugin commits; disabled built-in Vim plugins (`gzip`, `matchit`, `netrwPlugin`, etc.) are explicitly listed rather than left to defaults, so a fresh install behaves identically to the reference machine.

## Key Features

- Full LSP stack via `mason.nvim` + `mason-lspconfig.nvim` + `nvim-lspconfig`, decoupled from manual server installation.
- `blink.cmp` completion engine with `LuaSnip` + `friendly-snippets`.
- Async formatting on `BufWritePre` (`conform.nvim`) and async linting (`nvim-lint`), both mason-installed per filetype.
- Treesitter parsers installed lazily on first `BufReadPost`, not eagerly at startup.
- `imperator` colorscheme: transparent-background mode, per-group override hook (table or function), and automatic terminal ANSI color assignment (`g.terminal_color_0..15`) so `:terminal` matches the editor palette.
- `mini.*` suite (`mini.ai`, `mini.files`, `mini.statusline`, `mini.indentscope`) chosen over heavier equivalents (nvim-tree, lualine) for lower plugin-count and startup cost.

## Configuration Breakdown

| Path | Responsibility | Why it exists |
|---|---|---|
| `init.lua` | Leader keys, core config load order, lazy.nvim bootstrap/install | Single deterministic entry point; the only file Neovim reads directly |
| `lua/config/options.lua` | Vim-native `opt.*` settings (numbers, indent, search, UI, folds, clipboard) | Kept plugin-free so it stays valid even if the plugin spec changes |
| `lua/config/keymaps.lua` | Core keymaps not owned by a specific plugin | Loaded before plugins so leader-based mappings are available immediately |
| `lua/imperator/init.lua` | Colorscheme engine: `setup()`, `load()`, config merging, override application, terminal color propagation | Separates the *mechanism* of applying a theme from the *data* of the theme |
| `lua/imperator/palette.lua` | Typed color palette (`no0..no2`, `re0..re2`, `gr0..gr2`, etc. — background/red/green/yellow/blue/violet/cyan/white/muted/orange families) | Single source of truth for every hex value used across highlight groups |
| `lua/imperator/groups.lua` | Highlight group definitions built from the palette | Kept separate from `init.lua` so adding plugin-specific highlight support doesn't bloat the engine file |
| `lua/plugins/*.lua` | One file per plugin domain (`lsp`, `completion`, `formatting`, `editing`, `git`, `navigation`, `treesitter`, `ui`, `dashboard`, `mini`, `imperator`) | `lazy.nvim`'s `{ import = "plugins" }` spec auto-discovers every file here — new plugins never require touching `init.lua` |
| `colors/imperator.lua` | Thin Vim colorscheme entry point (`:colorscheme imperator`) that calls into `lua/imperator` | Required by Vim's colorscheme-loading convention (`colors/<name>.lua`) |
| `lazy-lock.json` | Exact commit pins for every plugin | Reproducible installs — `lazy.nvim` will not silently update past these on a fresh clone |

## Dependencies

- Neovim **0.10+**
- `git` — plugin cloning
- `tree-sitter-cli` — required for `nvim-treesitter` to compile grammars (the `tree-sitter` package alone only ships the shared library)
- `lazygit` — used by `snacks.nvim`'s git integration
- A Nerd Font (e.g. `ttf-jetbrains-mono-nerd`) — statusline/dashboard/diagnostic glyphs
- Mason-installed, not pacman-installed: `lua_ls`, `pyright`, `bashls`, `jsonls`, `yamlls` (LSP); `stylua`, `ruff_format`/`black`, `shfmt`, `prettier`, `taplo` (formatters); `ruff`, `shellcheck`, `luacheck` (linters)

## Usage

Deployed as the Neovim config directory. On first launch, `lazy.nvim` bootstraps itself by cloning into `stdpath("data")/lazy/lazy.nvim` and then installs every plugin declared under `lua/plugins/`. Treesitter parsers install automatically the first time a matching filetype is opened; LSP/formatter/linter binaries must be installed once via `:Mason` / `:MasonInstall <name>`.

## Customization

- **Palette**: edit `lua/imperator/palette.lua` — every highlight group derives from it, so a single-file edit re-themes the whole editor.
- **Highlight overrides**: pass a table or function to `imperator.setup({ overrides = ... })` instead of editing `groups.lua` directly, to survive upstream changes to the base groups.
- **Plugins**: add a new file under `lua/plugins/` (or extend an existing domain file) — no registration step needed beyond that.
- **Core editor behavior**: `lua/config/options.lua` for Vim options, `lua/config/keymaps.lua` for non-plugin keymaps.

## Performance Considerations

- Built-in plugins with no use in this config (`gzip`, `matchit`, `matchparen`, `netrwPlugin`, `tarPlugin`, `tohtml`, `tutor`, `zipPlugin`) are explicitly disabled via `lazy.nvim`'s `performance.rtp.disabled_plugins`, trimming startup runtimepath scanning.
- Treesitter parsers are installed lazily (on first matching buffer) rather than all at once, avoiding an install burst on first launch.
- `checker = { enabled = false }` disables `lazy.nvim`'s background update-checker, removing a periodic network/IO check that has no effect on editing performance but does consume a timer.
- `foldenable = false` with `foldlevel = 99` keeps treesitter fold *computation* available on demand without forcing folds closed (and their associated redraw cost) by default.

## Notes

- `lua/plugins/treesitter.lua.bak` is a stray backup file committed alongside the active `treesitter.lua` — it is inert (not sourced by `lazy.nvim`, since the import glob only picks up files that return a valid spec table when required, and `.bak` files are not `.lua`) but should not be treated as an alternate config to switch to without diffing it first.
- `opt.clipboard = "unnamedplus"` requires `wl-clipboard` (Wayland) or `xclip`/`xsel` (X11) to be installed system-wide, or yank/paste to the system clipboard silently no-ops.
- The colorscheme's transparent-background mode (`transparent_bg`) only strips `bg` from a fixed list of groups (`Normal`, `SignColumn`, `NvimTreeNormal`, etc.) — adding a new UI plugin that draws its own background will need its group added to that list manually.
