# Wisp Config

This document covers every option available in `config.json`.

Wisp reads its config from `~/.config/wisp/config.json` (or `$XDG_CONFIG_HOME/wisp/config.json`), or from whatever path you pass with the `-c` flag. A missing file, missing keys, wrong types, or out-of-range values all fall back to defaults with a logged warning, so a bad config never stops Wisp from starting.

Config is read once at start, so changes only apply after a `wisp reload`. You can also edit everything from the Settings Section of the Command Center. See [features.md](features.md#settings-section).

An example with every default is in [config/config.json](config/config.json).

## Table of Contents

- [Top Level](#top-level)
- [bar](#bar)
- [weather](#weather)
- [wallpaper](#wallpaper)
- [packages](#packages)
- [battery](#battery)
- [notifications](#notifications)
- [welcome](#welcome)
- [osd](#osd)

## Top Level

### font

Default: `"Noto Sans"`

The font family used across the whole shell. The font needs to be installed on your system or Qt will fall back to something else.

## bar

### bar.timeFormat

Default: `"ddd MMM d hh:mm:ss AP"`

The format string for the time shown in the Time/Workspace Widget. It uses Qt's date/time format codes, so `ddd` is the short day name, `MMM` is the short month, `hh:mm:ss` is the time and `AP` adds AM/PM. The default looks like `Tue Nov 17 09:41:07 AM`.

### bar.orientation

Default: `"top"`

Which edge of the screen the bar sits on. Use `"top"` or `"bottom"`.

## weather

### weather.getWeatherFromIp

Default: `false`

When `true`, Wisp works out your location from your IP address and uses it for the Weather Widget. Needs `curl`.

### weather.weatherCity

Default: `""`

The city to get weather for when `getWeatherFromIp` is `false`. Set this to your city name (for example `"Minneapolis"`).

## wallpaper

### wallpaper.directory

Default: `"~/Pictures/wallpapers"`

The folder the Theme Switcher pulls its wallpaper gallery from.

### wallpaper.runMatugen

Default: `false`

Whether `matugen` runs after you pick a wallpaper to regenerate the theme colors. If this is off, the wallpaper changes but the theme stays as is.

## packages

### packages.notifyOnStartUp

Default: `false`

Sends a notification about pending package updates (yay and flatpak) every time Wisp starts.

### packages.notifyEveryDay

Default: `false`

Sends a notification about pending package updates once a day.

## battery

### battery.warnPercentage

Default: `30`

The battery percentage at which Wisp warns you that you are running low. Should be a number from 0 to 100.

### battery.autoPowerSaver

Default: `true`

Automatically switches to the power saver profile when the battery is low. You can still change profiles by hand from the Battery Widget popup.

## notifications

### notifications.toastDurationMs

Default: `2000`

How long a notification toast stays on screen, in milliseconds.

## welcome

### welcome.jokesFile

Default: `"/usr/share/wisp/config/jokes.txt"`

Path to the text file the Welcome Section pulls its joke from. Point it at your own file to use your own jokes. The example `config.json` uses a personal path, so change it if you copy it.

## osd

### osd.duration

Default: `1000`

How long an On Screen Display stays visible after its value changes, in milliseconds.

### osd.orientation

Default: `"bottom"`

Which edge of the screen the OSD shows up on. Use `"top"` or `"bottom"`.

### osd.scaleSize

Default: `1.0`

A multiplier for the size of the OSD. `1.0` is normal, `1.5` is 50% bigger, `0.75` is a quarter smaller.

## Adding a New Option

If you are adding a setting, see the [Configuration section of architecture.md](architecture.md#configuration) for the steps, and add it to this document too.
