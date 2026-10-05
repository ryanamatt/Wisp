#!/usr/bin/env bash

# tools/build.sh
#
# Usage:
#   ./build.sh          clean rebuild of everything
#   ./build.sh time     rebuild only the wisptime module
#   ./build.sh wisptime same as above (full target name also works)
#   ./build.sh wisp     rebuild only the wisp executable
#   ./build.sh --list   show available targets

set -euo pipefail

BUILD_DIR="build"
JOBS="$(nproc)"

configure_if_needed() {
    if [[ ! -f "$BUILD_DIR/CMakeCache.txt" ]]; then
        cmake -B "$BUILD_DIR"
    fi
}

list_targets() {
    cmake --build "$BUILD_DIR" --target help \
        | sed -n 's/^\.\.\. //p' \
        | awk '{print $1}'
}

# No argument: full clean rebuild
if [[ $# -eq 0 ]]; then
    rm -rf "$BUILD_DIR"
    cmake -B "$BUILD_DIR"
    cmake --build "$BUILD_DIR" --parallel "$JOBS"
    exit 0
fi

configure_if_needed

if [[ "$1" == "--list" || "$1" == "-l" ]]; then
    list_targets | grep -E '^wisp' | grep -vE '_(autogen|qmltyperegistration|qmllint|qmlcachegen|resources)' || true
    exit 0
fi

# Accept "time" or "wisptime"
name="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
targets="$(list_targets)"

if grep -qx "$name" <<< "$targets"; then
    target="$name"
elif grep -qx "wisp$name" <<< "$targets"; then
    target="wisp$name"
else
    echo "Unknown module: $1" >&2
    echo "Available modules:" >&2
    grep -E '^wisp' <<< "$targets" \
        | grep -vE '_(autogen|qmltyperegistration|qmllint|qmlcachegen|resources)|plugin$' \
        | sed 's/^/  /' >&2
    exit 1
fi

# QML modules also have a "<target>plugin" target that Qt actually loads.
# Build it too when it exists.
build_targets=("$target")
if grep -qx "${target}plugin" <<< "$targets"; then
    build_targets+=("${target}plugin")
fi

echo "Building: ${build_targets[*]}"
cmake --build "$BUILD_DIR" --parallel "$JOBS" --target "${build_targets[@]}"
