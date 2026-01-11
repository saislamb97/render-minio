FROM minio/minio:latest

ENTRYPOINT ["sh", "-c"]
CMD ["exec minio server /data --address :${PORT} --console-address :9090"]
