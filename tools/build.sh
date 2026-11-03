#!/usr/bin/env bash
#
# tools/build.sh - configure and build wisp for development
#
# Usage:
#   tools/build.sh [options] [module]
#
# Options:
#   -c, --clean      wipe the build directory first
#   -r, --release    Release build (default: Debug)
#   -l, --list       list buildable modules and exit
#   -h, --help       show this help
#
# Module (optional): "time" or "wisptime" builds only that QML module,
# "wisp" builds only the executable. No module builds everything.
#
# Environment:
#   BUILD_DIR        build directory (default: build)
#   BUILD_TYPE       Debug or Release (overridden by --release)

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

BUILD_DIR="${BUILD_DIR:-build}"
BUILD_TYPE="${BUILD_TYPE:-Debug}"
JOBS="$(nproc)"
CLEAN=0
LIST=0
MODULE=""

usage() { sed -n '3,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--clean)   CLEAN=1 ;;
        -r|--release) BUILD_TYPE=Release ;;
        -l|--list)    LIST=1 ;;
        -h|--help)    usage; exit 0 ;;
        -*)           echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
        *)
            if [[ -n "${MODULE}" ]]; then
                echo "Only one module may be given" >&2
                exit 1
            fi
            MODULE="$1"
            ;;
    esac
    shift
done

if ! command -v cmake >/dev/null 2>&1; then
    echo "cmake not found. Install it: sudo pacman -S cmake base-devel" >&2
    exit 1
fi

if [[ "${CLEAN}" -eq 1 ]]; then
    rm -rf "${BUILD_DIR}"
fi


cmake -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \

list_targets() {
    cmake --build "${BUILD_DIR}" --target help \
        | sed -n 's/^\.\.\. //p' \
        | awk '{print $1}'
}

filter_modules() {
    grep -E '^wisp' | grep -vE '_(autogen|qmltyperegistration|qmllint|qmlcachegen|resources)|plugin$' || true
}

if [[ "${LIST}" -eq 1 ]]; then
    list_targets | filter_modules
    exit 0
fi

if [[ -z "${MODULE}" ]]; then
    cmake --build "${BUILD_DIR}" --parallel "${JOBS}"
    exit 0
fi

name="$(tr '[:upper:]' '[:lower:]' <<< "${MODULE}")"
targets="$(list_targets)"

if grep -qx "${name}" <<< "${targets}"; then
    target="${name}"
elif grep -qx "wisp${name}" <<< "${targets}"; then
    target="wisp${name}"
else
    echo "Unknown module: ${MODULE}" >&2
    echo "Available modules:" >&2
    filter_modules <<< "${targets}" | sed 's/^/  /' >&2
    exit 1
fi

# QML modules also have a "<target>plugin" target that Qt actually loads.
build_targets=("${target}")
if grep -qx "${target}plugin" <<< "${targets}"; then
    build_targets+=("${target}plugin")
fi

echo "Building: ${build_targets[*]} (${BUILD_TYPE})"
cmake --build "${BUILD_DIR}" --parallel "${JOBS}" --target "${build_targets[@]}"
