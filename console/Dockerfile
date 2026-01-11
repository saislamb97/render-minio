FROM nginx:stable-alpine-slim

# Nginx official image supports envsubst templating from /etc/nginx/templates/*.template
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Remove default site
RUN rm -f /etc/nginx/conf.d/default.conf
