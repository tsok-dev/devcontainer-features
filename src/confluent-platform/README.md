
# Confluent Platform (confluent-platform)

Installs the Confluent Platform (including Kafka and other services) from an official tarball.

## Example Usage

```json
"features": {
    "ghcr.io/tsok-dev/devcontainer-features/confluent-platform:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Which Confluent Platform version to install (e.g. 7.4.0, 7.3.2, etc.) | string | 7.4.0 |
| installPath | Where to extract the Confluent Platform files. | string | /usr/local/confluent |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/tsok-dev/devcontainer-features/blob/main/src/confluent-platform/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
