#!/usr/bin/env bash
#
# uninstall.sh - remove everything install.sh put in place

set -euo pipefail

INSTALL_BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/wisp"
WISP_SHARE_DIR="/usr/share/wisp"
ICON_DIR="/usr/share/icons/hicolor/scalable/apps"

PURGE_CONFIG=0
for arg in "$@"; do
    case "${arg}" in
        --purge)
            PURGE_CONFIG=1
            ;;
        *)
            echo "Unknown option: ${arg}" >&2
            echo "Usage: $0 [--purge]" >&2
            exit 1
            ;;
    esac
done

info()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m==> warning:\033[0m %s\n' "$1"; }

if ! command -v sudo >/dev/null 2>&1; then
    warn "sudo not found. System paths under /usr/share won't be removed automatically."
fi

if [[ -f "${INSTALL_BIN_DIR}/wisp" ]]; then
    info "Removing ${INSTALL_BIN_DIR}/wisp"
    rm -f "${INSTALL_BIN_DIR}/wisp"
else
    info "No wisp binary at ${INSTALL_BIN_DIR}/wisp, skipping"
fi

if [[ -d "${WISP_SHARE_DIR}" ]]; then
    info "Removing ${WISP_SHARE_DIR} (sudo)"
    sudo rm -rf "${WISP_SHARE_DIR}"
else
    info "No ${WISP_SHARE_DIR} directory found, skipping"
fi

if [[ -f "${ICON_DIR}/wisp.svg" ]]; then
    info "Removing ${ICON_DIR}/wisp.svg (sudo)"
    sudo rm -f "${ICON_DIR}/wisp.svg"

    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1 || true
    fi
else
    info "No icon found at ${ICON_DIR}/wisp.svg, skipping"
fi

if [[ "${PURGE_CONFIG}" -eq 1 ]]; then
    if [[ -d "${CONFIG_DIR}" ]]; then
        info "Removing config at ${CONFIG_DIR}"
        rm -rf "${CONFIG_DIR}"
    else
        info "No config directory found at ${CONFIG_DIR}, skipping"
    fi
else
    if [[ -d "${CONFIG_DIR}" ]]; then
        info "Leaving config at ${CONFIG_DIR} in place (pass --purge to remove it)"
    fi
fi

info "Done."
