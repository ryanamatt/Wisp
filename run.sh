#!/usr/bin/env bash

set -euo pipefail

echo -e ./build/wisp -c config.json run
./build/wisp -c config/config.json run
