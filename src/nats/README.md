
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
| token | Authentication token (only used when auth is 'token'). | string | - |
| username | Username for authentication (only used when auth is 'user-password'). | string | nats |
| password | Password for authentication (only used when auth is 'user-password'). | string | password |
| dataDir | Directory for NATS server data storage (JetStream, etc.). | string | /var/lib/nats |

## Customizations

### VS Code Extensions

- `ms-vscode.vscode-json`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/tsok-dev/devcontainer-features/blob/main/src/nats/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
