#!/bin/bash

echo "Testing NATS installation..."

# Test that binaries are installed
echo "Checking for NATS server binary..."
if command -v nats-server >/dev/null 2>&1; then
    echo "✓ nats-server found"
    nats-server --version
else
    echo "✗ nats-server not found"
    exit 1
fi

echo "Checking for NATS CLI binary..."
if command -v nats >/dev/null 2>&1; then
    echo "✓ nats CLI found"
    nats --version
else
    echo "✗ nats CLI not found"
    exit 1
fi

# Test configuration files
echo "Checking configuration files..."
if [ -f "/etc/nats/nats-server.conf" ]; then
    echo "✓ NATS server config found"
else
    echo "✗ NATS server config not found"
    exit 1
fi

if [ -f "/usr/local/share/nats-init.sh" ]; then
    echo "✓ NATS init script found"
else
    echo "✗ NATS init script not found"
    exit 1
fi

# Test data directory
if [ -d "/var/lib/nats" ]; then
    echo "✓ NATS data directory found"
else
    echo "✗ NATS data directory not found"
    exit 1
fi

echo "All tests passed! ✓"
