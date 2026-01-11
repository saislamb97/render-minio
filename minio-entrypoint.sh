#!/bin/sh
set -eu

: "${MINIO_ROOT_USER?}"
: "${MINIO_ROOT_PASSWORD?}"
: "${MINIO_BUCKET?}"
: "${PORT?}"

MINIO_API_PORT="${PORT}"
MINIO_CONSOLE_PORT="${MINIO_CONSOLE_PORT:-9001}"

export MC_CONFIG_DIR="/tmp/.mc"
LOCAL="http://127.0.0.1:${MINIO_API_PORT}"

# Start MinIO
minio server /data \
  --address ":${MINIO_API_PORT}" \
  --console-address ":${MINIO_CONSOLE_PORT}" &
PID="$!"

# Wait until ready
until mc alias set local "${LOCAL}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null 2>&1; do
  sleep 1
done

# Ensure bucket exists
mc mb -p "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

# -------------------------------------------------------------------
# 1) Ensure ROOT USER can write (fixes your PutObject 403 for admin)
# -------------------------------------------------------------------
cat >/tmp/root-full.json <<'POLICY'
{
  "Version":"2012-10-17",
  "Statement":[{
    "Effect":"Allow",
    "Action":["s3:*"],
    "Resource":["arn:aws:s3:::*","arn:aws:s3:::*/*"]
  }]
}
POLICY

mc admin policy create local root-full /tmp/root-full.json >/dev/null 2>&1 || true
mc admin policy attach local root-full --user "${MINIO_ROOT_USER}" >/dev/null 2>&1 || true

# -------------------------------------------------------------------
# 2) PUBLIC READ/WRITE bucket policy (anonymous can list/get/put/delete)
# -------------------------------------------------------------------
cat >/tmp/public-rw.json <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicListBucket",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${MINIO_BUCKET}"]
    },
    {
      "Sid": "PublicReadWriteObjects",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": ["arn:aws:s3:::${MINIO_BUCKET}/*"]
    }
  ]
}
POLICY

mc admin policy create local "${MINIO_BUCKET}-public-rw" /tmp/public-rw.json >/dev/null 2>&1 || true

# Attach to anonymous (critical)
mc admin policy attach local "${MINIO_BUCKET}-public-rw" --user anonymous >/dev/null 2>&1 || true

# Also explicitly set anonymous access (helps Console reflect non-private)
mc anonymous set public "local/${MINIO_BUCKET}" >/dev/null 2>&1 || true

echo "[minio] Bucket ${MINIO_BUCKET} is PUBLIC read/write (anonymous)."

wait "$PID"
