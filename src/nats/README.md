# NATS Server and CLI (nats)

Installs NATS server and CLI from GitHub releases with configurable authentication and service management.

## Example Usage

```json
"features": {
    "ghcr.io/tsok-dev/devcontainer-features/nats:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| serverVersion | Version of NATS server to install (e.g., 'latest', '2.11.5'). | string | latest |
| cliVersion | Version of NATS CLI to install (e.g., 'latest', '0.2.3'). | string | latest |
| installPath | Directory where NATS binaries will be installed. | string | /usr/local/bin |
| port | Port for NATS server to listen on. | string | 4222 |
| monitorPort | Port for NATS server monitoring interface. | string | 8222 |
| jetstream | Enable JetStream (persistent messaging) support. | boolean | true |
| autoStart | Automatically start NATS server when the container starts. | boolean | true |
| auth | Authentication method for NATS server. | string | none |
| token | Authentication token (only used when auth is 'token'). | string |  |
| username | Username for authentication (only used when auth is 'user-password'). | string | nats |
| password | Password for authentication (only used when auth is 'user-password'). | string | password |
| dataDir | Directory for NATS server data storage (JetStream, etc.). | string | /var/lib/nats |

## Customizations

### VS Code Extensions

- `ms-vscode.vscode-json`

## Advanced Configuration

### Authentication Methods

The feature supports several authentication methods:

- **none** (default): No authentication required
- **token**: Simple token-based authentication
- **user-password**: Username/password authentication  
- **nkey**: NKey-based authentication (requires manual setup)

### Example with Token Authentication

```json
"features": {
    "ghcr.io/tsok-dev/devcontainer-features/nats:1": {
        "auth": "token",
        "token": "my-secret-token"
    }
}
```

### Example with User/Password Authentication

```json
"features": {
    "ghcr.io/tsok-dev/devcontainer-features/nats:1": {
        "auth": "user-password",
        "username": "admin",
        "password": "secure-password"
    }
}
```

### Example with Custom Ports and JetStream Disabled

```json
"features": {
    "ghcr.io/tsok-dev/devcontainer-features/nats:1": {
        "port": "4223",
        "monitorPort": "8223",
        "jetstream": false
    }
}
```

## Usage

Once installed, you can use the NATS server and CLI:

### Server Management

```bash
# Start NATS server manually (if autoStart is false)
nats-server -c /etc/nats/nats-server.conf

# Check server status
nats server info

# View server logs
tail -f /var/lib/nats/nats-server.log
```

### CLI Usage

```bash
# Check CLI version
nats --version

# Publish a message
nats pub subject.name "Hello NATS"

# Subscribe to messages
nats sub subject.name

# JetStream operations (if enabled)
nats stream add mystream
nats pub mystream.test "Persistent message"
```

### Monitoring

Access the NATS monitoring interface at `http://localhost:8222` (or your configured monitor port).

## Data Persistence

NATS data is stored in `/var/lib/nats` which is mounted as a volume, ensuring persistence across container restarts.

## Configuration Files

- **Server Config**: `/etc/nats/nats-server.conf`
- **CLI Context**: `/root/.config/nats/context/devcontainer.json`
- **Logs**: `/var/lib/nats/nats-server.log`

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/tsok-dev/devcontainer-features/blob/main/src/nats/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
