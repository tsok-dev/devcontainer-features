#!/usr/bin/env bash
set -e

################################################################################
# Helper functions for logs
################################################################################
info() {
    echo "[INFO] $@"
}
fatal() {
    echo "[ERROR] $@" >&2
    exit 1
}

################################################################################
# Read Feature Options (from devcontainer-feature.json)
################################################################################
# "binaryName" -> rename the CLI from 'relay' to something else
# "installPath" -> where to place the CLI
BINARY_NAME="${BINARYNAME:-relay}"
INSTALL_BIN_DIR="${INSTALLPATH:-/usr/local/bin}"

################################################################################
# Setup environment (sudo if not root)
################################################################################
setup_env() {
    SUDO="sudo"
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
    fi

    # This script originally used BIN_DIR=/usr/local/bin if not set
    BIN_DIR="${INSTALL_BIN_DIR:-/usr/local/bin}"
}

################################################################################
# Detect OS, possibly handle Windows if needed
################################################################################
setup_verify_os() {
    OS=$(uname | tr '[:upper:]' '[:lower:]')
    case "$OS" in
        darwin|linux)
            ;;
        mingw*|msys*|cygwin*)
            # Technically can handle Windows, but adapt if needed
            OS="windows"
            ;;
        *)
            fatal "OS $OS is not supported by this installation script"
            ;;
    esac
    info "OS = $OS"
}

################################################################################
# Detect architecture
################################################################################
setup_verify_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        amd64|x86_64)
            ARCH="amd64"
            ;;
        arm64|aarch64)
            ARCH="aarch64"
            ;;
        arm*)
            ARCH="arm"
            ;;
        *)
            fatal "Unsupported architecture: $ARCH"
            ;;
    esac
    info "ARCH = $ARCH"
}

################################################################################
# Check for curl or wget
################################################################################
verify_downloader() {
    if command -v "$1" > /dev/null 2>&1; then
        DOWNLOADER="$1"
        return 0
    fi
    return 1
}

################################################################################
# Create temporary directory (cleaned on exit)
################################################################################
setup_tmp() {
    TMP_DIR=$(mktemp -d -t relay-cli.XXXXXXXXXX)
    TMP_BIN="${TMP_DIR}/relay"
    cleanup() {
        local code=$?
        set +e
        trap - EXIT
        rm -rf "${TMP_DIR}"
        exit "${code}"
    }
    trap cleanup INT EXIT
}

################################################################################
# Download from https://my.webhookrelay.com/webhookrelay/downloads
################################################################################
download() {
    local targetFile="$1"
    local url="$2"

    case "$DOWNLOADER" in
        curl)
            curl -sSfL -o "$targetFile" "$url" || fatal "Download failed: $url"
            ;;
        wget)
            wget -qO "$targetFile" "$url" || fatal "Download failed: $url"
            ;;
        *)
            fatal "No valid downloader found"
            ;;
    esac
}

download_binary() {
    # The original script used:
    #   BIN_URL="https://my.webhookrelay.com/webhookrelay/downloads/relay-${OS}-${ARCH}"
    BIN_URL="https://my.webhookrelay.com/webhookrelay/downloads/relay-${OS}-${ARCH}"
    info "Downloading Webhook Relay CLI from ${BIN_URL}"
    download "${TMP_BIN}" "${BIN_URL}"
}

setup_binary() {
    chmod 755 "${TMP_BIN}"
    mkdir -p "${BIN_DIR}"

    local finalPath="${BIN_DIR}/${BINARY_NAME}"
    info "Installing CLI to ${finalPath}"
    ${SUDO} mv -f "${TMP_BIN}" "${finalPath}"
}

download_and_verify() {
    setup_verify_os
    setup_verify_arch

    # Check if we have curl or wget
    verify_downloader curl || verify_downloader wget || fatal "Cannot find curl or wget for downloading files"

    # Prepare a temp directory
    setup_tmp

    # Download and install
    download_binary
    setup_binary

    info "Installation complete! Checking binary name..."
    if ! command -v "${BINARY_NAME}" > /dev/null 2>&1; then
        info "Note: The CLI may not be on your PATH yet. Make sure ${BIN_DIR} is in your PATH."
    else
        "${BINARY_NAME}" --help || info "Could not show help. Possibly no '--help' command."
    fi
}

################################################################################
# Main
################################################################################

setup_env
download_and_verify
