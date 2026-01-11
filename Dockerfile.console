FROM nginx:stable-alpine-slim

RUN rm -f /etc/nginx/conf.d/default.conf \
    /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh

COPY minio-console.conf.template /etc/nginx/templates/minio-console.conf.template
