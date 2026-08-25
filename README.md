# Wisp

Wisp is a Shell for Arch + Hyprland. 

## Dependencies

<table><tr><td>

* Hyprland
* Quickshell
* jq
* Matugen

</td><td>

* awww
* gcalcli
* curl
* cava

</td><td>

* PipeWire
* swaync
* cliphist
* wl-clipboard

</td><td>

* hyprsunset

</td></tr></table>

## Install

```Bash
./install.sh
```

This builds wisp and installs it:

* `wisp` binary to `~/.local/bin`
* QML tree, internal scripts, and matugen config to `/usr/share/wisp` 

## Build & Run (without installing)

```Bash
# Build
cmake -B build
cmake --build build
# Or 
./tools/build.sh

# Run directly from the build directory
./build/wisp run
```

## Usage

```
wisp [command] [options]
```

### Commands

| Command | Description |
|---|---|
| `run` | Launch the bar |
| `kill` | Stop a running wisp instance |
| `reload` | Restart the quickshell process of a running wisp instance |
| `open <target>` | Open a widget/popup |
| `close <target>` | Close a widget/popup |
| `toggle <target>` | Toggle a widget/popup |

### Examples

```Bash
wisp run                    # launch the bar in the foreground
wisp -d run                 # launch the bar and detach immediately
wisp toggle themeSwitcher   # open/close the theme switcher
wisp reload                 # restart quickshell without restarting wisp
wisp kill                   # stop a running instance
```

## IPC Targets

Every widget below can be controlled with `wisp open <target>`, `wisp close <target>`, or `wisp toggle <target>`.

| Target | Controls |
|---|---|
| `calendar` | Time / workspace popup (calendar view) |
| `appLauncher` | App launcher |
| `powerMenu` | Power menu |
| `audioPlayer` | Audio widget |
| `systemMonitor` | System monitor widget |
| `clipboard` | Clipboard widget |
| `network` | Network widget |
| `brightness` | Brightness widget |
| `battery` | Battery widget |
| `themeSwitcher` | Theme/wallpaper switcher |
| `workspaceSwitcher` | Workspace switcher |
| `commandCenter` | Command Center |

## Configuration

Wisp reads a `config.json`, by default at `~/.config/wisp/config.json`. A missing file, missing keys, or a parse error all fall back to defaults rather than failing.

See [config/config.json](config/config.json) for an example.

## Log File

Log file is located at `~/.local/state/wisp/wisp.log`.

## License

MIT
