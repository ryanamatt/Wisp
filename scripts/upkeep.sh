#!/usr/bin/sh

# upkeep.sh - System maintenance utility for Arch Linux (using yay).
#
# This script automates the process of updating system and AUR packages,
# and cleaning up unnecessary dependencies and cached files.
# Usage: ./upkeep.sh

GREEN='\033[0;32m'
NC='\033[0m'

WISP_SHARE_DIR="${WISP_SHARE_DIR:-/usr/share/wisp}"

echo -e "${GREEN}Upkeeping system...${NC}"

yay -Syu

flatpak update -y

# Check if there are any orphans first to avoid yay/pacman throwing an error if none exist.
if [ -n "$(yay -Qdtq)" ]; then
    yay -Rns $(yay -Qdtq)
fi

flatpak uninstall --unused -y

yay -Sc

sudo rm -rf /var/cache/pacman/pkg/download-*

notify-send -a "Wisp" -i "$WISP_SHARE_DIR/assets/wisp.svg" "Updated System" "System Packages Updated & Cache, Orphans Removed"
