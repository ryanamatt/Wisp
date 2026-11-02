# Wisp Architecture

Wisp is a Desktop Shell for Arch + Hyprland. This is a developer-facing document about how all the pieces fit together. It is meant for new comers and re-orientation after time away from the project.

## Table of Contents

1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Repository Layout](#repository-layout)
4. [Wisp to Quickshell Communication](#wisp-to-quickshell-communication)
5. [C++ Code](#c-code)
6. [QML Code](#qml-code)
7. [Scripts](#scripts)
8. [Configuration](#configuration)
9. [Logging](#logging)
10. [Build and Install](#build-and-install)

## Overview

Wisp has two halves the run as two processes:

- **`wisp`**: a C++ executable. It is the CLI, the process supervisor, and the owner of the configuration and logging.
- **`quickshell`**: the actual UI. It runs the QML under `qml/` and is spawned by `wisp` as a child process.

QML gets native functionality (audio, battery, calendar, and so on) from the C++ backend modules under `src/backed`, which are compiled as QML modules rather than linked into `wisp`.

```
                 +-----------------------------------+
  user / hypr -> |  wisp (C++ executable)            |
  keybinds       |  CLI, supervisor, config, logging |
                 +-----------------+-----------------+
                                   |
            fork + exec            |   env vars (at start)
            SIGUSR1 = reload       |   quickshell IPC (after start)
                                   v
                 +-----------------------------------+
                 |  quickshell (child process)       |
                 |  qml/shell.qml and everything     |
                 |  it imports                       |
                 +-----------------+-----------------+
                                   |
                       imports     |   calls
                                   v
              +-------------------------+   +-------------------+
              | Wisp.* QML modules      |   | scripts/*.sh      |
              | (C++, src/backend/)     |   | (long/complex     |
              +-------------------------+   |  shell commands)  |
                                            +-------------------+
```
## Tech Stack

| Layer | User For |
|---|---|
| Quickshell QML | All UI: Bar, Popups, UI, Lock Screen, Runner, etc. |
| JavaScript | Helper Logic inside QML |
| C++17 (Qt6 Core) | The `Wisp` CLI/supervisor and the QML backend modules |
| Bash | Longer or more complicated commands that QML calls out to (`scripts/`) |
| CMake | Build System | 
| nlohman/json | Config parsing (vendored in `third_party/`)

## Repository Layout

```
.
├── CMakeLists.txt        Build definition for everything
├── install.sh            Build + install
├── uninstall.sh          Remove installed files
├── run.sh                Dev helper for running from the build tree
├── cmake/                CMake helper scripts (version header generation)
├── config/               Example config.json, jokes.txt, matugen config + templates
├── qml/                  The Quickshell config (the whole UI)
├── scripts/              Bash helpers called by QML
├── src/                  All C++
│   ├── main.cpp          Entry point of the wisp executable
│   ├── env.hpp           Names of the env vars shared with QML
│   ├── backend/          Compiled into QML modules (NOT into wisp)
│   ├── bar/              Launches and supervises quickshell
│   ├── cli/              Argument parsing and the `log` command
│   ├── config/           config.json loading
│   ├── ipc/              `wisp open/close/toggle` forwarding
│   ├── logging/          Shared plain C++ logger
│   └── process/          Pid file, signals, kill/reload/status
├── third_party/          Vendored dependencies (nlohmann/json)
└── tools/                Development Tools (`format.sh`, `build.sh`)
```
 
The key rule for `src/`:
 
> Anything under `src/backend/` is compiled into a QML module for use by QML. Everything else under `src/` is compiled into the `wisp` executable.

## Wisp to Quickshell Communication
 
Communication is deliberately simple and is split into two phases.
 
**1. At start: environment variables.** Before spawning quickshell, wisp exports its state into its own environment, which the child inherits:
 
* All config values (`WISP_*` names defined in `src/env.hpp`, set in `config.cpp::exportEnv`).
* `QML2_IMPORT_PATH`, so QML can import the `Wisp.*` C++ modules.
* The share dir (`/usr/share/wisp` by default), so QML and scripts can find installed assets.
* A few quickshell/Qt tweaks (`QS_NO_RELOAD_POPUP`, `QT_MESSAGE_PATTERN`, `QT_LOGGING_RULES`).
QML reads these through the `Config` singleton (`qml/Config/Config.qml`). Because this is environment-based, config changes only take effect after a reload, which re-runs `config::load` and respawns quickshell.
 
**2. While running: Quickshell IPC.** `wisp open|close|toggle <target>` runs `qs -c <qmlDir> ipc call <target> <action>` (`src/ipc/ipc.cpp`). It uses `execvp`, so the wisp CLI process is replaced by `qs` and its exit code is passed through. On the QML side, IPC handlers live in the `IpcState` module, which routes calls to popup and window state. The valid targets are listed in the README.
 
Signals (`SIGTERM`, `SIGUSR1`) go from the CLI to the wisp supervisor only, never to quickshell directly.

## C++ Code
 
### `wisp` executable (everything in `src/` except `backend/`)
 
| Directory | Responsibility |
|---|---|
| `src/main.cpp` | Parse args, optionally daemonize, dispatch to a command |
| `src/cli/` | `args` (argument parsing, usage text) and `logCommand` (`wisp log`) |
| `src/bar/` | `runBar()`: environment setup, spawn quickshell, supervision loop |
| `src/process/` | `pidfile`, `supervisor` (signal handlers, daemonize), `control` (kill/reload), `status` |
| `src/ipc/` | Forwards open/close/toggle to quickshell's IPC |
| `src/config/` | Loads `config.json`, applies defaults, exports env vars |
| `src/logging/` | Shared logging core (see [Logging](#logging)) |
| `src/env.hpp` | Single place for env var names used by both C++ and QML |
 
### QML backend modules (`src/backend/`)
 
Each subdirectory becomes a QML module under the `Wisp.` namespace. They are defined in `CMakeLists.txt` with the `add_wisp_qml_module()` helper.
 
| Directory | QML import | Purpose |
|---|---|---|
| `audio/` | `Wisp.Audio` | Audio state/control |
| `battery/` | `Wisp.Battery` | Battery state |
| `brightness/` | `Wisp.Brightness` | Brightness state/control |
| `calculator/` | `Wisp.Calculator` | Calculator backend |
| `calendar/` | `Wisp.Calendar` | Calendar data |
| `logger/` | `Wisp.Log` | QML-facing logger singleton |
| `systemMonitor/` | `Wisp.System` | CPU/memory/etc. metrics |
| `time/` | `Wisp.Time` | Clock, countdown timer, stopwatch |
| `version/` | `Wisp.Version` | Version and commit hash |
 
Modules are output to `build/qml/Wisp/<Name>/` and installed with the rest of the QML tree.
 
To add a module, create `src/backend/<dir>/<name>.{hpp,cpp}` and add one line to `CMakeLists.txt`:
 
```cmake
add_wisp_qml_module(<target> <UriName> backend/<dir> <mainFileBasename> [extraBasenames...])
```

## QML Code
 
`qml/shell.qml` is the entry point. It is a single `Scope` that instantiates each top-level feature:
 
| Feature | Directory |
|---|---|
| Notification package checks | `Notifiers/` |
| Notification toasts | `Notifications/` |
| The bar and its widgets/popups | `Bar/` |
| Theme and wallpaper switcher | `ThemeSwitcher/` |
| Workspace switcher | `WorkspaceSwitcher/` |
| Command center (settings, system, packages, welcome) | `CommandCenter/` |
| Screenshot and screen recording | `Screenshot/` |
| App launcher, calculator, symbols | `Runner/` |
| Timer and stopwatch | `Timer/` |
| Hyprland window rules | `WindowRules/` |
| Lock screen | `LockScreen/` |
| On-screen displays (volume, brightness, caps lock, etc.) | `OSD/` |
 
Shared infrastructure:
 
| Directory | Purpose |
|---|---|
| `Components/` | Reusable building blocks (`BarPopup`, `WidgetPopup`, `BarWidgetContainer`, `ToggleButton`, and so on) |
| `Config/` | `Config` singleton exposing config values from env vars |
| `Colors/` | `Colors` singleton, generated from matugen output |
| `Icons/` | `Icons` singleton |
| `IpcState/` | IPC handlers plus popup, window, and lock state |
| `WispState/` | General shared runtime state |
| `Effects/` | Visual effects |
| `Utils/` | `Utils.js` helpers |

## Scripts
 
`scripts/` holds Bash for anything too long or fiddly to inline in QML. QML locates them through the share dir env var. They are installed to `/usr/share/wisp/scripts`.
 
| Script | Purpose |
|---|---|
| `change_wallpaper.sh` | Apply a wallpaper via Awww, Runs Matguen, and updates Razer Colors. |
| `screenshot.sh` | Screenshot capture (grim/slurp) |
| `upkeep.sh` | Package and system upkeep checks |
| `wisp_safe_lock.sh` | Lock the screen safely |

## Configuration
 
* User config: `~/.config/wisp/config.json` (or `$XDG_CONFIG_HOME/wisp/config.json`), or a path passed with `-c`.
* Defaults live **only** in `src/config/config.hpp`. Missing files, missing keys, wrong types, and out-of-range values all fall back to defaults with a logged warning and never fail startup.
* Config is flattened into env vars (`config.cpp::exportEnv`). To add a setting:
  1. Add a default constant and a `Config` field in `config.hpp`.
  2. Parse it in `config.cpp::load` (there are `readBool` and `readInt` helpers).
  3. Add an env var name in `src/env.hpp` and export it in `exportEnv`.
  4. Read it in `qml/Config/Config.qml`.
  5. Optionally add a control in `qml/CommandCenter/SettingsSection/`.
* Theme colors come from [matugen](https://github.com/InioX/matugen). Config and templates are in `config/matugen/` and install to `/usr/share/wisp/matugen`. The `wisp-colors.json` template feeds `Colors`, and the others theme external tools (kitty, fish, nvim, swaync, Hyprland, starship).

## Logging
 
`src/logging/log.{hpp,cpp}` is plain C++ with no Qt dependency, so both the `wisp` executable and the QML `Logger` singleton (`Wisp.Log`) share one implementation and one log file.
 
* File: `$XDG_STATE_HOME/wisp/wisp.log` (default `~/.local/state/wisp/wisp.log`).
* Line format: `[timestamp] [LEVEL] [category] message`.
* Levels: debug, info, warning, error. Warnings and errors go to stderr, the rest to stdout, with ANSI color on the terminal only.
* Thread-safe (mutex). The file is reopened automatically if it is rotated or deleted by another process, using a device and inode check.
* Rotation: at process start, a file over 5 MB is renamed to `wisp.log.old`.
* `wisp log [head|tail|clear] [n]` reads the file back and re-colors lines with `colorizeLine()`.
The `wisplogcore` static library is linked into both `wisp` and the `Wisp.Log` QML module.

## Build and Install
 
Key CMake targets:
 
| Target | Type | Notes |
|---|---|---|
| `wisp` | Executable | All non-backend C++ |
| `wisplogcore` | Static lib | Logging, shared by `wisp` and `Wisp.Log` |
| `wispconfig` | Static lib | Config loading, uses vendored nlohmann/json |
| `wisp<name>` | QML modules | One per backend directory |
| `wisp_version_header` | Custom target | Runs `cmake/GenerateVersionHeader.cmake` to produce `version.hpp` from git |
 
Compile-time definitions baked into `wisp`:
 
* `WISP_SHARE_DIR`: install prefix for assets (default `/usr/share/wisp`, configurable at CMake time).
* `WISP_DEFAULT_QML_DIR`: `${WISP_SHARE_DIR}/qml`.
* `WISP_QML_IMPORT_PATH`: where installed `Wisp.*` modules live.
Install layout:
 
| Source | Destination |
|---|---|
| `wisp` binary | `~/.local/bin` (via `install.sh`) |
| `qml/` plus built `build/qml/` modules | `/usr/share/wisp/qml` |
| `scripts/` | `/usr/share/wisp/scripts` |
| `config/matugen/` | `/usr/share/wisp/matugen` |
| `assets/` | `/usr/share/wisp/assets` |
| `config/jokes.txt` | `/usr/share/wisp/config` |
 
Developing without installing: build, then `./build/wisp run -m build/qml` (or use `run.sh`) so quickshell picks up the modules in the build tree ahead of the installed ones.

