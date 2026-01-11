FROM minio/minio:latest

# Render provides PORT automatically
# We bind the S3 API to $PORT
CMD ["sh", "-c", "minio server /data --address :${PORT}"]
