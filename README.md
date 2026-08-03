# Wisp

Wisp is a Shell.

## Build & Run

```Bash
# Build
cmake -B build
cmake --build build
# Or
./scripts/build.sh

# Run
./build/wisp
```

## Other

Keybinds Added to binds.lua

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs -c ~/Projects/wisp/qml ipc call appLauncher toggle"))

hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("qs -c ~/Projects/wisp/qml ipc call powerMenu toggle"))

