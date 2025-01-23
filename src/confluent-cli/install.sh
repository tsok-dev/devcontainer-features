#!/usr/bin/env bash
# install.sh - Installs Confluent CLI from GitHub release archive

set -e

################################################################################
# Read Feature Options
################################################################################

VERSION=${VERSION:-"latest"}
INSTALL_PATH=${INSTALLPATH:-"/usr/local/bin"}

################################################################################
# Detect OS and Architecture
################################################################################

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="armv7" ;;
    *) 
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ "$OS" != "linux" ] && [ "$OS" != "darwin" ]; then
    echo "Unsupported OS: $OS"
    exit 1
fi

################################################################################
# If version=latest, fetch the latest release from GitHub
################################################################################

if [ "$VERSION" = "latest" ]; then
    echo "Fetching latest version from GitHub API..."
    # Query the GitHub API for the latest release tag of confluentinc/cli
    LATEST=$(curl -s https://api.github.com/repos/confluentinc/cli/releases/latest | grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/')
    VERSION="${LATEST}"
    echo "Latest version is $VERSION"
fi

################################################################################
# Download & Extract
################################################################################

echo "Installing Confluent CLI version $VERSION for $OS-$ARCH..."
TARBALL_URL="https://github.com/confluentinc/cli/releases/download/v${VERSION}/confluent_${VERSION}_${OS}_${ARCH}.tar.gz"
echo "Downloading $TARBALL_URL"

# Download
curl -sSL -o /tmp/confluent-cli.tgz "$TARBALL_URL"

# Extract
tar -xzf /tmp/confluent-cli.tgz -C /tmp

################################################################################
# Identify Extracted Directory & Move Binary
################################################################################

cd /tmp
# Confluent archive typically extracts to something like: confluent_v3.24.1_linux_amd64
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "confluent_${VERSION}_${OS}_${ARCH}" 2>/dev/null | head -1)

if [ -z "$EXTRACTED_DIR" ]; then
    # Fallback to any "confluent*" directory if the naming changed
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "confluent*" 2>/dev/null | head -1)
fi

if [ -z "$EXTRACTED_DIR" ]; then
    echo "ERROR: Could not find extracted folder. Installation failed."
    exit 1
fi

# Copy binary to the specified installPath
echo "Copying confluent binary to $INSTALL_PATH"
cp "$EXTRACTED_DIR/confluent" "$INSTALL_PATH/"

# Ensure it's executable
chmod +x "$INSTALL_PATH/confluent"

################################################################################
# Clean up
################################################################################

rm -rf /tmp/confluent-cli.tgz "$EXTRACTED_DIR"

echo "Confluent CLI installed at $INSTALL_PATH/confluent."
echo "Confluent CLI version:"
"$INSTALL_PATH/confluent" --version
echo "**** Installation Complete! ****"
