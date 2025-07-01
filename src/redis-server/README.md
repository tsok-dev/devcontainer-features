
# Redis Server (redis-server)

The open source, in-memory data store used by millions of developers as a database, cache, streaming engine, and message broker.

This feature installs and configures Redis server to automatically start when the dev container is created. The Redis server runs as a daemon process and is ready to accept connections on the default port 6379.

## Example Usage

```json
"features": {
    "ghcr.io/tsok-dev/devcontainer-features/redis-server:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a version of Redis. | string | latest |

## Features

- **Automatic startup**: Redis server starts automatically when the container is created
- **Persistent data**: Data is persisted in a Docker volume mounted at `/var/lib/redis-server/data`
- **Secure configuration**: Includes a production-ready Redis configuration
- **User-friendly**: Runs as the dev container user (not root)
- **Management script**: Includes a control script at `/usr/local/share/redis-server-init.sh` for managing the Redis service

## Usage

Once installed, Redis will be automatically running and available at `redis://localhost:6379`.

You can interact with Redis using the `redis-cli` command:

```bash
# Test connection
redis-cli ping

# Set and get a value
redis-cli set mykey "Hello World"
redis-cli get mykey

# View server info
redis-cli info
```

## Management

The Redis server can be controlled using the management script:

```bash
# Check status
/usr/local/share/redis-server-init.sh status

# Restart Redis
/usr/local/share/redis-server-init.sh restart

# Stop Redis
/usr/local/share/redis-server-init.sh stop

# Start Redis
/usr/local/share/redis-server-init.sh start
```

## Configuration

The Redis configuration file is located at `/etc/redis/redis.conf` and includes:
- Persistent storage with both RDB snapshots and AOF
- Memory optimization settings
- Secure defaults with disabled dangerous commands
- Logging to `/var/log/redis/redis-server.log`

## Customizations

### VS Code Extensions

- `cweijan.vscode-redis-client` - Redis client extension for VS Code

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/tsok-dev/devcontainer-features/blob/main/src/redis-server/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
