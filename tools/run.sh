#!/usr/bin/env bash
#
# tools/run.sh - run wisp from the build tree without installing it
#
# Usage:
#   tools/run.sh                 same as: wisp run
#   tools/run.sh <wisp args>     any wisp command or option, e.g.
#                                tools/run.sh -d run
#                                tools/run.sh toggle calendar
#
# QML is loaded straight from qml/, and quickshell reloads it when files
# change, so QML edits need no rebuild. C++ changes need tools/build.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

if [[ ! -x build/wisp ]]; then
    echo "build/wisp not found. Build first: just build" >&2
    exit 1
fi

export WISP_SHARE_DIR="${ROOT}"

if [[ $# -eq 0 ]]; then
    set -- run
fi

echo "+ ./build/wisp -f ${ROOT}/qml -m ${ROOT}/build/qml $*"
exec ./build/wisp -f "${ROOT}/qml" -m "${ROOT}/build/qml" "$@"
