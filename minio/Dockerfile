FROM minio/minio:latest

# Add MinIO Client (mc) for initialization
COPY --from=minio/mc:latest /usr/bin/mc /usr/bin/mc

# Entry script handles:
# - starting minio
# - creating bucket
# - enforcing private access (signed URLs)
COPY minio-entrypoint.sh /usr/local/bin/minio-entrypoint.sh
RUN chmod +x /usr/local/bin/minio-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/minio-entrypoint.sh"]
