#!/usr/bin/env bash
#
# tools/doctor.sh - check that dev tools and runtime dependencies are present
#
# Exits 1 only if a required dev tool is missing. Runtime dependencies
# and optional tools are reported as warnings.

set -uo pipefail

ok()   { printf '  \033[1;32m ok \033[0m %s\n' "$1"; }
miss() { printf '  \033[1;31mmiss\033[0m %s\n' "$1"; }
opt()  { printf '  \033[1;33mmiss\033[0m %s (optional)\n' "$1"; }

status=0

check() { # level cmd [label]
    local level="$1" cmd="$2" label="${3:-$2}"
    if command -v "${cmd}" >/dev/null 2>&1; then
        ok "${label}"
    elif [[ "${level}" == "required" ]]; then
        miss "${label}"
        status=1
    else
        opt "${label}"
    fi
}

echo "Required for development:"
check required cmake
check required clang-format
check required just

echo "Optional dev tools:"
check optional clangd

echo "Runtime dependencies:"
for cmd in Hyprland quickshell jq matugen awww gcalcli curl cava pipewire \
            cliphist wl-copy hyprsunset grim slurp; do
    if command -v "${cmd}" >/dev/null 2>&1; then
        ok "${cmd}"
    else
        printf '  \033[1;33mmiss\033[0m %s\n' "${cmd}"
    fi
done

exit "${status}"
