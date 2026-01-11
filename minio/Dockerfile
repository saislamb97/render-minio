FROM minio/minio:latest

# Add mc for initialization
COPY --from=minio/mc:latest /usr/bin/mc /usr/bin/mc

# Init + entrypoint
COPY minio-entrypoint.sh /usr/local/bin/minio-entrypoint.sh
RUN chmod +x /usr/local/bin/minio-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/minio-entrypoint.sh"]
