# Render MinIO Deployment (API + Console)

This repository contains a **production-ready MinIO setup for Render**, split into **two services**:

1. **MinIO Server (API)** – public-facing, required for signed URLs
2. **MinIO Console** – public-facing UI, proxied via NGINX to the MinIO server

The setup is designed to work cleanly with **Render Web Services**, persistent disks, and environment-based configuration.

---

## 🧱 Architecture Overview

```
┌────────────────────┐
│   MinIO Console    │  (Public)
│   NGINX Proxy      │
│   :10000           │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│   MinIO Server     │  (Public)
│   API + Console    │
│   :PORT / :9090    │
│   Persistent Disk  │
└────────────────────┘
```

### Why two services?

* **Render assigns one public port per service**
* MinIO exposes **API + Console on separate ports**
* The console is exposed via **NGINX reverse proxy**
* The API remains directly accessible for **presigned URLs**

---

## 📂 Repository Structure

```bash
.
├── Dockerfile.minio          # MinIO server image
├── Dockerfile.console        # NGINX console proxy
├── minio-entrypoint.sh       # MinIO bootstrap & init logic
├── minio-console.conf.template  # NGINX config template
├── render.yaml               # Render infrastructure definition
└── README.md
```

---

## 🐳 Docker Images

### 1️⃣ MinIO Server (`Dockerfile.minio`)

* Based on `minio/minio:latest`
* Adds:

  * `wget` (for health checks)
  * `mc` (MinIO Client) for initialization
* Uses a **custom entrypoint** to:

  * Start MinIO
  * Wait for readiness
  * Create bucket
  * Enforce private access

```dockerfile
FROM minio/minio:latest

RUN microdnf install -y wget && microdnf clean all || true

COPY --from=minio/mc:latest /usr/bin/mc /usr/bin/mc
COPY minio-entrypoint.sh /usr/local/bin/minio-entrypoint.sh

RUN chmod +x /usr/local/bin/minio-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/minio-entrypoint.sh"]
```

---

### 2️⃣ MinIO Console Proxy (`Dockerfile.console`)

* Based on `nginx:stable-alpine-slim`
* Uses **NGINX templates** to inject environment variables
* Proxies WebSocket + HTTP traffic to MinIO Console

```dockerfile
FROM nginx:stable-alpine-slim

RUN rm -f /etc/nginx/conf.d/default.conf \
    /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh

COPY minio-console.conf.template /etc/nginx/templates/minio-console.conf.template
```

---

## ⚙️ MinIO Entrypoint Logic

`minio-entrypoint.sh` performs **safe, idempotent initialization**:

### What it does

1. Validates required environment variables
2. Starts MinIO (API + Console)
3. Waits for readiness
4. Configures `mc` alias
5. Creates bucket (if missing)
6. Enforces **private access**
7. Handles graceful shutdown

### Required environment variables

```bash
MINIO_ROOT_USER
MINIO_ROOT_PASSWORD
MINIO_BUCKET
PORT                # Injected by Render
```

---

## 🌐 NGINX Console Proxy

`minio-console.conf.template`:

* Uses environment variables injected by Render
* Supports:

  * WebSockets (required for MinIO Console)
  * Large uploads
  * Long-lived connections

```nginx
upstream minio_console {
    server ${MINIO_HOST}:${MINIO_CONSOLE_PORT};
    keepalive 32;
}

server {
    listen ${PORT};

    location / {
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_pass http://minio_console;
    }
}
```

---

## 🚀 Render Deployment (`render.yaml`)

### Service 1: MinIO Server

```yaml
- type: web
  name: minio-server
  runtime: docker
  dockerfilePath: ./Dockerfile.minio
  disk:
    name: data
    mountPath: /data
  envVars:
    - key: MINIO_ROOT_USER
      value: admin
    - key: MINIO_ROOT_PASSWORD
      sync: false
    - key: MINIO_BUCKET
      value: nudgytai
    - key: MINIO_CONSOLE_PORT
      value: "9090"
```

* Public API access
* Persistent disk at `/data`
* Required for signed URLs

---

### Service 2: MinIO Console

```yaml
- type: web
  name: minio-console
  runtime: docker
  dockerfilePath: ./Dockerfile.console
  envVars:
    - key: PORT
      value: "10000"
    - key: MINIO_HOST
      fromService:
        name: minio-server
        type: web
        property: host
    - key: MINIO_CONSOLE_PORT
      value: "9090"
```

* Public UI
* Proxies traffic to `minio-server:9090`

---

## 🔐 Security Notes

* Buckets are **PRIVATE by default**
* No anonymous access is allowed
* All access should be via:

  * MinIO credentials
  * Presigned URLs

---

## ✅ Use Cases

* S3-compatible object storage
* Signed upload/download URLs
* Private media storage
* Backend-friendly blob storage

---

## 🧪 Local Development (Optional)

```bash
docker build -f Dockerfile.minio -t minio-server .
docker build -f Dockerfile.console -t minio-console .
```