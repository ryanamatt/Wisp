#!/usr/bin/env bash
#
# tools/format.sh - run clang-format over src/
#
# Usage:
#   tools/format.sh            format files in place
#   tools/format.sh --check    report problems, change nothing, exit 1 if any

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

MODE="write"
case "${1:-}" in
    "")        ;;
    --check)   MODE="check" ;;
    -h|--help) sed -n '3,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)         echo "Unknown option: $1" >&2; exit 1 ;;
esac

if [[ ! -d src ]]; then
    echo "Error: 'src' directory not found." >&2
    exit 1
fi

if ! command -v clang-format >/dev/null 2>&1; then
    echo "clang-format not found. Install it: sudo pacman -S clang" >&2
    exit 1
fi

if [[ "${MODE}" == "check" ]]; then
    echo "Checking formatting under src/..."
    find src -type f \( -name '*.cpp' -o -name '*.hpp' \) -print0 \
        | xargs -0 clang-format --dry-run --Werror
    echo "Formatting OK."
else
    echo "Running clang-format on files under src/..."
    find src -type f \( -name '*.cpp' -o -name '*.hpp' \) -print0 \
        | xargs -0 clang-format -i
    echo "Formatting complete."
fi
