# Wisp

Wisp is a Shell.

## Build & Run

```Bash
cmake -B build
cmake --build build

# Run
./build/wisp
```

## Other

Keybinds Added to binds.lua

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs -c ~/Projects/bar/qml ipc call appLauncher toggle"))

