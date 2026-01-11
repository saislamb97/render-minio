#!/bin/sh
set -eu

: "${MINIO_ROOT_USER?}"
: "${MINIO_ROOT_PASSWORD?}"
: "${MINIO_BUCKET?}"

# Render sets PORT for web services
: "${PORT?}"

# We expose MinIO API publicly on $PORT (signed URLs work in browsers)
MINIO_API_PORT="${PORT}"
MINIO_CONSOLE_PORT="${MINIO_CONSOLE_PORT:-9090}"

export MC_CONFIG_DIR="/tmp/.mc"
MINIO_ENDPOINT_INTERNAL="http://127.0.0.1:${MINIO_API_PORT}"

echo "Starting MinIO..."
/usr/bin/minio server /data \
  --address ":${MINIO_API_PORT}" \
  --console-address ":${MINIO_CONSOLE_PORT}" &
MINIO_PID="$!"

echo "Waiting for MinIO to become ready at ${MINIO_ENDPOINT_INTERNAL} ..."
until wget -qO- "${MINIO_ENDPOINT_INTERNAL}/minio/health/ready" >/dev/null 2>&1; do
  sleep 2
done

echo "Configuring mc alias..."
mc alias set local "${MINIO_ENDPOINT_INTERNAL}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null

echo "Creating bucket (if missing): ${MINIO_BUCKET}"
mc mb -p "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

echo "Ensuring bucket is PRIVATE (no anonymous access)"
mc anonymous set none "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

echo "MinIO init complete. Bringing MinIO to foreground..."
wait "${MINIO_PID}"
