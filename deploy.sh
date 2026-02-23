#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

COMPOSE_FILE="compose.yml"
ENV_FILE=".env"

if [[ ! -f "${ENV_FILE}" ]]; then
  cp .env.example "${ENV_FILE}"
  echo "Created ${ENV_FILE} from .env.example."
  echo "Set LOCAL_SCRIBE_IMAGE to a real image, then re-run deploy.sh"
  exit 0
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found. Install Docker Engine and Compose plugin first."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose plugin not found. Install Docker Compose plugin first."
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

if [[ "${LOCAL_SCRIBE_IMAGE:-}" == "" ]]; then
  echo "LOCAL_SCRIBE_IMAGE is empty in ${ENV_FILE}. Set it and retry."
  exit 1
fi

if [[ "${LOCAL_SCRIBE_IMAGE}" == "ghcr.io/your-org/local-scribe:latest" ]]; then
  echo "LOCAL_SCRIBE_IMAGE is still the placeholder value in ${ENV_FILE}."
  echo "Set it to your real published image and retry."
  exit 1
fi

if [[ -z "${LOCAL_UID:-}" ]]; then
  export LOCAL_UID="$(id -u)"
fi
if [[ -z "${LOCAL_GID:-}" ]]; then
  export LOCAL_GID="$(id -g)"
fi

mkdir -p "${HOST_JOBS_DIR:-./jobs}"

if command -v nvidia-smi >/dev/null 2>&1; then
  if ! nvidia-smi >/dev/null 2>&1; then
    echo "warning: nvidia-smi is present but failed; GPU runtime may be unavailable."
  fi
else
  echo "warning: nvidia-smi not found; GPU runtime may be unavailable."
fi

echo "Pulling image: ${LOCAL_SCRIBE_IMAGE}"
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" pull

echo "Starting service"
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d

timeout_s="${HEALTH_TIMEOUT_SECONDS:-90}"
health_url="http://127.0.0.1:${HOST_PORT:-8080}/healthz"

echo "Waiting for health (${timeout_s}s): ${health_url}"
for _ in $(seq 1 "${timeout_s}"); do
  if curl -fsS "${health_url}" >/dev/null 2>&1; then
    echo "local-scribe is healthy"
    echo "UI:      http://127.0.0.1:${HOST_PORT:-8080}/"
    echo "Health:  ${health_url}"
    exit 0
  fi
  sleep 1
done

echo "Service did not become healthy within ${timeout_s}s."
echo "Recent logs:"
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" logs --tail=80 local-scribe || true
exit 1
