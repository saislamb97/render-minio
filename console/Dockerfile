FROM minio/minio:latest

# The console connects to the MinIO server via its public/internal URL
# Render injects PORT automatically
CMD ["sh", "-c", "minio console --address :${PORT} ${MINIO_SERVER_URL}"]
