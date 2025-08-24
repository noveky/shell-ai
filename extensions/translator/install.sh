#!/bin/bash

# Install script for translator extension
# Creates symbolic links for dict and trans commands in bin directory

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BIN_DIR="$PROJECT_ROOT/bin"

# Create symbolic links

# Link dict command
ln -sf "$SCRIPT_DIR/dict" "$BIN_DIR/dict"

# Link trans command
ln -sf "$SCRIPT_DIR/trans" "$BIN_DIR/trans"
