# MinIO Stack (Render) — Signed URLs, Private Buckets

A **production-ready MinIO setup** designed for use with Django (or any S3-compatible client), deployed on **Render**, using:

* ✅ **Private buckets**
* ✅ **Signed (pre-signed) URLs**
* ✅ **Only 2 services** (no init worker)
* ✅ **Public MinIO API** (required for browser downloads)
* ✅ **Separate public Console via Nginx**
* ✅ Clean separation from application code (Django lives elsewhere)

---

## Architecture Overview

```text
┌────────────────────┐
│   Django Backend   │
│  (separate repo)   │
└─────────┬──────────┘
          │  S3 API (signed URLs)
          ▼
┌──────────────────────────────┐
│  MinIO API (public endpoint) │
│  - Private bucket            │
│  - Pre-signed URLs           │
└─────────┬────────────────────┘
          │
          ▼
┌────────────────────┐
│   Persistent Disk  │
│     /data          │
└────────────────────┘

┌──────────────────────────────┐
│ MinIO Console (Nginx proxy)  │
│ Public UI → internal :9090   │
└──────────────────────────────┘
```

---

## Repository Structure

```text
minio-stack/
├── render.yaml
│
├── minio/
│   ├── Dockerfile
│   └── minio-entrypoint.sh
│
└── console/
    ├── Dockerfile
    └── minio-console.conf.template
```

---

## Services (Exactly 2)

### 1️⃣ `minio-server`

* Runs the **MinIO API**
* Publicly reachable (required for signed URLs)
* Automatically:

  * Starts MinIO
  * Creates the bucket (idempotent)
  * Ensures the bucket is **PRIVATE**
* Uses a **persistent disk** mounted at `/data`

### 2️⃣ `minio-console`

* Lightweight **Nginx reverse proxy**
* Exposes MinIO Console safely
* Proxies internally to `minio-server:9090`
* Handles WebSockets and large uploads correctly

---

## Bucket Policy & Security Model

* Bucket is **private**
* ❌ No anonymous access
* ✅ All downloads happen via **time-limited signed URLs**
* Django (or any backend) controls access

This is the **recommended production model**.

---

## Deployment (Render)

1. Create a new **Blueprint** on Render
2. Connect this repository
3. Deploy using `render.yaml`
4. Set secrets in the Render dashboard:

   * `MINIO_ROOT_PASSWORD`

After deploy:

* MinIO API → Render-generated service URL
* MinIO Console → separate Render URL

---

## Environment Variables (MinIO)

### Required

| Variable              | Description                      |
| --------------------- | -------------------------------- |
| `MINIO_ROOT_USER`     | Admin username                   |
| `MINIO_ROOT_PASSWORD` | Admin password (store as secret) |
| `MINIO_BUCKET`        | Bucket to auto-create            |
| `PORT`                | Injected by Render               |

### Optional

| Variable             | Description                             |
| -------------------- | --------------------------------------- |
| `MINIO_CONSOLE_PORT` | Internal console port (default: `9090`) |

---

## How Initialization Works (No 3rd Service)

Instead of a separate init worker:

* `minio-entrypoint.sh`:

  * Starts MinIO
  * Waits for health check
  * Runs `mc` commands:

    * create bucket
    * remove anonymous policies
  * Keeps MinIO running

This keeps the stack **simple and reliable**.

---

## Django Integration (High-Level)

Django lives in a **separate repo/service** and connects via environment variables only.

### Django uses:

* `django-storages`
* `boto3`
* MinIO **public API URL**
* **Signed URLs** for access

### Result:

* Django uploads files
* Django returns signed URLs
* Browser downloads directly from MinIO
* Django does **not** serve media files

---

## Example Signed URL

```text
https://<minio-api-domain>/nudgytai/media/file.png
  ?X-Amz-Algorithm=AWS4-HMAC-SHA256
  &X-Amz-Credential=...
  &X-Amz-Signature=...
  &X-Amz-Expires=3600
```

* Valid for a limited time
* Cannot be guessed
* Bucket remains private

---

## Health Checks

### MinIO API

```
GET /minio/health/live
GET /minio/health/ready
```

### Example

```bash
curl https://<minio-server-url>/minio/health/live
```