#!/usr/bin/env bash

set -e

################################################################################
# Read Feature Options
################################################################################
# VERSION is provided by the feature's "options.version"
LOCALTUNNEL_VERSION="${VERSION:-latest}"

################################################################################
# Check if npm is installed
################################################################################
if ! command -v npm &> /dev/null; then
    echo "[ERROR] npm is not available in this environment."
    echo "Please ensure Node.js + npm are installed (via another feature or your base image) before using this feature."
    exit 1
fi

echo "[INFO] Installing localtunnel (lt) via npm at version: ${LOCALTUNNEL_VERSION}"

################################################################################
# Install LocalTunnel globally
################################################################################
if [ "${LOCALTUNNEL_VERSION}" = "latest" ]; then
    if ! npm install --global "localtunnel"; then
        echo "[ERROR] Failed to install localtunnel"
        exit 1
    fi
else
    if ! npm install --global "localtunnel@${LOCALTUNNEL_VERSION}"; then
        echo "[ERROR] Failed to install localtunnel@${LOCALTUNNEL_VERSION}"
        exit 1
    fi
fi

echo "[INFO] LocalTunnel installation complete!"
echo "[INFO] Checking 'lt --help':"
lt --help || echo "[WARNING] Could not run 'lt --help'."
