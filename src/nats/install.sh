#!/bin/bash
set -e

. ./library_scripts.sh

# Feature options from devcontainer-feature.json
SERVER_VERSION="${SERVERVERSION:-latest}"
CLI_VERSION="${CLIVERSION:-latest}" 
INSTALL_PATH="${INSTALLPATH:-/usr/local/bin}"
NATS_PORT="${PORT:-4222}"
MONITOR_PORT="${MONITORPORT:-8222}"
JETSTREAM="${JETSTREAM:-true}"
AUTO_START="${AUTOSTART:-true}"
AUTH_METHOD="${AUTH:-none}"
TOKEN="${TOKEN:-}"
USERNAME="${USERNAME:-nats}"
PASSWORD="${PASSWORD:-password}"
DATA_DIR="${DATADIR:-/var/lib/nats}"

echo "Installing NATS Server and CLI..."
echo "Server Version: $SERVER_VERSION"
echo "CLI Version: $CLI_VERSION"
echo "Install Path: $INSTALL_PATH"

# Ensure nanolayer is available
ensure_nanolayer nanolayer_location "v0.5.4"

# Install NATS Server from GitHub releases
echo "Installing NATS Server..."
$nanolayer_location \
    install \
    devcontainer-feature \
    "ghcr.io/devcontainers-extra/features/gh-release:1.0.25" \
    --option repo='nats-io/nats-server' \
    --option binaryNames='nats-server' \
    --option version="$SERVER_VERSION" \
    --option assetRegex='.*amd64\.deb'

# Install NATS CLI from GitHub releases  
echo "Installing NATS CLI..."
$nanolayer_location \
    install \
    devcontainer-feature \
    "ghcr.io/devcontainers-extra/features/gh-release:1.0.25" \
    --option repo='nats-io/natscli' \
    --option binaryNames='nats' \
    --option version="$CLI_VERSION" \
    --option assetRegex='.*amd64\.deb'

# Create data directory
echo "Creating NATS data directory..."
mkdir -p "$DATA_DIR"
chmod 755 "$DATA_DIR"

# Create NATS configuration file
echo "Creating NATS configuration..."
NATS_CONFIG_DIR="/etc/nats"
mkdir -p "$NATS_CONFIG_DIR"

cat > "$NATS_CONFIG_DIR/nats-server.conf" << EOF
# NATS Server Configuration
port: $NATS_PORT

# HTTP monitoring port
http_port: $MONITOR_PORT

# Server name
server_name: "devcontainer-nats"

# Logging options
log_file: "$DATA_DIR/nats-server.log"
logtime: true
debug: false
trace: false

EOF

# Add JetStream configuration if enabled
if [ "$JETSTREAM" = "true" ]; then
    cat >> "$NATS_CONFIG_DIR/nats-server.conf" << EOF
# JetStream Configuration
jetstream {
    store_dir: "$DATA_DIR/jetstream"
    max_memory_store: 256MB
    max_file_store: 2GB
}

EOF
fi

# Add authentication configuration
case "$AUTH_METHOD" in
    "token")
        if [ -n "$TOKEN" ]; then
            echo "authorization: \"$TOKEN\"" >> "$NATS_CONFIG_DIR/nats-server.conf"
        else
            echo "Warning: Token authentication selected but no token provided"
        fi
        ;;
    "user-password")
        cat >> "$NATS_CONFIG_DIR/nats-server.conf" << EOF
# User/Password Authentication
authorization {
    users = [
        {user: "$USERNAME", password: "$PASSWORD"}
    ]
}

EOF
        ;;
    "nkey")
        echo "# NKey authentication would require additional setup" >> "$NATS_CONFIG_DIR/nats-server.conf"
        echo "# Please configure nkey authentication manually if needed" >> "$NATS_CONFIG_DIR/nats-server.conf"
        ;;
    "none"|*)
        echo "# No authentication configured" >> "$NATS_CONFIG_DIR/nats-server.conf"
        ;;
esac

# Create NATS initialization script
echo "Creating NATS initialization script..."
cat > /usr/local/share/nats-init.sh << 'EOF'
#!/bin/bash
set -e

NATS_CONFIG_DIR="/etc/nats"
DATA_DIR="/var/lib/nats"

# Ensure directories exist
mkdir -p "$DATA_DIR"
mkdir -p "$DATA_DIR/jetstream"

# Set proper permissions
chmod 755 "$DATA_DIR"
chmod 755 "$DATA_DIR/jetstream"

# Start NATS server if auto-start is enabled
if [ "${AUTO_START:-true}" = "true" ]; then
    echo "Starting NATS server..."
    exec nats-server -c "$NATS_CONFIG_DIR/nats-server.conf"
else
    echo "NATS server not started automatically (AUTO_START=false)"
    echo "To start NATS server manually, run:"
    echo "  nats-server -c $NATS_CONFIG_DIR/nats-server.conf"
    
    # Keep container running
    exec sleep infinity
fi
EOF

chmod +x /usr/local/share/nats-init.sh

# Create a simple NATS context for easy CLI usage
echo "Setting up NATS CLI context..."
mkdir -p /root/.config/nats/context

NATS_URL="nats://localhost:$NATS_PORT"
if [ "$AUTH_METHOD" = "token" ] && [ -n "$TOKEN" ]; then
    NATS_URL="nats://$TOKEN@localhost:$NATS_PORT"
elif [ "$AUTH_METHOD" = "user-password" ]; then
    NATS_URL="nats://$USERNAME:$PASSWORD@localhost:$NATS_PORT"
fi

cat > /root/.config/nats/context/devcontainer.json << EOF
{
  "description": "Default devcontainer NATS context",
  "url": "$NATS_URL",
  "user": "",
  "password": "",
  "creds": "",
  "nkey": "",
  "cert": "",
  "key": "",
  "ca": "",
  "nsc": "",
  "jetstream_domain": "",
  "jetstream_api_prefix": "",
  "jetstream_event_prefix": "",
  "inbox_prefix": "",
  "user_jwt": "",
  "color_scheme": ""
}
EOF

# Set the default context
echo "devcontainer" > /root/.config/nats/context/.current

# Set environment variables
export NATS_PORT="$NATS_PORT"
export NATS_MONITOR_PORT="$MONITOR_PORT"

echo "NATS installation completed!"
echo ""
echo "Configuration:"
echo "  Server Port: $NATS_PORT"
echo "  Monitor Port: $MONITOR_PORT" 
echo "  JetStream: $JETSTREAM"
echo "  Authentication: $AUTH_METHOD"
echo "  Data Directory: $DATA_DIR"
echo "  Config File: $NATS_CONFIG_DIR/nats-server.conf"
echo ""
echo "Usage:"
echo "  Start NATS server: nats-server -c $NATS_CONFIG_DIR/nats-server.conf"
echo "  Use NATS CLI: nats --help"
echo "  Check server status: nats server info"
echo ""
echo "Done!"
