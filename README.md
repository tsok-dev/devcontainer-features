# Dev Container Features Collection

This repository hosts multiple Dev Container Features for various development tools and services.  

## Repository Structure

```
.
├─ src/
│  ├─ confluent-cli/
│  │  ├─ devcontainer-feature.json
│  │  ├─ install.sh
│  │  └─ README.md
│  ├─ confluent-platform/
│  │  ├─ devcontainer-feature.json
│  │  ├─ install.sh
│  │  └─ README.md
│  ├─ nats/
│  │  ├─ devcontainer-feature.json
│  │  ├─ install.sh
│  │  ├─ library_scripts.sh
│  │  └─ README.md
│  └─ ... (other features)
├─ .devcontainer/
│  └─ devcontainer.json (example usage)
├─ LICENSE
└─ README.md (this file)
```

### Features Overview

1. **`confluent-cli`**  
   - Installs the Confluent CLI binary from GitHub Releases.  
   - User-configurable options:
     - `version`: The release tag to download (e.g. `3.24.1`, or `latest`).  
     - `installPath`: Directory to place the `confluent` binary (default `/usr/local/bin`).  

2. **`confluent-platform`**  
   - Installs the full Confluent Platform (Kafka, Schema Registry, Connect, etc.) from the Confluent tarball.  
   - User-configurable options:
     - `version`: The Confluent Platform version (e.g. `7.4.0`).  
     - `installPath`: Where the platform is extracted (default `/usr/local/confluent`).  

3. **`nats`**  
   - Installs NATS server and CLI from GitHub Releases with configurable authentication and service management.
   - User-configurable options:
     - `serverVersion`: NATS server version (e.g. `2.11.5`, or `latest`).
     - `cliVersion`: NATS CLI version (e.g. `0.2.3`, or `latest`).
     - `auth`: Authentication method (`none`, `token`, `user-password`, `nkey`).
     - `jetstream`: Enable JetStream persistent messaging (default `true`).
     - `autoStart`: Automatically start NATS server (default `true`).

---

## Using These Features Locally

If you want to use these features in a local Dev Container without publishing them:

1. **Clone** or copy this repository into your project, ensuring the `src/` directory structure is preserved.
2. In your project’s `.devcontainer/devcontainer.json`, **reference the features** in `src/` via **relative paths**.  
   For example, if your structure looks like this:

   ```
   your-project/
   ├─ .devcontainer/
   │  └─ devcontainer.json
   └─ my-devcontainer-features/
      └─ src/
         ├─ confluent-cli/
         └─ confluent-platform/
   ```

   Your `.devcontainer/devcontainer.json` might reference them like so:

   ```jsonc
   {
     "name": "Dev Container with Confluent and NATS",
     "features": {
       // Confluent CLI feature (path to src/confluent-cli)
       "../my-devcontainer-features/src/confluent-cli": {
         "version": "latest",
         "installPath": "/usr/local/bin"
       },
       // Confluent Platform feature (path to src/confluent-platform)
       "../my-devcontainer-features/src/confluent-platform": {
         "version": "7.4.0",
         "installPath": "/usr/local/confluent"
       },
       // NATS feature (path to src/nats)
       "../my-devcontainer-features/src/nats": {
         "serverVersion": "latest",
         "cliVersion": "latest",
         "auth": "user-password",
         "username": "admin",
         "password": "secure-password",
         "jetstream": true
       }
     }
   }
   ```

3. **Rebuild** your Dev Container in VS Code (or another Dev Container environment).  
4. **Verify** installation inside the container:
   - **Confluent CLI**: `confluent --version`  
   - **Confluent Platform**: Check `kafka-server-start` or contents in `/usr/local/confluent` (if you used the default install path).

---

## Using These Features from a Registry (Optional)

If you publish these features to GHCR or another registry, you can reference them directly by their namespace, for example:

```jsonc
{
  "features": {
    "ghcr.io/tsok-dev/devcontainer-features/confluent-cli:1.0.0": {
      "version": "3.24.1",
      "installPath": "/usr/local/bin"
    },
    "ghcr.io/tsok-dev/devcontainer-features/confluent-platform:1.0.0": {
      "version": "7.4.0",
      "installPath": "/usr/local/confluent"
    }
  }
}
```

---

## Verification & Usage

### Confluent CLI

- Run `confluent --version` in the container’s terminal to confirm the CLI is installed.

### Confluent Platform

- Files will be located at `installPath` (e.g., `/usr/local/confluent`).  
- Start a service (e.g. Kafka) by running:
  ```bash
  $INSTALL_PATH/bin/kafka-server-start \
    $INSTALL_PATH/etc/kafka/server.properties
  ```

---

## Contributing

We welcome contributions and issues. Feel free to open a PR or file an issue:

- [Issues](https://github.com/tsok-dev/devcontainer-features/issues)
- [Pull Requests](https://github.com/tsok-dev/devcontainer-features/pulls)

---

## License

Include your chosen license (e.g. [MIT License](https://opensource.org/licenses/MIT)) in a `LICENSE` file at the root of this repo.
