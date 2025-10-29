# Production Nginx with SSL and security headers
FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/

# Create non-root user
RUN addgroup -g 1000 -S nginx && \
    adduser -S -D -H -u 1000 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Change ownership
RUN chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx

USER nginx

EXPOSE 8080