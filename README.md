# Render MinIO (Server + Console)

This repository deploys **MinIO on Render** as **two separate web services**:

* **MinIO Server** → S3-compatible object storage (used by Django)
* **MinIO Console** → Web UI for administration

This setup:

* Uses **Render-generated public URLs**
* Uses **one persistent disk**
* Requires **no nginx, no sidecars, no AIStor**
* Works with **django-storages[s3]**

---

## Architecture

```
┌─────────────────────┐
│  Django App(s)      │
│  (django-storages)  │
└─────────┬───────────┘
          │  S3 API
          ▼
┌─────────────────────────────┐
│  MinIO Server (public)      │
│  https://minio-server-*.onrender.com
│  • Persistent Disk (/data) │
│  • Buckets + Objects       │
└─────────┬──────────────────┘
          │
          ▼
┌─────────────────────────────┐
│  MinIO Console (public UI)  │
│  https://minio-console-*.onrender.com
│  • Admin / Buckets / Users │
└─────────────────────────────┘
```

---

## Repository Structure

```
render-minio/
├── server/
│   └── Dockerfile        # MinIO S3 API service
├── console/
│   └── Dockerfile        # MinIO Web Console service
└── render.yaml           # Render Blueprint (deploys both)
```

---

## Deployment (Render)

### 1. Create a new Render Blueprint

* Go to **Render Dashboard → New → Blueprint**
* Select this GitHub repository
* Render will deploy **two web services automatically**

---

### 2. Services created

#### `minio-server`

* Public S3 API endpoint
* Has a **persistent disk** mounted at `/data`
* Stores all buckets and objects

#### `minio-console`

* Public web UI for MinIO
* No disk
* Connects to `minio-server`

---

### 3. Admin credentials

Render automatically generates these on **minio-server**:

* `MINIO_ROOT_USER`
* `MINIO_ROOT_PASSWORD`

You can find them in:

```
Render Dashboard → minio-server → Environment
```

These credentials are:

* Console login credentials
* S3 access key & secret key

---

## Access URLs

After deploy, Render will give you two URLs:

```
https://minio-server-xxxx.onrender.com   ← S3 API (use in Django)
https://minio-console-yyyy.onrender.com  ← Admin Console
```

---

## Initial Setup (Once)

### 1. Log into the console

Open:

```
https://minio-console-yyyy.onrender.com
```

Login using:

* Username = `MINIO_ROOT_USER`
* Password = `MINIO_ROOT_PASSWORD`

---

### 2. Create a bucket

Create a bucket for Django media, for example:

```
nudgytai
```

(Optional)
Set bucket to **public read** if you want direct media URLs.

---

## Django Integration (`django-storages[s3]`)

### Install

```bash
pip install django-storages[s3]
```

---

### Django Environment Variables

```env
USE_MINIO=true

MINIO_ENDPOINT_URL=https://minio-server-xxxx.onrender.com
MINIO_BUCKET=nudgytai

MINIO_ACCESS_KEY=<MINIO_ROOT_USER>
MINIO_SECRET_KEY=<MINIO_ROOT_PASSWORD>
```

(You can later replace root credentials with a dedicated MinIO user.)

---

### Media URL behavior

With a public bucket:

```
https://minio-server-xxxx.onrender.com/nudgytai/path/to/file.jpg
```

---

## Local Testing (Optional)

### MinIO Server

```bash
docker run -p 9000:9000 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  -v ./data:/data \
  minio/minio server /data
```

### MinIO Console

```bash
docker run -p 9001:9001 \
  minio/minio console --address :9001 http://localhost:9000
```

---

## Notes & Limitations

* This setup runs **one MinIO server instance**
* Do **not scale horizontally** (single disk)
* Ideal for:

  * Django media storage
  * Internal apps
  * MVPs and production workloads that don’t require HA