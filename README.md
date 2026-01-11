# Render MinIO Deployment

This repository provides a **ready-to-deploy MinIO + MinIO Console setup for Render** using Docker and Render’s native `render.yaml` configuration.

It is designed to:

* Run **MinIO Object Storage** as a web service
* Expose the **MinIO Console UI** behind NGINX
* Automatically initialize buckets and policies on startup
* Work cleanly with Render’s infrastructure and environment variables

---

## Overview

**What’s included:**

* MinIO server container
* MinIO Console (NGINX reverse proxy)
* Startup script for bucket creation & access policies
* Render service configuration

**Key features:**

* Zero manual setup after deployment
* Optional public or private bucket
* Console accessible via HTTPS
* Render-friendly (no Docker Compose required)

---

## Architecture

```
┌──────────────┐
│   Internet   │
└──────┬───────┘
       │
┌──────▼────────┐
│ Render Web    │
│ Service       │
│               │
│  ┌─────────┐  │
│  │  NGINX  │──┼──► MinIO Console (9001)
│  └─────────┘  │
│       │        │
│       ▼        │
│   MinIO Server │──► Object Storage (9000)
└────────────────┘
```

---

## Repository Structure

```
render-minio/
├── Dockerfile.minio              # MinIO server image
├── Dockerfile.console            # NGINX-based MinIO console
├── minio-entrypoint.sh           # Startup & initialization script
├── minio-console.conf.template   # NGINX config template
├── render.yaml                   # Render service definition
└── README.md
```

---

## Files Explained

### `Dockerfile.minio`

* Uses the official `minio/minio` image
* Installs the MinIO client (`mc`)
* Copies a custom entrypoint script
* Launches MinIO via `minio-entrypoint.sh`

---

### `minio-entrypoint.sh`

This script runs on container startup and:

1. Starts the MinIO server
2. Waits until MinIO is ready
3. Configures a local alias using root credentials
4. Creates a bucket if it doesn’t exist
5. Optionally makes the bucket **public**
6. Keeps the MinIO process running

**Supported behaviors:**

* Idempotent bucket creation
* Safe to restart
* Controlled via environment variables

---

### `Dockerfile.console`

* Based on `nginx:alpine`
* Removes default config
* Uses an NGINX template for Render
* Proxies traffic to the MinIO Console

---

### `minio-console.conf.template`

NGINX reverse proxy configuration:

* WebSocket support
* Long-lived connections
* Forwards traffic to MinIO Console on port `9001`

---

### `render.yaml`

Defines a **single Render web service**:

* Uses Docker
* Exposes ports `9000` (MinIO) and `9001` (Console)
* Configures all required environment variables

---

## Environment Variables

These are required (or optional) in Render:

### Required

| Variable              | Description           |
| --------------------- | --------------------- |
| `MINIO_ROOT_USER`     | MinIO admin username  |
| `MINIO_ROOT_PASSWORD` | MinIO admin password  |
| `MINIO_BUCKET`        | Bucket to auto-create |

### Optional

| Variable              | Default | Description                       |
| --------------------- | ------- | --------------------------------- |
| `MINIO_PUBLIC_BUCKET` | `false` | Make bucket public (anonymous RW) |
| `MINIO_CONSOLE_PORT`  | `9001`  | Console port                      |
| `MINIO_SERVER_URL`    | auto    | External MinIO URL                |

---

## Deployment on Render

### 1. Create a New Web Service

* Choose **“Deploy from GitHub”**
* Select this repository
* Render will automatically detect `render.yaml`

### 2. Set Environment Variables

Add the required variables in the Render dashboard.

### 3. Deploy 🚀

Once deployed:

* MinIO API:

  ```
  https://<your-service>.onrender.com
  ```
* MinIO Console:

  ```
  https://<your-service>.onrender.com
  ```

---

## Accessing MinIO

### Console Login

Use:

* **Username:** `MINIO_ROOT_USER`
* **Password:** `MINIO_ROOT_PASSWORD`