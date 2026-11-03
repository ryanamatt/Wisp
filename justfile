set default-list := true
set shell := ["bash", "-euo", "pipefail", "-c"]

# --- Build ---

# Build everything, or one module (e.g. `just build time`)
[group('build')]
build module="":
    ./tools/build.sh {{module}}

# Optimized build
[group('build')]
release:
    ./tools/build.sh --release

# Wipe build/ and rebuild from scratch
[group('build')]
rebuild:
    ./tools/build.sh --clean

# Remove build/
[group('build')]
clean:
    rm -rf build

# List buildable modules
[group('build')]
targets:
    ./tools/build.sh --list

# --- Run ---

# Run the dev build from the repo (extra args go to wisp, e.g. `just run -d run`)
[group('run')]
run *args:
    ./tools/run.sh {{args}}

# Build, then run
[group('run')]
dev *args: build
    ./tools/run.sh {{args}}

# Send a command to the dev build (e.g. `just wisp toggle calendar`)
[group('run')]
wisp *args:
    ./tools/run.sh {{args}}

# Show wisp's log (e.g. `just log tail 50`)
[group('run')]
log *args:
    ./tools/run.sh log {{args}}

# --- Quality ---

# Run Format or Check Formatting
[group('quality')]
[arg("check", long="check", value="--check")]
format check="":
    ./tools/format.sh {{ check }}

# Verify dev tools and runtime dependencies are installed
[group('quality')]
doctor:
    ./tools/doctor.sh

# --- Install ---

# Install Wisp
[group('install')]
install:
    ./install.sh

# Uninstall Wisp (`just uninstall --purge` also removes your config)
[group('install')]
uninstall *args:
    ./uninstall.sh {{args}}
