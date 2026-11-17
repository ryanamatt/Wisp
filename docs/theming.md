# Theming

A quick, informal rundown of how theming works in Wisp and what each color in `colors.json` is for.

## How it works

Wisp reads a file called `json` file for its colors. You may pass your colors file
using the `-C` flag in the CLI. Wisp watches this file and automatically updates
based on your colors.

Normally Wisp looks for colors in `~/.config/wisp/colors.json`. If no file present
it defaults into its base colors. You may choose to have Matugen write your colors
and if you do I would recommend checking out [Wisp Matugen Template](wisp-colors-matugen-template.json) as a reference template.

## What each color does

Quick note: "used for" below is based on how the colors are used in the QML today. Treat it as intent, not a hard rule.

### Backgrounds and surfaces

| Key | Used for |
|---|---|
| `background` | The base color of big windows and panels (theme switcher window, lock screen backdrop) |
| `backgroundAlt` | A slightly different base for areas that sit next to `background` |
| `surface` | Cards and containers that sit on top of `background` |
| `surfaceAlt` | Secondary surfaces, also used for dimming the screen behind popups |
| `surfaceElevated` | Things that float above everything else, like tooltips, hover cards and the zoom controls |
| `surfaceInput` | Text fields, the graph plot area, and the frosted glass look on the lock screen |
| `surfaceOverlay` | Overlay panels |

### Text

| Key | Used for |
|---|---|
| `foreground` | Main text and icons |
| `foregroundMuted` | Secondary text, hints, helper lines |
| `foregroundSubtle` | Quiet text like subtitles and placeholders |
| `foregroundDisabled` | Text and icons on things that are turned off |
| `onAccent` | Text or icons sitting on top of an `accent` colored fill, so it stays readable |

### Accents

| Key | Used for |
|---|---|
| `accent` | The main highlight: focused items, important icons, active states |
| `accentAlt` | A second accent for variety (battery icon on the lock screen, for example) |
| `link` | Link-style text |

### Borders

| Key | Used for |
|---|---|
| `border` | Default outline on panels, cards and popups |
| `borderSoft` | A quieter outline for unfocused or low-emphasis things (unfocused wallpaper cards) |
| `borderActive` | Outline for the thing you're interacting with (the focused password box) |
| `borderStrong` | A more visible outline when `border` is too faint |
| `focusRing` | Keyboard focus indicator |

### Interaction states

| Key | Used for |
|---|---|
| `hover` | Background when the mouse is over something |
| `pressed` | Background while something is being clicked |
| `selected` | Selected items, and text selection highlight in inputs |
| `focused` | Background of the item that has keyboard focus |
| `disabled` | Fill for things that are turned off |
| `scrim` | The dark layer behind modal things. Usually black, with transparency applied by whatever uses it |

### Status

| Key | Used for |
|---|---|
| `success` | Good state: charging, "cool" CPU temp |
| `warning` | Heads up: "medium" CPU temp |
| `error` | Bad state: wrong password, low battery, "warm" CPU temp |
| `info` | Neutral information |
| `neutral` | Status that is neither good nor bad |

The system monitor widget is a handy example. It picks `success` under 70°C, `warning` under 90°C, and `error` above that.

### Named hues

`purple`, `blue`, `cyan`, `teal`, `green`, `lime`, `yellow`, `orange`, `red`, `pink`, `magenta`, `indigo`

These are general purpose colors for when something just needs to be a specific hue and not tied to a meaning (think categories, charts, or terminal-style palettes). Matugen usually tunes these so they match the rest of the theme.

### Shadow

| Key | Used for |
|---|---|
| `shadow` | Drop shadow color |

Heads up: `shadow` is the odd one out. It's written as `#AARRGGBB` (alpha first), which is how Qt reads 8 digit hex colors, not the `#RRGGBBAA` you might expect from CSS. In the fallback, `#4078d1ff` is the accent blue `#78d1ff` at 25% opacity.

## Minimal custom file

You don't need every key. This is a perfectly valid `colors.json`:

```json
{
  "background": "#1e1e2e",
  "foreground": "#cdd6f4",
  "accent": "#89b4fa"
}
```

Everything else falls back to the built-in palette. It looks best, though, if you set related colors together (for example `accent` and `onAccent`, or `background` and the `surface` family), so text stays readable.
