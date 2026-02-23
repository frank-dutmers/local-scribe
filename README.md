# Bare-Bones Deployment Kit

This folder is a minimal, pull-and-run deployment path for Local Scribe on a brand new machine.

## Goal

- Fewest manual steps
- No dev setup on target host
- Deterministic startup with one script

## Prerequisites

- Docker Engine
- Docker Compose plugin
- NVIDIA runtime support (`nvidia-smi` should work for GPU mode)
- A published container image for Local Scribe

## Quick Start

1. Copy this folder to the target host.
2. Run once:

```bash
bash deploy.sh
```

This creates `.env` from `.env.example` and exits.

3. Edit `.env` if needed. Default image is pinned to:

```bash
ghcr.io/frank-dutmers/local-scribe:v0.1.0
```
4. Run again:

```bash
bash deploy.sh
```

The script pulls the image, starts the service, and waits for health.

## URLs

- UI: `http://127.0.0.1:${HOST_PORT}/`
- Health: `http://127.0.0.1:${HOST_PORT}/healthz`

## Files

- `compose.yml`: runtime service definition
- `.env.example`: deployment variables
- `deploy.sh`: bootstrap + preflight + deploy + health wait

## Variable Notes

- `LOCAL_SCRIBE_IMAGE` (required): published image reference (default pinned to `ghcr.io/frank-dutmers/local-scribe:v0.1.0`)
- `HOST_JOBS_DIR`: host path for job outputs
- `LOCAL_UID` / `LOCAL_GID`: optional; auto-detected if blank
- `TRANSCRIBE_MODELS_ROOT`: defaults to baked-cache in-image path
- `HEALTH_TIMEOUT_SECONDS`: health wait budget
