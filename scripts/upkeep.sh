#!/usr/bin/sh

# upkeep.sh - System maintenance utility for Arch Linux (using yay).
#
# This script automates the process of updating system and AUR packages,
# and cleaning up unnecessary dependencies and cached files.
# Usage: ./upkeep.sh

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Upkeeping system...${NC}"

yay -Syu

flatpak update -y

# Check if there are any orphans first to avoid yay/pacman throwing an error if none exist.
if [ -n "$(yay -Qdtq)" ]; then
    yay -Rns $(yay -Qdtq)
fi

flatpak uninstall --unused -y

yay -Sc