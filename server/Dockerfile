FROM minio/minio:latest

# IMPORTANT:
# MinIO image already has ENTRYPOINT ["minio"]
# So CMD must ONLY contain MinIO arguments
CMD ["server", "/data", "--address", ":${PORT}"]
