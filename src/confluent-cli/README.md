
# Confluent CLI Installer (confluent-cli)

Installs the Confluent CLI inside a Dev Container

## Example Usage

```json
"features": {
    "ghcr.io/tsok-dev/devcontainer-features/confluent-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Release version to install (e.g. '3.24.1' or use 'latest' to auto-detect from GitHub). | string | latest |
| installPath | Folder where the confluent binary will be placed. | string | /usr/local/bin |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/tsok-dev/devcontainer-features/blob/main/src/confluent-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
