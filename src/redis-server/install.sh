#!/usr/bin/env bash
# install.sh – Dev-Container feature: install and launch Redis

set -e
export DEBIAN_FRONTEND=noninteractive

################################################################################
# Configurable options (override from devcontainer-feature.json if desired)
################################################################################
REDIS_VERSION="${REDIS_VERSION:-latest}"   # e.g. 7.2.4 or "latest"
REDIS_PORT="${REDIS_PORT:-6379}"

################################################################################
# Install Redis (Debian/Ubuntu only)
################################################################################
apt-get update -yq
if [[ "$REDIS_VERSION" == "latest" || "$REDIS_VERSION" == "stable" ]]; then
  apt-get install -yq redis-server redis-tools
else
  apt-get install -yq "redis-server=${REDIS_VERSION}*" "redis-tools=${REDIS_VERSION}*"
fi

################################################################################
# Start Redis – background, container-friendly
################################################################################
redis-server \
  --daemonize yes \
  --port "$REDIS_PORT" \
  --bind 0.0.0.0 \
  --protected-mode no

# Simple health-check (retry up to 5 s)
for _ in {1..10}; do
  if redis-cli -p "$REDIS_PORT" ping >/dev/null 2>&1; then
    echo "✓ Redis is up on port $REDIS_PORT"
    break
  fi
  sleep 0.5
done

################################################################################
# House-keeping
################################################################################
rm -rf /var/lib/apt/lists/*
echo "🎉 Redis installation complete."
