#!/bin/sh
set -eu

: "${MINIO_HOST?}"
: "${MINIO_PORT?}"
: "${MINIO_ROOT_USER?}"
: "${MINIO_ROOT_PASSWORD?}"
: "${MINIO_BUCKET?}"

MINIO_ENDPOINT="http://${MINIO_HOST}:${MINIO_PORT}"
export MC_CONFIG_DIR="/tmp/.mc"

echo "Waiting for MinIO at ${MINIO_ENDPOINT} ..."
until wget -qO- "${MINIO_ENDPOINT}/minio/health/ready" >/dev/null 2>&1; do
  sleep 2
done

echo "Configuring mc alias..."
mc alias set local "${MINIO_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null

echo "Creating bucket (if missing): ${MINIO_BUCKET}"
mc mb -p "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

echo "Ensuring bucket is PRIVATE (no anonymous access)"
# This removes any anonymous policy if previously set
mc anonymous set none "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

echo "MinIO init done."
