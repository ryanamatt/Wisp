#!/bin/bash

# tools/format.sh

set -euo pipefail

if [ ! -d "src" ]; then
    echo "Error: 'src' directory not found in the current path."
    exit 1
fi

echo "Running clang-format on files under src/..."

find src -type f \( -name "*.cpp" -o -name "*.hpp" \) -exec clang-format -i {} +

echo "Formatting complete!"
