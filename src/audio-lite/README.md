
# Audio Lite

A feature to provide audio to the container. This should be installed after a
desktop provider such as [desktop-lite](https://github.com/devcontainers/features/tree/main/src/desktop-lite)

## Example Usage

```json
"overrideFeatureInstallOrder": [
    "ghcr.io/devcontainers/features/desktop-lite",
    "ghcr.io/empathicqubit/empathicqubit-dc-features/audio-lite"
],
"features": {
    "ghcr.io/devcontainers/features/desktop-lite:1": {
        "version": "latest"
    },
    "ghcr.io/empathicqubit/empathicqubit-dc-features/audio-lite:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
|mumblePort|The port which Mumble should listen on|number|64378|
|mumblePassword|Set a password required to join the server. You only need this if you open the server port to the public.|string||