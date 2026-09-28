

## Bar Widgets

The bar (`qml/Bar/Bar.qml`) hosts eleven widgets, one per directory in `qml/Bar/`. Most follow the same pattern: a compact widget sits in the bar, and hovering over it with the mouse opens a popup with more detail or controls. Popups can also be driven from the command line with `wisp open|close|toggle <target>`.

### Overview

| Widget | Purpose | IPC target |
|---|---|---|
| [[#AppLauncher]] | Launch configured applications | `appLauncher` |
| [[#Audio]] | Audio visualizer, volume, mic and media controls | `audioPlayer` |
| [[#Battery]] | Battery levels for the laptop and connected devices | `battery` |
| [[#Brightness]] | Backlight level, night light and keyboard backlight | `brightness` |
| [[#Clipboard]] | Searchable clipboard history | `clipboard` |
| [[#Network]] | Ethernet and Wi-Fi status, Wi-Fi management | `network` |
| [[#Notifications]] | Click to toggle the swaync panel | none |
| [[#PowerMenu]] | Lock, sleep, logout, reboot and shut down, with confirmation | `powerMenu` |
| [[#SystemMonitor]] | CPU and GPU stats, network, memory and partitions | `systemMonitor` |
| [[#TimeWorkspace]] | Clock, workspace dots and calendar | `calendar` |
| [[#Weather]] | Current temperature and conditions | none |

---

### AppLauncher

Launches applications. It is the popup of the `AppsWidget` in the bar, so hovering over the widget opens a launcher with an entry for each configured app. The launcher has full keyboard support, so it can be used without touching the mouse.

Apps are defined in `config.json` under `appLauncher.apps`. Each entry has three fields:

| Field | Meaning |
|---|---|
| `name` | Label shown in the launcher |
| `command` | Command to run, written as an array of arguments |
| `icon` | Icon theme name used for the entry |

```json
{ "name": "Obsidian", "command": ["flatpak", "run", "md.obsidian.Obsidian"], "icon": "md.obsidian.Obsidian" }
```

The default apps are Chrome, Discord, Spotify, Obsidian, VS Code, OBS Studio, Steam, Dolphin and Polychromatic. The `config.json` in the repo contains only default values, so these apps are used even when no config file exists. Flatpak apps are launched by putting the full `flatpak run` invocation in `command`.

### Audio

**In the bar:** instead of a standard icon, the widget is a live audio visualizer. It uses `cava` connected to PipeWire, so the bars move with whatever is currently playing.

**Popup (`audioPlayer`):** hovering over the visualizer opens a popup with:

* Microphone mute/unmute
* Volume controls: mute/unmute and a volume slider
* Album art for the current track
* Media controls: previous, play/pause and next
* Time elapsed and time remaining for the current track

### Battery

**In the bar:** the widget cycles through the battery level of each device in turn. Each step shows an icon of the device followed by that device's battery percentage, so a headset appears as a headset icon with its percentage.

Devices covered:

* The laptop battery, if the machine has one
* Razer accessories
* Devices that report through `headsetcontrol -b`
* Connected Bluetooth accessories

**Popup (`battery`):** hovering over the widget opens a list of all connected devices and their battery levels.

### Brightness

**In the bar:** a brightness icon with the current backlight percentage. If the device has no backlight, the widget shows a moon icon instead. Backlight readings come from the C++ `brightness` backend module.

**Popup (`brightness`):** hovering over the widget opens a popup with:

* **Night light toggle:** turns night light on and off by running `hyprsunset`. While it is on, a slider appears underneath the toggle for choosing the colour temperature in kelvin.
* **Keyboard backlight slider:** controls the keyboard backlight. It is only shown on devices that have one.

### Clipboard

**In the bar:** a clipboard icon.

**Popup (`clipboard`):** hovering over the icon opens the clipboard history, powered by `cliphist` and showing the last 100 items. From top to bottom it contains:

* **Search bar:** filters the history.
* **History toggle:** switches saving of clipboard contents to history on or off.
* **Clear all button:** wipes the entire history.
* **History list:** a long list of past items. Clicking one copies it back to the clipboard, and an X on each item deletes just that entry from `cliphist`. Copied images appear as images in the list.

### Network

**In the bar:** an icon showing the current connection type, either ethernet or Wi-Fi. If both are connected, ethernet takes priority.

**Popup (`network`):** hovering over the icon opens a popup with:

* **Network list:** the currently connected network sits at the top, followed by all available Wi-Fi networks.
* **Refresh icon:** refreshes the current connection.
* **Wi-Fi toggle:** turns Wi-Fi on and off.
* **Rescan button:** rescans for available Wi-Fi networks.
* **Password box:** when connecting to a password-protected network, a textbox appears to type the password.

**Known limitation:** connecting works well for networks that only need a password. More secure networks that need additional configuration are not supported.

### Notifications

A bar button that toggles the `swaync` notification panel. It runs `swaync-client -t -sw` when clicked. Unlike the other widgets, it does not respond to hover and must be clicked. Once the panel is open, everything is handled by `swaync`, so this widget has no popup of its own and no IPC target.

### PowerMenu

**In the bar:** a power button icon.

**Popup (`powerMenu`):** hovering over the icon opens a popup with five icon buttons, ordered from least to most destructive:

1. Lock
2. Sleep
3. Logout
4. Reboot
5. Shut Down

**Confirmation:** clicking a button does not run its command straight away. A green question mark appears next to the icon, and clicking the same icon again confirms and runs the command. Clicking a different icon moves the confirmation to that icon instead.

**Keyboard:** the menu has full keyboard support, so it can be used without touching the mouse.

### SystemMonitor

Monitors the state of the system. Data comes from the C++ `systemMonitor` backend module.

**In the bar:** an icon showing the CPU temperature in Celsius and the CPU usage percentage. The icon colour reflects the temperature:

| CPU temperature | Colour |
|---|---|
| Below 60°C | Green |
| 60°C to 84°C | Yellow |
| 85°C and above | Red |

**Popup (`systemMonitor`):** hovering over the widget opens a popup with these sections, top to bottom:

* **Network:** receive (rx) and transmit (tx) rates, each with an arrow icon.
* **CPU and GPU:** each has the same layout of an icon, its temperature in °C, a usage bar and the usage percentage.
* **Memory:** an icon, a usage bar and usage shown as used / total (for example 10 / 20) rather than a percentage.
* **Partitions:** a list of all partitions, each with an icon, a usage bar and usage shown as used / total rather than a percentage.

### TimeWorkspace

The clock and workspace indicator, combined into one widget.

**In the bar:** the current time in the configured format (`bar.timeFormat` in `config.json`), with five dots underneath. The default format `ddd MMM d hh:mm:ss AP` renders like `Sun Sep 20 03:45:12 PM`.

The dots represent the five workspaces of that monitor and map to numbered workspaces (1 to 10):

* **Active workspace:** its dot is a little longer, more ellipsoid than round, and filled with colour.
* **Special workspaces:** when a special workspace such as Spotify or Discord is active, a sixth dot appears containing the first character of the workspace name (S for Spotify, D for Discord).

**Popup (`calendar`):** hovering over the widget opens a calendar popup with two parts:

* **Calendar:** the current month shown in a 7 by 6 grid.
* **To-do list:** sits to the right of the calendar and is populated through `gcalcli`.

### Weather

Shows the current weather in the bar. It runs `curl` against `wttr.in` to fetch the data, then displays the temperature in Fahrenheit as text next to an icon of the current conditions, such as a sun for sunny or a cloud for cloudy. The available icons are sunny, cloudy, overcast, fog, rain, snow and thunderstorm. Like Notifications, it has no popup and no IPC target.

---

## Command Center

A full window for information and settings, controlled with `wisp open|close|toggle commandCenter`. It has a left panel for selecting a section and a right panel that shows the selected section.

### Welcome Section

The landing section. It shows a greeting based on the time of day, followed by the user's name taken from `whoami`. Underneath the greeting is the Wisp mascot with a floating animation.

### System Monitor Section

A more in-depth version of the [[#SystemMonitor]] bar popup, and generally nicer to look at. It shows:

* **Uptime and load**
* **Everything the bar popup shows:** network rx and tx, CPU and GPU stats, memory, and the list of partitions
* **Network graph:** a graph over time of network rx and tx

### Packages Section

Shows what needs updating on the system, and can run the upkeep for it.

* **yay updates:** a section on the left lists packages that need updating through `yay`, covering both the AUR and pacman.
* **Flatpak updates:** a second section lists flatpaks that need updating.
* **Refresh icon:** checks again for packages that need updating.
* **Upkeep button:** opens `kitty` and runs the upkeep bash script (`scripts/upkeep.sh`). The script:
    * updates packages with `yay` and `flatpak`
    * removes orphaned packages for both
    * clears the package cache for both

### Settings Section

Reads and writes the `config.json` file (by default at `~/.config/wisp/config.json`). The available settings are:

* **Time format:** the format used by the [[#TimeWorkspace]] widget
* **Bar orientation:** the orientation of the bar
* **Wallpaper directory:** the directory the Theme Switcher looks in for wallpapers
* **Font:** the font used by the shell

Changes come with previews that show what they would look like before anything is saved. A large save button writes the settings out to `config.json`.

---

## OSD

An On Screen Display: a small window that pops up for a second and then disappears. OSDs sit on the Wayland overlay layer, so they appear on top of everything else. For example, changing the volume pops up an OSD showing the new volume.

There are three OSDs:

* **Volume:** appears when the volume changes
* **Brightness:** appears when the brightness changes
* **Mic:** appears when the microphone is muted or unmuted

---

## Screenshot

A window with two tabs: Screenshot and Video.

### Screenshot Tab

* **Save to disk toggle:** turns saving to disk on or off. When on, screenshots are saved to `~/Pictures/Screenshots`.
* **Capture buttons:** three icon buttons for capturing a region, a window, or a full monitor.

Every screenshot is always copied to the clipboard, and a notification is sent when it succeeds.

### Video Tab

Not implemented yet. It currently just shows "Coming Soon" text.

---

## ThemeSwitcher

A window for changing the wallpaper, and with it the shell's colours.

* **Gallery:** a scrollable gallery of the wallpapers found in the wallpaper directory, which is configurable in the [[#Settings Section]] (default `~/Pictures/wallpapers`).
* **Wrap around:** the gallery loops in both directions. Reaching the end brings you back to the beginning, and vice versa.
* **Random tile:** a tile at the front of the gallery that selects a random wallpaper.
* **Keyboard:** full keyboard support, so it can be used without touching the mouse.

### Selecting a wallpaper

Once a wallpaper is selected, the `change_wallpaper` script (`scripts/change_wallpaper.sh`) runs:

1. It runs `awww` to set the wallpaper.
2. It runs `matugen`, which generates colours from the wallpaper. The `quickshell-colors` template overwrites `~/.config/wisp/colors.json`.
3. It also runs `razer-cli` to change the colours of Razer accessories.

The FileWatcher in `Colors.qml` watches `colors.json`, so the shell's colours change instantly when `matugen` rewrites the file.

---

## WorkspaceSwitcher

A window that brings up a rolodex of all the workspaces that contain a window. It can be navigated with the keyboard or the mouse, and selecting a workspace takes you to it.

Each workspace item shows the workspace number, or the first character of the name if the workspace is not a number, followed by icons of what is open on that workspace.

---

## CLI

The `wisp` binary is how Wisp is launched, controlled and inspected.

```
wisp [command] [options]
```

### Commands

| Command | Description |
|---|---|
| `run` | Launch the bar |
| `kill` | Stop a running wisp instance |
| `reload` | Restart the quickshell process of a running wisp instance |
| `log [head\|tail\|clear] [n]` | Print or manage the log contents (default: last 15 lines) |
| `open <target>` | Open a widget or popup |
| `close <target>` | Close a widget or popup |
| `toggle <target>` | Toggle a widget or popup |

### Options

| Option | Description |
|---|---|
| `-d` | Disown: return control to the shell immediately and keep running detached |
| `-f <dir>` | Directory containing `shell.qml` (default: `/usr/share/wisp/qml`) |
| `-m <dir>` | Extra QML module import path, checked before the installed modules |
| `-c <file>` | Path to `config.json` (default: `~/.config/wisp/config.json`) |
| `-h`, `--help` | Show the help message |
| `-v`, `--version` | Show version information |

`-f` and `-m` are for testing an unreleased build without installing it. For example, `-m build/qml` is used alongside `-f`.

### Targets

`open`, `close` and `toggle` take one of these targets:

| Target | Controls |
|---|---|
| `calendar` | Time and workspace popup (calendar view) |
| `appLauncher` | App launcher |
| `powerMenu` | Power menu |
| `audioPlayer` | Audio widget |
| `systemMonitor` | System monitor widget |
| `clipboard` | Clipboard widget |
| `network` | Network widget |
| `brightness` | Brightness widget |
| `battery` | Battery widget |
| `themeSwitcher` | Theme and wallpaper switcher |
| `workspaceSwitcher` | Workspace switcher |
| `commandCenter` | Command Center |
| `screenshot` | Screenshot window |

### Examples

```bash
wisp run                    # launch the bar in the foreground
wisp -d run                 # launch the bar and detach immediately
wisp toggle themeSwitcher   # open or close the theme switcher
wisp reload                 # restart quickshell without restarting wisp
wisp kill                   # stop a running instance
wisp log tail 5             # show the last 5 lines of the log
```

### Log file

The log file is at `~/.local/state/wisp/wisp.log`. `wisp log` prints from it, and `wisp log clear` clears the log file.

Each line has a timestamp, a level and a source. There are four levels: Info, Debug, Warn and Error.

This is what a successful launch of the bar looks like with `wisp run -d`:

```
[2026-09-20 15:41:43.028] [DEBUG] [wisp] disowned, running detached (pid 558226)
[2026-09-20 15:41:43.028] [DEBUG] [wisp] runBar: qmlDir=/usr/share/wisp/qml configPath=/home/myUser/.config/wisp/config.json modulePath=<none>
[2026-09-20 15:41:43.040] [INFO ] [wisp] loaded config from /home/myUser/.config/wisp/config.json
[2026-09-20 15:41:43.041] [DEBUG] [wisp] setting QML2_IMPORT_PATH=/usr/share/wisp/qml
[2026-09-20 15:41:43.041] [DEBUG] [wisp] setting WISP_SHARE_DIR=/usr/share/wisp
[2026-09-20 15:41:43.041] [INFO ] [wisp] environment ready: QML2_IMPORT_PATH=/usr/share/wisp/qml WISP_SHARE_DIR=/usr/share/wisp
[2026-09-20 15:41:43.041] [DEBUG] [wisp] wrote pid file /run/user/1000/wisp/wisp.pid (pid 558226)
[2026-09-20 15:41:43.041] [INFO ] [wisp] bar started (quickshell pid 558239)
[2026-09-20 15:41:43.041] [DEBUG] [wisp] exec: quickshell -c /usr/share/wisp/qml
```


