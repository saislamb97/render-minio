FROM minio/minio:latest

# Render provides PORT
# We build https://<hostport> dynamically
CMD ["sh", "-c", "minio console --address :${PORT} https://${MINIO_SERVER_HOSTPORT}"]
