#!/usr/bin/env bash

SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

SAVE_FILE=false
FULL_MONITOR=false
FILENAME=""

function usage() {
  echo "Usage: $0 [-s] [-w] [-h|--help]"
  echo "  -s             Save the screenshot to $SAVE_DIR"
  echo "  -w             Takes a Screenshot of Entire Current Montior"
  echo "  -h, --help     Show this help message"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -s)
      SAVE_FILE=true;;
    -w) FULL_MONITOR=true ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
  shift
done

TMP_FILE=$(mktemp)

if [ "$FULL_MONITOR" = true ]; then
  GEOMETRY=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x),\(.y) \(.width)x\(.height)"')
  grim -g "$GEOMETRY" - > "$TMP_FILE"
else
  grim -g "$(slurp)" - > "$TMP_FILE"
fi

wl-copy < "$TMP_FILE"

if [ "$SAVE_FILE" = true ]; then
  FILENAME="$(date +%Y-%m-%d_%H-%M-%S).png"
  
  mv "$TMP_FILE" "$SAVE_DIR/$FILENAME"
  echo "Saved to $SAVE_DIR/$FILENAME"
  notify-send "Screenshot Saved" "File saved to $SAVE_DIR/$FILENAME"
else
  # Clean up if not saving
  rm "$TMP_FILE"
  notify-send "Screenshot" "Screenshot copied to clipboard."
fi
