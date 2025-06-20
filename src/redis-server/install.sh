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

setup_redis() {
    # Create Redis data directory and set permissions
    mkdir -p /var/lib/redis-server/data
    
    # Set ownership to the determined USERNAME if not root, otherwise try redis user
    if [ "${USERNAME}" != "root" ] && id "${USERNAME}" >/dev/null 2>&1; then
        chown -R "${USERNAME}:${USERNAME}" /var/lib/redis-server/data
        chmod 0755 /var/lib/redis-server/data
    elif id redis >/dev/null 2>&1; then
        chown -R redis:redis /var/lib/redis-server/data
        chmod 0750 /var/lib/redis-server/data
    else
        chmod 0755 /var/lib/redis-server/data
    fi
    
    # Update Redis configuration and fix permissions
    if [ -f /etc/redis/redis.conf ]; then
        # Make config file readable by the user who will run Redis
        chmod 644 /etc/redis/redis.conf
        
        # Update configuration - replace the default dir instead of appending
        sed -i 's|^dir /var/lib/redis.*|dir /var/lib/redis-server/data|' /etc/redis/redis.conf
        # If no dir line exists, add it
        if ! grep -q "^dir " /etc/redis/redis.conf; then
            echo "dir /var/lib/redis-server/data" >> /etc/redis/redis.conf
        fi
        
        # Enable Redis to start as a daemon
        sed -i 's/^daemonize no/daemonize yes/' /etc/redis/redis.conf
        
        # Add memory overcommit setting to avoid warnings
        if ! grep -q "vm.overcommit_memory" /etc/redis/redis.conf; then
            echo "# Memory overcommit setting for containers" >> /etc/redis/redis.conf
            echo "# This is handled at the system level in containers" >> /etc/redis/redis.conf
        fi
        
        # Set ownership of config directory
        if [ "${USERNAME}" != "root" ] && id "${USERNAME}" >/dev/null 2>&1; then
            chown -R "${USERNAME}:${USERNAME}" /etc/redis/
        elif id redis >/dev/null 2>&1; then
            chown -R redis:redis /etc/redis/
        fi
    fi
    
    # Create init script that handles both systemd and direct Redis startup
    tee /usr/local/share/redis-server-init.sh << EOF
#!/bin/sh
set -e

# Ensure Redis data directory exists
mkdir -p /var/lib/redis-server/data

# Set permissions using the same logic as installation
if [ "${USERNAME}" != "root" ] && id "${USERNAME}" >/dev/null 2>&1; then
    chown -R "${USERNAME}:${USERNAME}" /var/lib/redis-server/data
    chmod 0755 /var/lib/redis-server/data
    REDIS_USER="${USERNAME}"
elif id redis >/dev/null 2>&1; then
    chown -R redis:redis /var/lib/redis-server/data
    chmod 0750 /var/lib/redis-server/data
    REDIS_USER="redis"
else
    chmod 0755 /var/lib/redis-server/data
    REDIS_USER="\$(whoami)"
fi

# Ensure config file permissions are correct
if [ -f /etc/redis/redis.conf ]; then
    chmod 644 /etc/redis/redis.conf
    # Also ensure the config uses the correct data directory
    sed -i 's|^dir /var/lib/redis.*|dir /var/lib/redis-server/data|' /etc/redis/redis.conf
fi

# Set memory overcommit to avoid Redis warnings in containers
echo 1 > /proc/sys/vm/overcommit_memory 2>/dev/null || true

# Start Redis server
if command -v systemctl >/dev/null 2>&1 && systemctl is-system-running >/dev/null 2>&1; then
    # Use systemd if available and running
    systemctl enable redis-server >/dev/null 2>&1 || true
    systemctl start redis-server || {
        echo "Systemd failed, falling back to direct Redis startup"
        if [ -f /etc/redis/redis.conf ] && [ -r /etc/redis/redis.conf ]; then
            redis-server /etc/redis/redis.conf --daemonize yes
        else
            echo "Config file not accessible, starting with minimal config"
            redis-server --daemonize yes --dir /var/lib/redis-server/data --port 6379
        fi
    }
elif command -v service >/dev/null 2>&1; then
    # Try using service command if available
    service redis-server start >/dev/null 2>&1 || {
        echo "Service command failed, falling back to direct Redis startup"
        if [ -f /etc/redis/redis.conf ] && [ -r /etc/redis/redis.conf ]; then
            redis-server /etc/redis/redis.conf --daemonize yes
        else
            echo "Config file not accessible, starting with minimal config"
            redis-server --daemonize yes --dir /var/lib/redis-server/data --port 6379
        fi
    }
else
    # Fall back to direct Redis startup
    echo "Starting Redis server directly..."
    if [ -f /etc/redis/redis.conf ] && [ -r /etc/redis/redis.conf ]; then
        redis-server /etc/redis/redis.conf --daemonize yes
    else
        echo "Config file not accessible, starting with minimal config"
        redis-server --daemonize yes --dir /var/lib/redis-server/data --port 6379
    fi
fi

# Wait a moment for Redis to start
sleep 3

# Verify Redis is running
if redis-cli ping >/dev/null 2>&1; then
    echo "Redis server started successfully"
else
    echo "Warning: Redis may not be running properly"
    # Try to show Redis process status for debugging
    if command -v pgrep >/dev/null 2>&1; then
        if pgrep redis-server >/dev/null 2>&1; then
            echo "Redis process is running but not responding to ping"
            echo "Trying to connect with explicit port..."
            if redis-cli -p 6379 ping >/dev/null 2>&1; then
                echo "Redis is responding on port 6379"
            else
                echo "Redis still not responding on port 6379"
                # Show Redis log if available
                if [ -f /var/log/redis/redis-server.log ]; then
                    echo "Last few lines of Redis log:"
                    tail -n 5 /var/log/redis/redis-server.log 2>/dev/null || true
                fi
            fi
        else
            echo "Redis process not found"
        fi
    fi
fi

set +e

# Execute whatever commands were passed in (if any). This allows us
# to set this script to ENTRYPOINT while still executing the default CMD.
exec "\$@"
EOF
    chmod +x /usr/local/share/redis-server-init.sh
    chown ${USERNAME}:root /usr/local/share/redis-server-init.sh
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