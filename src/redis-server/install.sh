#!/usr/bin/env bash
# install.sh  -- Dev-Container feature script
# Installs and launches Redis in a safe, reproducible way.

set -e

################################################################################
# 0. Configuration knobs (override in `features` JSON if you like)
################################################################################
REDIS_VERSION="${REDIS_VERSION:-latest}"   # e.g. 7.2.4 or "latest"
REDIS_PORT="${REDIS_PORT:-6379}"
DATA_DIR="/var/lib/redis"
LOG_DIR="/var/log/redis"
CONF_DIR="/etc/redis"
CONF_FILE="$CONF_DIR/redis.conf"

################################################################################
# 1. Pick the best non-root user (vscode, node …) or fall back to root
################################################################################
USERNAME="${USERNAME:-${_REMOTE_USER:-automatic}}"
if [[ "$USERNAME" =~ ^(auto|automatic)$ ]]; then
  for CANDIDATE in vscode node codespace "$(awk -F: '$3==1000 {print $1}' /etc/passwd)"; do
    if id -u "$CANDIDATE" &>/dev/null; then USERNAME="$CANDIDATE"; break; fi
  done
fi
id -u "$USERNAME" &>/dev/null || USERNAME=root
echo "Using user: $USERNAME"

################################################################################
# 2. Helper: apt install if Debian/Ubuntu
################################################################################
install_via_apt() {
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -yq
  if [[ "$REDIS_VERSION" == "latest" || "$REDIS_VERSION" == "stable" ]]; then
    apt-get install -yq redis-server redis-tools
  else
    # Try to match exact major.minor.* in the repo
    apt-get install -yq "redis-server=${REDIS_VERSION}*" "redis-tools=${REDIS_VERSION}*"
  fi
}

################################################################################
# 3. Install Redis
################################################################################
. /etc/os-release
case "$ID" in
  debian|ubuntu) install_via_apt ;;
  *)
    echo "❌ Unsupported distro ($ID). Base your devcontainer on Debian/Ubuntu or extend this script."
    exit 1
    ;;
esac

################################################################################
# 4. Directory layout & permissions
################################################################################
echo "Creating directories…"
mkdir -p "$DATA_DIR" "$LOG_DIR" "$CONF_DIR"
chown -R "$USERNAME":"$USERNAME" "$DATA_DIR" "$LOG_DIR" "$CONF_DIR"

################################################################################
# 5. Minimal, container-friendly redis.conf
################################################################################
cat > "$CONF_FILE" <<EOF
bind 0.0.0.0
port $REDIS_PORT
# Run Redis as a background daemon (dev-container friendly)
daemonize yes
dir $DATA_DIR
logfile $LOG_DIR/redis.log
protected-mode no

# RDB snapshots – keep them small for dev use
save 900 1
save 300 10
save 60 10000
EOF
chmod 644 "$CONF_FILE"
chown "$USERNAME":"$USERNAME" "$CONF_FILE"

################################################################################
# 6. Launch Redis right away so the feature “just works”
################################################################################
echo "Starting Redis on port $REDIS_PORT…"
sudo -u "$USERNAME" redis-server "$CONF_FILE"

# Quick sanity-check (retry for up to 5 s)
for i in {1..10}; do
  if redis-cli -p "$REDIS_PORT" ping &>/dev/null; then
    echo "✓ Redis is up and responding (port $REDIS_PORT)"
    break
  fi
  sleep 0.5
done

################################################################################
# 7. Clean up APT cache to keep the image lean
################################################################################
rm -rf /var/lib/apt/lists/*
echo "🎉 Redis feature install complete!"
