#!/usr/bin/env bash
# install.sh - Installs WunderGraph CLI (wgc) via npm if npm is available

set -e

################################################################################
# Read Feature Options
################################################################################

WGC_VERSION=${VERSION:-"latest"}  # This is the version from devcontainer-feature.json options

################################################################################
# Check if npm is installed
################################################################################

if ! command -v npm &> /dev/null; then
    echo "[ERROR] npm was not found. Please ensure Node.js + npm are installed before using this feature."
    exit 1
fi

echo "[INFO] Installing WunderGraph CLI wgc@${WGC_VERSION} via npm..."

################################################################################
# Install wgc globally
################################################################################

npm install --global "wgc@${WGC_VERSION}"

echo "[INFO] WunderGraph CLI (wgc) installed. Version info:"
wgc --version || echo "[WARNING] Could not display wgc version."

echo "[INFO] Installation complete!"
