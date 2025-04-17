#!/bin/bash

# Build the app
cmake -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_ARCHITECTURES=x86_64 -DCMAKE_TOOLCHAIN_FILE=$(pwd)/ios/cmake/toolchain.cmake -B build_ios
cmake --build build_ios

# Launch the simulator
open -a Simulator