#!/usr/bin/env bash

set -e

# Configuration
REDIS_SERVER_VERSION="${VERSION:-"latest"}"
REDIS_SUPPORTED_ARCHS="amd64 arm64 i386 ppc64el"
REDIS_SUPPORTED_CODENAMES="bookworm bullseye buster sid bionic focal jammy kinetic noble"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
REDIS_DATA_DIR="/var/lib/redis-server/data"

# Error handler
err() {
    echo "(!) $*" >&2
    exit 1
}

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    err "Script must be run as root."
fi

# Pick appropriate non-root user
if [[ "${USERNAME}" =~ ^(auto|automatic)$ ]]; then
    for CANDIDATE in vscode node codespace "$(awk -F: '$3==1000 {print $1}' /etc/passwd)"; do
        if id -u "$CANDIDATE" > /dev/null 2>&1; then
            USERNAME="$CANDIDATE"
            break
        fi
    done
    USERNAME="${USERNAME:-root}"
elif [[ "${USERNAME}" == "none" ]] || ! id -u "$USERNAME" > /dev/null 2>&1; then
    USERNAME=root
fi

# Apt helpers
apt_get_update() {
    if [ "$(find /var/lib/apt/lists -type f | wc -l)" -eq 0 ]; then
        apt-get update -y
    fi
}

install_packages() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        apt_get_update
        apt-get install -y --no-install-recommends "$@"
    fi
}

setup_redis_wrapper() {
    # Create and configure the data directory with proper ownership and permissions
    mkdir -p "$REDIS_DATA_DIR"
    chown -R redis:redis "$REDIS_DATA_DIR"
    chmod 0750 "$REDIS_DATA_DIR"

    cat << 'EOF' > /usr/local/share/redis-server-init.sh
#!/bin/bash
set -e

# Start redis-server directly (not using init.d)
exec redis-server /etc/redis/redis.conf "$@"
EOF

    chmod +x /usr/local/share/redis-server-init.sh
    chown root:root /usr/local/share/redis-server-init.sh
}

install_redis_via_apt() {
    install_packages apt-transport-https curl ca-certificates gnupg2

    curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb ${VERSION_CODENAME} main" \
        > /etc/apt/sources.list.d/redis.list

    apt-get update -y

    local version_suffix=""
    if [[ "$REDIS_SERVER_VERSION" != "latest" && "$REDIS_SERVER_VERSION" != "lts" && "$REDIS_SERVER_VERSION" != "stable" ]]; then
        version_suffix="$(apt-cache show redis-server 2>/dev/null | awk -v v="$REDIS_SERVER_VERSION" '
            BEGIN { RS=""; found=0 }
            /Version: [0-9]+:?'$REDIS_SERVER_VERSION'(\.|$|-|\+)/ {
                match($0, /Version: ([^\n]+)/, a)
                print "=" a[1]
                found=1
                exit
            }')"

        if [[ -z "$version_suffix" ]]; then
            err "Redis version '${REDIS_SERVER_VERSION}' not found in apt cache."
        fi
    fi

    apt-get install -y "redis-server${version_suffix}"
    setup_redis_wrapper
}

# Load OS info
. /etc/os-release
architecture="$(dpkg --print-architecture)"

# Decide if we can install from apt or fallback to archive/manual
if [[ "$REDIS_SUPPORTED_ARCHS" == *"$architecture"* && "$REDIS_SUPPORTED_CODENAMES" == *"$VERSION_CODENAME"* ]]; then
    install_redis_via_apt || err "Apt install failed."
else
    err "This architecture/codename not supported via apt. Consider adding a manual archive fallback here."
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Redis installed and ready!"
