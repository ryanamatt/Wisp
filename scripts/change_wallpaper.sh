#!/usr/bin/env bash

# scripts/change_wallpaper.sh

set -euo pipefail

WALLPAPER_DIR="${WISP_WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"

WISP_SHARE_DIR="${WISP_SHARE_DIR:-/usr/share/wisp}"
if [[ -f "$WISP_SHARE_DIR/config/matugen/config.toml" ]]; then
    MATUGEN_CONFIG="$WISP_SHARE_DIR/config/matugen/config.toml"
else
    MATUGEN_CONFIG="$WISP_SHARE_DIR/matugen/config.toml"
fi

WISP_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wisp"
mkdir -p "$WISP_STATE_DIR"

input_arg="${1:-}"
wallpaper=""

c_green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
c_yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
c_red() { printf '\033[1;31m%s\033[0m\n' "$*" >&2; }
c_blue() { printf '\033[1;34m%s\033[0m\n' "$*"; }

function update_wallpaper() {
    awww img --transition-type center --transition-step 90 --transition-fps 60 --transition-duration 2 "$wallpaper"
    sleep 1
    (cd "$WISP_STATE_DIR" && matugen image "$wallpaper" -c "$MATUGEN_CONFIG" -t scheme-vibrant --source-color-index 0)
    c_green "Update Wallpaper and Ran Matugen"
}

apply_razer_colors() {
    if ! command -v razer-cli >/dev/null 2>&1; then
        return # If razer-cli not there just return
    fi

    local json_file="$HOME/.config/wisp/colors.json"

    if [[ ! -f "$json_file" ]]; then
        c_yellow "No Razer color file found at $json_file"
        return
    fi

    if ! command -v jq >/dev/null 2>&1; then
        c_yellow "razer-cli or jq not installed, skipping Razer lighting"
        return
    fi

    local color
    color=$(jq -r '.accent // empty' "$json_file" 2>/dev/null | sed 's/#//' || true)

    if [[ ! "$color" =~ ^[0-9A-Fa-f]{6}$ ]]; then
        c_yellow "Invalid or missing accent color in $json_file, skipping Razer lighting"
        return
    fi

    c_blue "Apply Razer lighting: #$color"

    razer-cli -c "$color"
}

if [ -z "$input_arg" ]; then
    c_red "Error: Please Provide a Wallpaper image/gif/vid."
    exit 1
fi

if [ -f "$WALLPAPER_DIR/$input_arg" ]; then
    wallpaper="$WALLPAPER_DIR/$input_arg"
    update_wallpaper "$wallpaper"

else
    resolved_path=$(realpath -- "$input_arg" 2>/dev/null || true)
    if [ -f "$resolved_path" ]; then
        wallpaper="$resolved_path"
        update_wallpaper "$wallpaper"
    else
        c_red "Error: Wallpaper '$input_arg' does not exist."
        exit 1
    fi
fi

apply_razer_colors

notify-send -a "Wisp" -i "$WISP_SHARE_DIR/assets/wisp.svg" "Changed Wallpaper!" "Changed Wallpaper to $input_arg"
