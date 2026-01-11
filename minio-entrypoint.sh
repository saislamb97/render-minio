#!/bin/sh
set -eu

: "${MINIO_ROOT_USER?}"
: "${MINIO_ROOT_PASSWORD?}"
: "${MINIO_BUCKET?}"
: "${PORT?}"  # Render injects this

MINIO_API_PORT="${PORT}"
MINIO_CONSOLE_PORT="${MINIO_CONSOLE_PORT:-9001}"

# Optional: create a dedicated app user for Django (recommended)
MINIO_APP_USER="${MINIO_APP_USER:-django}"
MINIO_APP_PASSWORD="${MINIO_APP_PASSWORD:-}"

export MC_CONFIG_DIR="/tmp/.mc"
MINIO_LOCAL_ENDPOINT="http://127.0.0.1:${MINIO_API_PORT}"

cleanup() {
  echo "[minio] Received signal, shutting down..."
  if [ "${MINIO_PID:-}" ]; then
    kill "${MINIO_PID}" 2>/dev/null || true
  fi
}
trap cleanup INT TERM

echo "[minio] Starting MinIO (API :${MINIO_API_PORT}, Console :${MINIO_CONSOLE_PORT})..."
/usr/bin/minio server /data \
  --address ":${MINIO_API_PORT}" \
  --console-address ":${MINIO_CONSOLE_PORT}" &
MINIO_PID="$!"

echo "[minio] Waiting for readiness via mc..."
# alias set validates connectivity; loop until MinIO is reachable
until mc alias set local "${MINIO_LOCAL_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null 2>&1; do
  sleep 1
done
until mc admin info local >/dev/null 2>&1; do
  sleep 1
done

# ------------------------------------------------------------
# FULL ACCESS POLICY (ALL buckets + objects)
# IMPORTANT: include BOTH bucket and object ARNs
# - arn:aws:s3:::*     (buckets)
# - arn:aws:s3:::*/*   (objects)  <-- required for PutObject
# ------------------------------------------------------------
cat >/tmp/full-access.json <<'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": [
        "arn:aws:s3:::*",
        "arn:aws:s3:::*/*"
      ]
    }
  ]
}
POLICY

echo "[minio] Ensuring policy exists: full-access"
mc admin policy create local full-access /tmp/full-access.json >/dev/null 2>&1 || true

# ------------------------------------------------------------
# Bucket init
# ------------------------------------------------------------
echo "[minio] Ensuring bucket exists: ${MINIO_BUCKET}"
mc mb -p "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

echo "[minio] Enforcing PRIVATE bucket (no anonymous access)"
mc anonymous set none "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

# ------------------------------------------------------------
# App user (recommended) OR attach policy to root user
# ------------------------------------------------------------
if [ -n "${MINIO_APP_PASSWORD}" ]; then
  echo "[minio] Ensuring app user exists: ${MINIO_APP_USER}"
  mc admin user add local "${MINIO_APP_USER}" "${MINIO_APP_PASSWORD}" >/dev/null 2>&1 || true

  echo "[minio] Attaching policy to app user: ${MINIO_APP_USER}"
  mc admin policy attach local full-access --user "${MINIO_APP_USER}" >/dev/null 2>&1 || true

  echo "[minio] Init complete. App user '${MINIO_APP_USER}' has full access to ALL buckets."
else
  echo "[minio] MINIO_APP_PASSWORD not set; attaching policy to root user '${MINIO_ROOT_USER}'"
  mc admin policy attach local full-access --user "${MINIO_ROOT_USER}" >/dev/null 2>&1 || true

  echo "[minio] Init complete. Root user '${MINIO_ROOT_USER}' has full access to ALL buckets."
fi

wait "${MINIO_PID}"
