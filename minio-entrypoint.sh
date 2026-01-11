#!/bin/sh
set -eu

: "${MINIO_ROOT_USER?}"
: "${MINIO_ROOT_PASSWORD?}"
: "${MINIO_BUCKET?}"
: "${PORT?}"  # Render injects this

MINIO_API_PORT="${PORT}"
MINIO_CONSOLE_PORT="${MINIO_CONSOLE_PORT:-9001}"

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

echo "[minio] Waiting for readiness..."
until wget -qO- "${MINIO_LOCAL_ENDPOINT}/minio/health/ready" >/dev/null 2>&1; do
  sleep 2
done

echo "[minio] Configuring mc alias..."
mc alias set local "${MINIO_LOCAL_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null

# --- OPTIONAL: if you REALLY want a policy, make it correct ---
cat >/tmp/full-access.json <<EOF
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
EOF

mc admin policy create local full-access /tmp/full-access.json >/dev/null 2>&1 || true
mc admin policy attach local full-access --user "${MINIO_ROOT_USER}" >/dev/null 2>&1 || true
# --- OR better: delete the 2 lines above for root user ---

echo "[minio] Ensuring bucket exists: ${MINIO_BUCKET}"
mc mb -p "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

echo "[minio] Enforcing PRIVATE access (no anonymous access)"
mc anonymous set none "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

echo "[minio] Init complete."
wait "${MINIO_PID}"
