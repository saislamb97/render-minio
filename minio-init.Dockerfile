FROM minio/mc:latest
COPY minio-init.sh /minio-init.sh
RUN chmod +x /minio-init.sh
ENTRYPOINT ["/minio-init.sh"]
