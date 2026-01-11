FROM minio/minio:latest

# Console connects to the server using full HTTPS URL
CMD ["console", "--address", ":${PORT}", "https://${MINIO_SERVER_HOSTPORT}"]
