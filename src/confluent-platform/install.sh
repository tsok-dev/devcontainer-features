#!/usr/bin/env bash
# install.sh - Installs the Confluent Platform from an official tarball.

set -e

################################################################################
# Read Feature Options
################################################################################

VERSION=${VERSION:-"7.4.0"}
INSTALL_PATH=${INSTALLPATH:-"/usr/local/confluent"}

################################################################################
# Derive Download URL
# The tarballs are usually found at:
#   https://packages.confluent.io/archive/<major>.<minor>/confluent-<full-version>.tar.gz
# For example, version=7.4.0 => https://packages.confluent.io/archive/7.4/confluent-7.4.0.tar.gz
################################################################################

MAJOR_MINOR="$(echo "$VERSION" | cut -d. -f1,2)"
TARBALL_URL="https://packages.confluent.io/archive/${MAJOR_MINOR}/confluent-${VERSION}.tar.gz"

echo "**** Installing Confluent Platform version $VERSION ****"
echo "Download URL: $TARBALL_URL"

################################################################################
# Install dependencies, then download & extract
################################################################################

# Download tarball
curl -sSL -o /tmp/confluent-platform.tgz "$TARBALL_URL"

# Extract to /tmp
tar -xzf /tmp/confluent-platform.tgz -C /tmp

################################################################################
# Move extracted folder to INSTALL_PATH
################################################################################

# The tar typically extracts to /tmp/confluent-<version>
EXTRACTED_DIR="/tmp/confluent-${VERSION}"
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "ERROR: Extracted directory not found: $EXTRACTED_DIR"
    exit 1
fi

# Create the install path if it doesn't exist
mkdir -p "$INSTALL_PATH"

# Move the entire extracted folder contents to INSTALL_PATH
mv "$EXTRACTED_DIR"/* "$INSTALL_PATH"

# Optionally, remove the top-level folder if you want a direct layout
# For instance, if you prefer /usr/local/confluent/confluent-7.4.0 as is,
# you can skip the move above and do a rename:
#   mv "$EXTRACTED_DIR" "$INSTALL_PATH"
# Adjust to your preference.

################################################################################
# Clean up
################################################################################

rm -rf /tmp/confluent-platform.tgz "$EXTRACTED_DIR"

echo "**** Confluent Platform installed in $INSTALL_PATH ****"
echo "You can start Kafka (for example) with:"
echo "  $INSTALL_PATH/bin/kafka-server-start $INSTALL_PATH/etc/kafka/server.properties"
echo "**** Installation complete! ****"
