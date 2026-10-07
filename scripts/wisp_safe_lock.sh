#!/usr/bin/sh

# scripts/wisp_safe_lock.sh
# Safely lock the screen with a backup of hyprlock

WISP_EXE="${WISP_SHARE_DIR}/build/wisp"

# Try local dev build if it exists
if [ -n "$WISP_SHARE_DIR" ] && [ -x "$WISP_EXE" ]; then
    if "$WISP_EXE" -f "${WISP_SHARE_DIR}/qml" lock; then
        exit 0
    fi
fi

# Try installed version on PATH
if command -v wisp >/dev/null 2>&1; then
    if wisp lock; then
        exit 0
    fi
fi

# Fallback to hyprlock
hyprlock
