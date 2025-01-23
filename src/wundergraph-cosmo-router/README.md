
# WunderGraph Cosmo Router (wundergraph-cosmo-router)

Installs the Cosmo Router binary from GitHub releases.

## Example Usage

```json
"features": {
    "ghcr.io/tsok-dev/devcontainer-features/wundergraph-cosmo-router:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | The router@<version> to download from GitHub releases | string | 0.164.1 |
| installPath | Install destination for the binary | string | /usr/local/bin |
| binaryName | Rename the binary if desired (e.g. 'wgrouter') | string | router |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/tsok-dev/devcontainer-features/blob/main/src/wundergraph-cosmo-router/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
