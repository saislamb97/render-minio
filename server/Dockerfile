FROM minio/minio:latest

# Render exposes one port; we'll use 9000 for S3 API (public on this service)
# and 9090 for the console (internal, proxied by the console service).
EXPOSE 9000 9090

# Use a shell so ${PORT} etc are expanded, then exec so signals work properly.
ENTRYPOINT ["sh", "-c"]
CMD ["exec minio server /data --address ${HOST:-0.0.0.0}:${PORT:-9000} --console-address ${HOST:-0.0.0.0}:${CONSOLE_PORT:-9090}"]
