#!/usr/bin/env bash

# scripts/change_wallpaper.sh

set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/wallpapers"

input_arg="$1"
wallpaper=""

c_green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
c_yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
c_red() { printf '\033[1;31m%s\033[0m\n' "$*" >&2; }
c_blue() { printf '\033[1;34m%s\033[0m\n' "$*"; }

function update_wallpaper() {
    awww img --transition-type center --transition-step 90 --transition-fps 60 --transition-duration 2 "$wallpaper"
    matugen image "$wallpaper" -c config/matugen/config.toml -t scheme-vibrant --source-color-index 0
    c_green "Update Wallpaper and Ran Matugen"
}

apply_razer_colors() {
    local json_file=state/quickshell/colors.json

    if [[ ! -f "$json_file" ]]; then
        c_yellow "No Razer color file found at $json_file"
        return
    fi

    local color
    color=$(jq -r '.accent' "$json_file" | sed 's/#//')

    c_blue "Apply Razer lighting: #$color"

    if command -v razer-cli >/dev/null 2>&1; then
        razer-cli -c "$color"
    fi
}

if [ -z "$input_arg" ]; then
    c_red "Error: Please Provide a Wallpaper image/gif/vid."
    exit 1
fi

if [ -f "$WALLPAPER_DIR/$input_arg" ]; then
    wallpaper="$WALLPAPER_DIR/$input_arg"
    update_wallpaper "$wallpaper"

else
    resolved_path=$(realpath "$input_arg" 2>/dev/null)
    if [ -f "$resolved_path" ]; then
        wallpaper="$resolved_path"
        update_wallpaper "$wallpaper"
    else
        c_red "Error: Wallpaper '$input_arg' does not exist."
        exit 1
    fi
fi

apply_razer_colors
