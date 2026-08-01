# Wisp

Wisp is a Shell.

## Build & Run

```Bash
cmake -B build
cmake --build build

# Run
QML2_IMPORT_PATH=$(pwd)/build/qml qs -c ~/Projects/bar
```

## Other

Keybinds Added to binds.lua

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs -c ~/Projects/bar ipc call appLauncher toggle"))

