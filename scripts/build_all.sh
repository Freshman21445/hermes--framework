#!/bin/bash
set -e

echo "=== Building Zig agent for x86_64-linux ==="
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSafe

echo "=== Building Zig agent for aarch64-linux ==="
zig build -Dtarget=aarch64-linux -Doptimize=ReleaseSafe

echo "=== Building plugins ==="
cd plugins
make clean
make
cd ..

echo "=== Building Go server ==="
cd server
go build -o hermes-server .
cd ..

echo "All builds complete."
