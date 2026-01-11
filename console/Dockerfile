FROM nginx:stable-alpine-slim

# Nginx official image does envsubst on /etc/nginx/templates/*.template at startup
COPY default.conf.template /etc/nginx/templates/default.conf.template

# Export container DNS resolver into $RESOLVER before envsubst runs
RUN printf '%s\n' \
'#!/bin/sh' \
'export RESOLVER="$(awk '\''/^nameserver/{print $2; exit}'\'' /etc/resolv.conf)"' \
> /docker-entrypoint.d/14-resolver.envsh \
&& chmod +x /docker-entrypoint.d/14-resolver.envsh

# Remove default config if present
RUN rm -f /etc/nginx/conf.d/default.conf
