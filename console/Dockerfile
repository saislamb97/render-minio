FROM nginx:stable-alpine-slim

# Remove the default site and optional ipv6 script
RUN rm -f /etc/nginx/conf.d/default.conf \
    /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh

# Nginx envsubst template support
COPY minio-console.conf.template /etc/nginx/templates/minio-console.conf.template
