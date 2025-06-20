# Redis Server

Installs Redis, the open source in-memory data store used by millions of developers as a database, cache, streaming engine, and message broker.

## Example Usage

```json
"features": {
    "ghcr.io/your-org/devcontainer-features/redis-server:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a version of Redis | string | latest |

## Supported Versions

- `latest` - Latest stable version
- `7` - Redis 7.x series
- `8` - Redis 8.x series (if available)

## What's Included

- Redis Server with automatic startup
- Redis CLI tools for management
- Persistent data storage in `/var/lib/redis-server/data`
- VS Code Redis Client extension for easy database management

## Usage

Once installed, Redis will automatically start when the container launches. You can connect to Redis using:

```bash
redis-cli
```

The Redis server runs on the default port `6379` and data is persisted in a Docker volume.

## Notes

- Redis runs as a daemon and automatically starts on container launch
- Data persistence is handled through Docker volumes
- The feature includes both systemd and fallback startup methods for compatibility