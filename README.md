<div align="center">
  <h1>Wisp</h1>
  <img src="assets/wisp.svg" width="10%">
</div>

<div align="center">
<text>Wisp is a Shell for Arch + Hyprland. This is a personal Desktop Shell tailored to my
system. I do not plan on supporting any system that is not my own.
Feel free to fork or take in compliance with the MIT License.
</text>
</div>


## Dependencies

<table><tr><td>

* Hyprland
* Quickshell
* jq

</td><td>

* awww
* gcalcli
* curl
* cava

</td><td>

* PipeWire
* hyprsunset
* cliphist
* wl-clipboard

</td><td>

* grim
* slurp

</td></tr></table>

### Install all Dependencies

One command on Arch using [yay](https://github.com/Jguer/yay) (it handles both the official repos and the AUR):
 
```Bash
yay -S --needed hyprland quickshell jq awww gcalcli curl cava pipewire hyprsunset cliphist wl-clipboard grim slurp
```

## Install

```Bash
# Clone the repo
git clone --depth=1 https://github.com/ryanamatt/Wisp && cd Wisp

just install
# Or
./install.sh
```

This builds wisp and installs it:

* `wisp` binary to `~/.local/bin`
* QML tree, internal scripts, and matugen config to `/usr/share/wisp`

## Build & Run (without installing)

```Bash
# Build
just build

# Run directly from the build directory
just run
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
| `log` [head\|tail\|clear] [n] | Show the Log File | 
| `status` | Shows the Status of Wisp |
| `open <target>` | Open a widget/popup |
| `close <target>` | Close a widget/popup |
| `toggle <target>` | Toggle a widget/popup |
| `targets` | Lists all available targets |
| `lock` | Lock the Screen |

### Examples

```Bash
wisp run                    # launch the bar in the foreground
wisp -d run                 # launch the bar and detach immediately
wisp toggle themeSwitcher   # open/close the theme switcher
wisp reload                 # restart quickshell without restarting wisp
wisp kill                   # stop a running instance
```

## Configuration

Wisp reads a `config.json`, by default at `~/.config/wisp/config.json`. A missing file, missing keys, or a parse error all fall back to defaults rather than failing.

See [config/config.json](config/config.json) for an example.

See [docs/theming.md](docs/theming.md) on how to theme Wisp.

## Development

Wisp is built for my own setup, but if you want to hack on it, here is how to get going. Everything below assumes the dependencies above are installed.

### Build requirements
 
In addition to the runtime dependencies, you need a C++17 compiler, CMake, Qt6 (Core and QML), and [just](https://github.com/casey/just):
 
```Bash
yay -S --needed base-devel cmake qt6-base qt6-declarative just
```

### Workflow

```Bash
just build    # compile the wisp executable and the Wisp.* QML modules
just run      # run from the build tree, so your build is picked up ahead of any installed copy
```

You can also point a running binary at a working tree without installing:
 
```Bash
wisp -f /path/to/shell.qml -m /path/to/backend/modules run
```
 
Config changes (including `config.json` edits) are read at startup, so use `wisp reload` to apply them. If something misbehaves, check the log with `wisp log tail`.
 
### Project layout
 
* `qml/`: the Quickshell config, which is the entire UI
* `src/`: all C++. Anything under `src/backend/` is compiled into a `Wisp.*` QML module, everything else is compiled into the `wisp` executable
* `scripts/`: Bash helpers called from QML
* `config/`: example `config.json` and `jokes.txt`
* `tools/`: development tools such as `format.sh` and `build.sh`
### Further reading
 
* [docs/architecture.md](docs/architecture.md) explains how the pieces fit together, how to add a backend module, and how to add a config setting.
* [docs/features.md](docs/features.md) lists every feature Wisp has.
* [docs/theming.md](docs/theming.md) covers colors and theming.

## Log File

Log file is located at `~/.local/state/wisp/wisp.log`.

View Log Command

```Bash
# Full Files
wisp log

# Or Part of Log (Default 15 lines)
wisp log head
wisp log tail
wisp log head 10
wisp log tail 5
```

## License

Wisp is licensed under the MIT License.

Icons are provided by Google's Material Symbols & Icons, which are Apache Licensed. You can find a copy of the license in [assets/icons/LICENSE](assets/icons/LICENSE).
