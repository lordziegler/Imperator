# Imperator — Universal Color Palette

Warm dark theme inspired by amber CRT screens and the austere aesthetic of the Dune universe.
Organic black background, soft gold text, full syntax hierarchy for Python, R and Quarto.

---

## Design Principles

- **Compact, coherent palette**: all colors belong to one of four families — gold/amber, sage green, indigo/steel, purple. No arbitrary chromatic dispersion.
- **Hierarchy by luminance and temperature**: token visual importance is communicated by brightness; its *type* is communicated by color temperature (gold → orange → amber → green → purple).
- **No neon**: maximum saturation is reserved for `#FFD700` (functions) and `#FF6B2B` (errors). The rest of the palette is moderate.
- **Legible inactive states**: unfocused elements use lowered colors but never below roughly 4:1 contrast against the background.
- **Semantic separation over decoration**: colors differentiate *what a token is* before communicating *how important* it is.

---

## Palette Spectrum

```
dark ◄─────────────────────────────────────────────────────► bright

BACKGROUNDS    #0E0C08  #141008  #1A1408  #241C0C  #1E1808
               Deep    DkEmber  Raised   Hover    Active

TEXT          #3A2E10  #5E4E28  #766035  #8A7040  #B8860B  #D4A843
               Dim     LineNum Comment  Subtle   Muted    Base

AMBER         #A07820  #AA9050  #B09030  #C8960C  #F0B030  #D48840  #FFD700
               Tertiary Keyword  Operator Type     Warm     Number   Primary

CONTRAST      #8DB8A0  #72C8B4  #9870A0  #5B8DA8
               String   Math   Special   Info
```

---

## Semantic roles — UI

| Role                 | Name             | HEX       | RGB               |
|----------------------|------------------|-----------|-------------------|
| Background           | Deep Void        | `#0E0C08` | 14, 12, 8         |
| Background Alt       | Dark Ember       | `#141008` | 20, 16, 8         |
| Background Raised    | Warm Shadow      | `#1A1408` | 26, 20, 8         |
| Background Hover     | Amber Dust       | `#241C0C` | 36, 28, 12        |
| Background Active    | Ember Glow       | `#1E1808` | 30, 24, 8         |
| Foreground           | Amber Light      | `#D4A843` | 212, 168, 67      |
| Foreground Muted     | Old Gold         | `#B8860B` | 184, 134, 11      |
| Foreground Subtle    | Tarnished Signal | `#8A7040` | 138, 112, 64      |
| Foreground Comment   | Ash Ember        | `#766035` | 118, 96, 53       |
| Foreground Dim       | Scorched         | `#3A2E10` | 58, 46, 16        |
| Line Number          | Ember Dust       | `#5E4E28` | 94, 78, 40        |
| Accent Primary       | Golden Signal    | `#FFD700` | 255, 215, 0       |
| Accent Secondary     | Amber Pulse      | `#C8960C` | 200, 150, 12      |
| Accent Tertiary      | Warm Ochre       | `#A07820` | 160, 120, 32      |
| Accent Warm          | Solar Flare      | `#F0B030` | 240, 176, 48      |
| String / Safe        | Phosphor Green   | `#8DB8A0` | 141, 184, 160     |
| Error / Danger       | Plasma Red       | `#FF6B2B` | 255, 107, 43      |
| Warning              | Caution Amber    | `#C8960C` | 200, 150, 12      |
| Success / Added      | Radar Green      | `#8DB87A` | 141, 184, 122     |
| Info / Link          | Signal Blue      | `#5B8DA8` | 91, 141, 168      |
| Debug / Special      | Violet Static    | `#9870A0` | 152, 112, 160     |
| Border               | Ember Border     | `#2A2010` | 42, 32, 16        |

---

## Semantic roles — Syntax (editors)

Token hierarchy for Python, R and Quarto. Order reflects descending visual prominence.

| Token                      | Name            | HEX       | Notes                                   |
|----------------------------|-----------------|-----------|-----------------------------------------|
| Function (definition)      | Golden Signal   | `#FFD700` | Maximum prominence; the "star token"    |
| Function (stdlib)          | Amber Pulse     | `#C8960C` | Same family as types, lower brightness  |
| Method, Enum               | Solar Flare     | `#F0B030` | Callable subcategory, italic optional    |
| Type, Class, Struct        | Amber Pulse     | `#C8960C` | Grouped type identities                 |
| Number, Constant literal   | Numeral Filament| `#D48840` | Orange-amber; hue distinct from gold    |
| Function parameter         | Pale Signal     | `#D4B070` | Pale amber, italic; subordinate         |
| Base text, Variable        | Amber Light     | `#D4A843` | Semantic background of code             |
| Property                   | Warm Brass      | `#B89050` | Between muted and base                  |
| Keyword, Storage           | Directive Amber | `#AA9050` | Control flow visible without dominating |
| Operator                   | Operator Amber  | `#B09030` | Slightly darker than keyword            |
| String, Regexp             | Phosphor Green  | `#8DB8A0` | Contrast by hue (green vs amber)        |
| Math inline `$...$`        | Cathode Teal    | `#72C8B4` | Clear perceptual contrast vs strings    |
| Variable in math LaTeX     | Pale Signal     | `#D4B070` | Italic; distinguishable inside math     |
| Comment                    | Ash Ember       | `#766035` | Legible (~5.5:1) without competing      |
| Decorator, Annotation      | Violet Static   | `#9870A0` | The only cool accent; unique in hue     |
| Namespace, Module          | Warm Ochre      | `#A07820` | Subordinate to types                    |
| Math delimiter `$` `$$`    | Golden Signal   | `#FFD700` | Marks math block start/end              |

---

## Semantic separation by hue family

```
Pure gold  #FFD700  → user-defined functions
Warm amber → types (#C8960C), methods (#F0B030), text (#D4A843)
Orange-amber → numbers (#D48840)  ← hue ~25°, distinct from amber ~38°
Pale amber  → parameters (#D4B070), keywords (#AA9050)
Sage green  → strings (#8DB8A0)
Teal-cyan   → LaTeX math (#72C8B4)  ← 20° Δhue vs strings
Purple      → decorators (#9870A0)  ← unique in the palette
Steel blue  → info, links (#5B8DA8)
Red-orange → errors (#FF6B2B)
```

---

## CSS Variables

```css
:root {
  /* Backgrounds */
  --crt-bg:             #0E0C08;
  --crt-bg-alt:         #141008;
  --crt-bg-raised:      #1A1408;
  --crt-bg-hover:       #241C0C;
  --crt-bg-active:      #1E1808;

  /* Foregrounds / Text */
  --crt-fg:             #D4A843;
  --crt-fg-muted:       #B8860B;
  --crt-fg-subtle:      #8A7040;
  --crt-fg-comment:     #766035;
  --crt-fg-linenum:     #5E4E28;
  --crt-fg-dim:         #3A2E10;

  /* Accents */
  --crt-accent:         #FFD700;
  --crt-accent-2:       #C8960C;
  --crt-accent-3:       #A07820;
  --crt-accent-4:       #F0B030;

  /* Syntax tokens */
  --crt-number:         #D48840;
  --crt-param:          #D4B070;
  --crt-keyword:        #AA9050;
  --crt-operator:       #B09030;
  --crt-string:         #8DB8A0;
  --crt-math:           #72C8B4;

  /* Semantic states */
  --crt-error:          #FF6B2B;
  --crt-warning:        #C8960C;
  --crt-success:        #8DB87A;
  --crt-info:           #5B8DA8;
  --crt-special:        #9870A0;

  --crt-border:         #2A2010;
}
```

---

## SCSS Variables

```scss
// Backgrounds
$crt-bg:           #0E0C08;
$crt-bg-alt:       #141008;
$crt-bg-raised:    #1A1408;
$crt-bg-hover:     #241C0C;
$crt-bg-active:    #1E1808;

// Foregrounds / Text
$crt-fg:           #D4A843;
$crt-fg-muted:     #B8860B;
$crt-fg-subtle:    #8A7040;
$crt-fg-comment:   #766035;
$crt-fg-linenum:   #5E4E28;
$crt-fg-dim:       #3A2E10;

// Accents
$crt-accent:       #FFD700;
$crt-accent-2:     #C8960C;
$crt-accent-3:     #A07820;
$crt-accent-4:     #F0B030;

// Syntax tokens
$crt-number:       #D48840;
$crt-param:        #D4B070;
$crt-keyword:      #AA9050;
$crt-operator:     #B09030;
$crt-string:       #8DB8A0;
$crt-math:         #72C8B4;

// Semantic states
$crt-error:        #FF6B2B;
$crt-warning:      #C8960C;
$crt-success:      #8DB87A;
$crt-info:         #5B8DA8;
$crt-special:      #9870A0;

$crt-border:       #2A2010;
```

---

## Hyprland (hyprland.conf)

```ini
# Imperator CRT — Hyprland colors
# Format: 0xAARRGGBB

general {
    col.active_border         = 0xFFFFD700 0xFFC8960C 45deg
    col.inactive_border       = 0xFF3A3018
    col.nogroup_border        = 0xFF3A2E10
    col.nogroup_border_active = 0xFFF0B030
}

decoration {
    col.shadow                = 0xCC0E0C08
    col.shadow_inactive       = 0x880E0C08
}

# For widgets:
# background: #0E0C08   foreground: #D4A843
# accent:     #FFD700   border:     #C8960C
# inactive:   #3A3018   subtle:     #8A7040
```

---

## Waybar (style.css)

```css
* {
    background-color: #0E0C08;
    color: #D4A843;
    border-color: #2A2010;
    font-family: monospace;
}

#workspaces button.active {
    color: #FFD700;
    border-bottom: 2px solid #FFD700;
    background-color: #1E1808;
}

#workspaces button:hover {
    background-color: #241C0C;
    color: #F0B030;
}

#workspaces button:not(.active) {
    color: #8A7040;
}

#clock, #battery, #cpu, #memory, #network {
    color: #B8860B;
    background-color: #141008;
    border: 1px solid #2A2010;
}

#battery.warning  { color: #C8960C; }
#battery.critical { color: #FF6B2B; }
```

---

## Spicetify (color.ini)

```ini
[Imperator CRT]
text                  = D4A843
subtext               = 8A7040
sidebar_and_player_bg = 0E0C08
main_bg               = 0E0C08
main_fg               = D4A843
main_bg_elevated      = 1A1408
highlight_elevated_1  = 241C0C
highlight_elevated_2  = 1E1808
button                = FFD700
button_active         = C8960C
button_disabled       = 3A2E10
tab_active            = FFD700
notification_error_bg = FF6B2B
notification_error_text = 0E0C08
misc                  = B8860B
```

---

## GTK (gtk.css)

```css
/* Imperator CRT — GTK Theme */
@define-color bg_color        #0E0C08;
@define-color bg_alt          #141008;
@define-color fg_color        #D4A843;
@define-color fg_muted        #8A7040;
@define-color selected_bg     #1E1808;
@define-color selected_fg     #FFD700;
@define-color accent          #FFD700;
@define-color accent_2        #C8960C;
@define-color border          #2A2010;
@define-color error           #FF6B2B;
@define-color warning         #C8960C;
@define-color success         #8DB87A;

window {
    background-color: @bg_color;
    color: @fg_color;
}

button {
    background-color: @bg_alt;
    color: @accent;
    border: 1px solid @border;
}

button:hover {
    background-color: @selected_bg;
    color: @accent;
    border-color: @accent_2;
}

label.dim-label {
    color: @fg_muted;
}
```

---

## Kitty / Alacritty (terminal colors)

```ini
# Imperator CRT — Terminal palette

# Base
background            #0E0C08
foreground            #D4A843
selection_background  #1E1808
selection_foreground  #FFD700
cursor                #FFD700
cursor_text_color     #0E0C08

# ANSI Colors
color0   #0E0C08   # black
color1   #C84830   # red
color2   #6D9860   # green
color3   #C8960C   # yellow
color4   #5B8DA8   # blue
color5   #9870A0   # magenta
color6   #5AADA8   # cyan
color7   #B89050   # white

# Bright ANSI Colors
color8   #4A3818   # bright black
color9   #FF8050   # bright red
color10  #8DB87A   # bright green
color11  #FFD700   # bright yellow
color12  #7AAEC8   # bright blue
color13  #C89860   # bright magenta
color14  #7ACAB0   # bright cyan
color15  #D4A843   # bright white
```

---

## Rofi (colors.rasi)

```css
* {
    bg:         #0E0C08;
    bg-alt:     #141008;
    bg-active:  #1E1808;
    fg:         #D4A843;
    fg-muted:   #8A7040;
    accent:     #FFD700;
    accent-2:   #C8960C;
    urgent:     #FF6B2B;
    border:     #2A2010;

    background-color: @bg;
    text-color:       @fg;
}

element selected.normal {
    background-color: @bg-active;
    text-color:       @accent;
}

element normal.normal {
    text-color: @fg;
}

element normal.urgent {
    text-color: @urgent;
}
```

---

## Dunst (dunstrc)

```ini
[global]
    background   = "#0E0C08"
    foreground   = "#D4A843"
    frame_color  = "#C8960C"

[urgency_low]
    background   = "#141008"
    foreground   = "#8A7040"
    frame_color  = "#3A3018"

[urgency_normal]
    background   = "#0E0C08"
    foreground   = "#D4A843"
    frame_color  = "#C8960C"

[urgency_critical]
    background   = "#1A0800"
    foreground   = "#FF6B2B"
    frame_color  = "#FF6B2B"
```

---

## Design Tokens (JSON)

```json
{
  "color": {
    "background": {
      "base":    { "value": "#0E0C08", "comment": "Deep Void" },
      "alt":     { "value": "#141008", "comment": "Dark Ember" },
      "raised":  { "value": "#1A1408", "comment": "Warm Shadow" },
      "hover":   { "value": "#241C0C", "comment": "Amber Dust" },
      "active":  { "value": "#1E1808", "comment": "Ember Glow" }
    },
    "foreground": {
      "base":    { "value": "#D4A843", "comment": "Amber Light — main text" },
      "muted":   { "value": "#B8860B", "comment": "Old Gold — secondary text" },
      "subtle":  { "value": "#8A7040", "comment": "Tarnished Signal — inactive labels" },
      "comment": { "value": "#766035", "comment": "Ash Ember — code comments" },
      "linenum": { "value": "#5E4E28", "comment": "Ember Dust — line numbers" },
      "dim":     { "value": "#3A2E10", "comment": "Scorched — decorative only" }
    },
    "accent": {
      "primary":   { "value": "#FFD700", "comment": "Golden Signal — functions, headings" },
      "secondary": { "value": "#C8960C", "comment": "Amber Pulse — types, classes, borders" },
      "tertiary":  { "value": "#A07820", "comment": "Warm Ochre — namespaces" },
      "warm":      { "value": "#F0B030", "comment": "Solar Flare — methods, enums" }
    },
    "syntax": {
      "number":    { "value": "#D48840", "comment": "Numeral Filament — numeric literals" },
      "param":     { "value": "#D4B070", "comment": "Pale Signal — function parameters" },
      "keyword":   { "value": "#AA9050", "comment": "Directive Amber — control flow" },
      "operator":  { "value": "#B09030", "comment": "Operator Amber — +/-/= etc." },
      "string":    { "value": "#8DB8A0", "comment": "Phosphor Green — string literals" },
      "math":      { "value": "#72C8B4", "comment": "Cathode Teal — LaTeX math inline" }
    },
    "semantic": {
      "error":   { "value": "#FF6B2B", "comment": "Plasma Red" },
      "warning": { "value": "#C8960C", "comment": "Caution Amber" },
      "success": { "value": "#8DB87A", "comment": "Radar Green" },
      "info":    { "value": "#5B8DA8", "comment": "Signal Blue" },
      "special": { "value": "#9870A0", "comment": "Violet Static — decorators" }
    },
    "border": { "value": "#2A2010", "comment": "Ember Border" }
  }
}
```
