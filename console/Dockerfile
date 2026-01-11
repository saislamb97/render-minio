FROM nginx:stable-alpine-slim

# The official nginx image runs envsubst on /etc/nginx/templates/*.template
# and writes the result to /etc/nginx/conf.d/*.conf on container start. :contentReference[oaicite:1]{index=1}
COPY default.conf.template /etc/nginx/templates/default.conf.template

# Remove the default site config if present
RUN rm -f /etc/nginx/conf.d/default.conf
