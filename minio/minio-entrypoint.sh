#!/bin/sh
set -eu

: "${MINIO_ROOT_USER?}"
: "${MINIO_ROOT_PASSWORD?}"
: "${MINIO_BUCKET?}"
: "${PORT?}"  # Render injects this for web services

MINIO_API_PORT="${PORT}"
MINIO_CONSOLE_PORT="${MINIO_CONSOLE_PORT:-9090}"

export MC_CONFIG_DIR="/tmp/.mc"
MINIO_LOCAL_ENDPOINT="http://127.0.0.1:${MINIO_API_PORT}"

echo "[minio] Starting MinIO (API :${MINIO_API_PORT}, Console :${MINIO_CONSOLE_PORT})..."
/usr/bin/minio server /data \
  --address ":${MINIO_API_PORT}" \
  --console-address ":${MINIO_CONSOLE_PORT}" &
MINIO_PID="$!"

echo "[minio] Waiting for readiness at ${MINIO_LOCAL_ENDPOINT}/minio/health/ready ..."
until wget -qO- "${MINIO_LOCAL_ENDPOINT}/minio/health/ready" >/dev/null 2>&1; do
  sleep 2
done

echo "[minio] Configuring mc alias..."
mc alias set local "${MINIO_LOCAL_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null

echo "[minio] Ensuring bucket exists: ${MINIO_BUCKET}"
mc mb -p "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

echo "[minio] Enforcing PRIVATE access (no anonymous policy) for bucket: ${MINIO_BUCKET}"
mc anonymous set none "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

echo "[minio] Init complete. Streaming MinIO logs..."
wait "${MINIO_PID}"
