#!/bin/bash
set -e

echo "Cleaning build directory..."
rm -rf build
mkdir -p build
cd build

echo "Configuring with CMake..."
cmake ..

echo "Building app..."
cmake --build . --parallel

echo "Build complete!"
echo "App path: $(find . -name "CouplesApp" -type f -perm +111 | head -1)"
echo "To run the app: cd build && ./$(find . -name "CouplesApp" -type f -perm +111 | head -1 | sed 's/^.\///')"