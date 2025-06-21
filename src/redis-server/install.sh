#!/usr/bin/env bash

REDIS_SERVER_VERSION=${VERSION:-"latest"}
REDIS_SERVER_ARCHIVE_ARCHITECTURES="amd64 arm64 i386 ppc64el"
REDIS_SERVER_ARCHIVE_VERSION_CODENAMES="bookworm bullseye buster sid bionic focal jammy kinetic noble"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

# Default: Exit on any failure.
set -e

# Clean up
rm -rf /var/lib/apt/lists/*

# Setup STDERR.
err() {
    echo "(!) $*" >&2
}

if [ "$(id -u)" -ne 0 ]; then
    err 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Set up directories and permissions
setup_directories() {
    echo "Setting up Redis directories..."
    mkdir -p /var/lib/redis-server/data /var/lib/redis-server/logs
    
    # Set proper ownership and permissions
    if [ "${USERNAME}" != "root" ] && id "${USERNAME}" >/dev/null 2>&1; then
        chown -R "${USERNAME}:${USERNAME}" /var/lib/redis-server
        REDIS_USER="${USERNAME}"
    elif id redis >/dev/null 2>&1; then
        chown -R redis:redis /var/lib/redis-server
        REDIS_USER="redis"
    else
        REDIS_USER="root"
    fi
    
    chmod -R 755 /var/lib/redis-server
}

# Create a simple, reliable Redis configuration
create_redis_config() {
    echo "Creating Redis configuration..."
    
    # Ensure the config directory exists
    mkdir -p /etc/redis
    
    # Create a custom config that works reliably in containers
    cat > /etc/redis/redis-server.conf << 'EOF'
# Redis configuration optimized for dev containers
port 6379
bind 0.0.0.0
timeout 0
keepalive 300
daemonize yes

# Data persistence
dir /var/lib/redis-server/data
dbfilename dump.rdb
save 900 1
save 300 10
save 60 10000

# Logging
logfile /var/lib/redis-server/logs/redis-server.log
loglevel notice

# Memory management
maxmemory-policy allkeys-lru

# Security - no authentication in dev environment
protected-mode no
EOF

    # Set proper permissions on config file - make it readable by everyone
    chmod 644 /etc/redis/redis-server.conf
    
    # Set ownership of entire config directory and file
    if [ "${USERNAME}" != "root" ] && id "${USERNAME}" >/dev/null 2>&1; then
        chown -R "${USERNAME}:${USERNAME}" /etc/redis
    elif id redis >/dev/null 2>&1; then
        chown -R redis:redis /etc/redis
    fi
    
    # Ensure the config directory has proper permissions
    chmod 755 /etc/redis
}

setup_redis() {
    setup_directories
    create_redis_config
    # Create simplified, bulletproof init script
    cat > /usr/local/share/redis-server-init.sh << 'EOF'
#!/bin/sh
set -e

echo "Starting Redis server..."

# Ensure directories exist with proper permissions
mkdir -p /var/lib/redis-server/data /var/lib/redis-server/logs

# Set proper ownership based on determined user (same logic as installation)
if [ "${USERNAME:-}" != "root" ] && [ "${USERNAME:-}" != "" ] && id "${USERNAME}" >/dev/null 2>&1; then
    chown -R "${USERNAME}:${USERNAME}" /var/lib/redis-server
elif id redis >/dev/null 2>&1; then
    chown -R redis:redis /var/lib/redis-server
fi

chmod -R 755 /var/lib/redis-server

# Set memory overcommit to avoid Redis warnings
echo 1 > /proc/sys/vm/overcommit_memory 2>/dev/null || true

# Create a guaranteed working config in /var/lib/redis-server
cat > /var/lib/redis-server/redis.conf << 'REDISEOF'
port 6379
bind 0.0.0.0
daemonize yes
dir /var/lib/redis-server/data
logfile /var/lib/redis-server/logs/redis-server.log
protected-mode no
save ""
REDISEOF

# Set proper ownership and permissions on config file
chmod 644 /var/lib/redis-server/redis.conf
if [ "${USERNAME:-}" != "root" ] && [ "${USERNAME:-}" != "" ] && id "${USERNAME}" >/dev/null 2>&1; then
    chown "${USERNAME}:${USERNAME}" /var/lib/redis-server/redis.conf
elif id redis >/dev/null 2>&1; then
    chown redis:redis /var/lib/redis-server/redis.conf
fi

echo "Starting Redis with guaranteed config..."
redis-server /var/lib/redis-server/redis.conf

# Wait briefly for startup
sleep 2

# Simple verification
echo "Verifying Redis startup..."
if redis-cli ping > /dev/null 2>&1; then
    echo "✓ Redis is running and responding"
else
    echo "✗ Redis ping failed, checking process..."
    if pgrep redis-server > /dev/null 2>&1; then
        echo "✓ Redis process found, may need more time"
    else
        echo "✗ No Redis process found"
        if [ -f /var/lib/redis-server/logs/redis-server.log ]; then
            echo "Redis log output:"
            cat /var/lib/redis-server/logs/redis-server.log
        fi
    fi
fi

echo "Redis startup complete"

# Execute any additional commands
exec "$@"
EOF

    chmod +x /usr/local/share/redis-server-init.sh
    
    echo "Redis setup complete!"
}

install_using_apt() {
    # Install dependencies
    check_packages apt-transport-https curl ca-certificates gnupg2 sudo

    # Import the repository signing key
    curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    # Create the file repository configuration
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb ${VERSION_CODENAME} main" | sudo tee /etc/apt/sources.list.d/redis.list

    # Update lists
    apt-get update -yq

    # Soft version matching for CLI
    if [ "${REDIS_SERVER_VERSION}" = "latest" ] || [ "${REDIS_SERVER_VERSION}" = "lts" ] || [ "${REDIS_SERVER_VERSION}" = "stable" ]; then
        # Empty, meaning grab whatever "latest" is in apt repo
        version_major=""
        version_suffix=""
    else
        version_major="$(echo "${REDIS_SERVER_VERSION}" | grep -oE -m 1 "^([0-9]+)")"
        version_suffix="=$(apt-cache show redis-server | awk -F"Version: " '{print $2}' | grep -E -m 1 "^([0-9]:)(${REDIS_SERVER_VERSION})(\.|$|\+.*|-.*)")"

        if [ -z ${version_suffix} ] || [ ${version_suffix} = "=" ]; then
            echo "Provided REDIS_SERVER_VERSION (${REDIS_SERVER_VERSION}) was not found in the apt-cache for this package+distribution combo";
            return 1
        fi
        echo "version_major ${version_major}"
        echo "version_suffix ${version_suffix}"
    fi

    (apt-get install -yq redis-server${version_suffix} redis-tools \
        && setup_redis) || return 1
}

export DEBIAN_FRONTEND=noninteractive

# Source /etc/os-release to get OS info
. /etc/os-release
architecture="$(dpkg --print-architecture)"

if [[ "${REDIS_SERVER_ARCHIVE_ARCHITECTURES}" = *"${architecture}"* ]] && [[  "${REDIS_SERVER_ARCHIVE_VERSION_CODENAMES}" = *"${VERSION_CODENAME}"* ]]; then
    install_using_apt || use_zip="true"
else
    use_zip="true"
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"