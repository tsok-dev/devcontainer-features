#!/usr/bin/env bash

set -e

# ------------------------------------------------------------------------------
# Logging helpers
# ------------------------------------------------------------------------------
info() {
    echo "[INFO] $@"
}

fatal() {
    echo "[ERROR] $@" >&2
    exit 1
}

# ------------------------------------------------------------------------------
# Environment Setup
# - Reads environment variables from the Dev Container Feature:
#   VERSION     -> e.g. "1.2.3" or "latest" (but here we assume a direct version)
#   INSTALLPATH -> The directory for installing the binary (e.g. /usr/local/bin)
#   BINARYNAME  -> The final binary name (e.g. "router" or "wgrouter")
# ------------------------------------------------------------------------------
setup_env() {
    # If we're not root, use sudo
    SUDO="sudo"
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
    fi

    # Use provided install path or default to /usr/local/bin
    INSTALL_PATH="${INSTALLPATH:-/usr/local/bin}"

    # Use provided binary name or default to "router"
    BINARY_NAME="${BINARYNAME:-router}"

    # Ensure we have some VERSION, otherwise fatal
    if [ -z "${VERSION}" ]; then
        fatal "VERSION environment variable is not set!"
    fi
}

# ------------------------------------------------------------------------------
# Verify OS
# ------------------------------------------------------------------------------
setup_verify_os() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "${OS}" in
        linux|darwin)
            info "OS detected: ${OS}"
            ;;
        *)
            fatal "Unsupported OS: ${OS}"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Verify Architecture
# ------------------------------------------------------------------------------
setup_verify_arch() {
    ARCH=$(uname -m)
    case "${ARCH}" in
        amd64|x86_64)
            ARCH="amd64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        armv7l|armv6l|arm*)
            # If Cosmo provides armhf or armv7 tar, adapt as needed
            ARCH="arm"
            ;;
        *)
            fatal "Unsupported architecture: ${ARCH}"
            ;;
    esac

    info "Architecture detected: ${ARCH}"
}

# ------------------------------------------------------------------------------
# Check for curl/wget
# ------------------------------------------------------------------------------
verify_downloader() {
    if command -v "$1" >/dev/null 2>&1; then
        DOWNLOADER="$1"
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# Create temporary directory
# ------------------------------------------------------------------------------
setup_tmp() {
    TMP_DIR=$(mktemp -d -t wundergraph-router.XXXXXXXXXX)
    # We'll place the final extracted binary at TMP_BIN (before moving it)
    TMP_BIN="${TMP_DIR}/router"

    cleanup() {
        local code=$?
        set +e
        trap - EXIT
        rm -rf "${TMP_DIR}"
        exit "${code}"
    }
    trap cleanup INT EXIT
}

# ------------------------------------------------------------------------------
# Download utility
# ------------------------------------------------------------------------------
download() {
    local targetFile="$1"
    local url="$2"

    case "${DOWNLOADER}" in
        curl)
            curl -sSfL -o "${targetFile}" "${url}" || fatal "Download failed: ${url}"
            ;;
        wget)
            wget -qO "${targetFile}" "${url}" || fatal "Download failed: ${url}"
            ;;
        *)
            fatal "No valid downloader (curl or wget) found"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Download + extract the Cosmo Router tar
# ------------------------------------------------------------------------------
download_binary() {
    # The original script used: 
    #   https://github.com/wundergraph/cosmo/releases/download/router@<VERSION>/router-router@<VERSION>-<OS>-<ARCH>.tar.gz
    # Adjust if your naming differs
    BIN_URL="https://github.com/wundergraph/cosmo/releases/download/router@${VERSION}/router-router@${VERSION}-${OS}-${ARCH}.tar.gz"

    info "Downloading router from: ${BIN_URL}"
    download "${TMP_BIN}.tar.gz" "${BIN_URL}"

    info "Extracting router archive"
    tar -xzf "${TMP_BIN}.tar.gz" -C "${TMP_DIR}"

    if [ ! -f "${TMP_BIN}" ]; then
        fatal "Binary 'router' not found after extraction!"
    fi
}

# ------------------------------------------------------------------------------
# Move binary to the final location, rename if needed
# ------------------------------------------------------------------------------
setup_binary() {
    chmod 755 "${TMP_BIN}"
    mkdir -p "${INSTALL_PATH}"

    local finalPath="${INSTALL_PATH}/${BINARY_NAME}"
    info "Installing WunderGraph Router as '${BINARY_NAME}' to '${INSTALL_PATH}'"
    ${SUDO} mv -f "${TMP_BIN}" "${finalPath}"

    info "Checking version..."
    if ! "${finalPath}" -version >/dev/null 2>&1; then
        info "Version check command not found or failed; ignoring."
    fi

    info "Install complete! Run '${BINARY_NAME}' to use the router."
}

# ------------------------------------------------------------------------------
# Main function
# ------------------------------------------------------------------------------
download_and_verify() {
    setup_verify_os
    setup_verify_arch

    verify_downloader curl || verify_downloader wget || fatal "Could not find curl or wget"
    setup_tmp
    download_binary
    setup_binary
}

# ------------------------------------------------------------------------------
# Entry point
# ------------------------------------------------------------------------------
setup_env

download_and_verify
