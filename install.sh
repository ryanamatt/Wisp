#!/usr/bin/env bash
#
# install.sh - build wisp and install it to standard locations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
INSTALL_BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/wisp"
WISP_SHARE_DIR="/usr/share/wisp"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m==> warning:\033[0m %s\n' "$1"; }
error() { printf '\033[1;31m==> error:\033[0m %s\n' "$1" >&2; }

if [[ ! -f "${SCRIPT_DIR}/CMakeLists.txt" ]]; then
    error "CMakeLists.txt not found next to this script. Run install.sh from the repo root."
    exit 1
fi

if ! command -v cmake >/dev/null 2>&1; then
    error "cmake not found. Install it first: sudo pacman -S cmake base-devel"
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    error "sudo not found, but it's needed to install into ${WISP_SHARE_DIR}."
    exit 1
fi

if ! command -v quickshell >/dev/null 2>&1; then
    warn "quickshell not found on PATH. wisp needs it at runtime to actually draw the bar."
    warn "Install it (e.g. from the AUR: yay -S quickshell-git) before running 'wisp run'."
fi

info "Configuring build in ${BUILD_DIR}"
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release

info "Building wisp"
cmake --build "${BUILD_DIR}" --parallel "$(nproc)"

BUILT_BIN="${BUILD_DIR}/wisp"
if [[ ! -x "${BUILT_BIN}" ]]; then
    error "Build finished but ${BUILT_BIN} wasn't produced. Check the build log above."
    exit 1
fi

info "Installing QML tree to ${WISP_SHARE_DIR}/qml (sudo)"
sudo cmake --install "${BUILD_DIR}"

info "Installing wisp binary to ${INSTALL_BIN_DIR}"
mkdir -p "${INSTALL_BIN_DIR}"
install -m 755 "${BUILT_BIN}" "${INSTALL_BIN_DIR}/wisp"

if [[ ! -f "${CONFIG_DIR}/config.json" ]]; then
    if [[ -f "${SCRIPT_DIR}/config/config.json" ]]; then
        info "Seeding default config at ${CONFIG_DIR}/config.json"
        mkdir -p "${CONFIG_DIR}"
        cp "${SCRIPT_DIR}/config/config.json" "${CONFIG_DIR}/config.json"
    fi
else
    info "Existing config found at ${CONFIG_DIR}/config.json, leaving it alone"
fi

case ":${PATH}:" in
    *":${INSTALL_BIN_DIR}:"*)
        ;;
    *)
        warn "${INSTALL_BIN_DIR} is not on your PATH."
        warn "Add this to your shell rc (e.g. ~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish):"
        warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac

info "Done. Try: wisp --help"
