# empathicqubit-dc-features

This repository contains a single devcontainer feature - `audio-lite`,
which forwards audio from the container using Mumble. 

### `audio-lite`

Running `audio-lite` inside the built container will install a Mumble server,
which will start up after the UI to forward audio out of the container.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "overrideFeatureInstallOrder": [
        "ghcr.io/devcontainers/features/desktop-lite",
        "./audio-lite"
    ],
    "features": {
        "ghcr.io/devcontainers/features/desktop-lite:1": {
            "version": "latest"
        },
        "audio-lite": {}
    }
}
```