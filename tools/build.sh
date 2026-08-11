#!/usr/bin/env bash

# tools/build.sh

rm -rf build/

cmake -B build

cmake --build build -j
