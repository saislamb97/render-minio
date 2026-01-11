FROM minio/minio:latest

# Render gives your web service a single $PORT to listen on.
# Bind S3 API to $PORT and bind console to a fixed internal port (9090).
# MinIO supports choosing a specific console port via --console-address. :contentReference[oaicite:3]{index=3}
ENTRYPOINT ["sh", "-c"]
CMD ["exec minio server /data --address :${PORT} --console-address :9090"]
