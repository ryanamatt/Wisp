#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export WISP_SHARE_DIR="${SCRIPT_DIR}"

echo ./build/wisp -f "${SCRIPT_DIR}/qml" -m "${SCRIPT_DIR}/build/qml" run
./build/wisp -f "${SCRIPT_DIR}/qml" -m "${SCRIPT_DIR}/build/qml" run
