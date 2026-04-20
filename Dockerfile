ARG VERSION_PHP=8.3
ARG VERSION_COMPOSER=lts
ARG VERSION_GIT=2.52.0

FROM composer:${VERSION_COMPOSER} AS comp

# Get upstream
FROM alpine/git:${VERSION_GIT} AS upstream
ARG APP_GH_ADD_SHA=false
ARG APP_GH_REF=refs/heads/develop
ARG GIT_TREE
ARG UPSTREAM_URL="https://github.com/librebooking/librebooking"
WORKDIR /upstream

COPY --chmod=0755 scripts/clone.sh /usr/local/bin/clone.sh
RUN APP_GH_ADD_SHA=${APP_GH_ADD_SHA} \
     APP_GH_REF=${APP_GH_REF} \
     GIT_TREE=${GIT_TREE} \
     UPSTREAM_URL=${UPSTREAM_URL} \
     /usr/local/bin/clone.sh

# Build supercronic
FROM golang:trixie AS supercronic
RUN go install github.com/aptible/supercronic@v0.2.44

FROM php:${VERSION_PHP}-apache
# Labels
LABEL org.opencontainers.image.title="LibreBooking"
LABEL org.opencontainers.image.description="LibreBooking as a container"
LABEL org.opencontainers.image.url="https://github.com/librebooking/docker"
LABEL org.opencontainers.image.source="https://github.com/librebooking/docker"
LABEL org.opencontainers.image.licenses="GPL-3.0"
LABEL org.opencontainers.image.authors="colisee@hotmail.com"

# Copy bin scripts
COPY --chmod=0755 bin /usr/local/bin/

# Copy cron jobs
COPY --chown=www-data:www-data --chmod=0755 \
     lb-jobs-cron /config/

# Copy composer
COPY --from=comp /usr/bin/composer /usr/bin/composer

# Copy supercronic
COPY --from=supercronic \
     /go/bin/supercronic /usr/local/bin/supercronic

# Copy Librebooking
COPY --from=upstream \
     --chown=www-data:root --chmod=0775 \
     /upstream/ /var/www/html/

# Customize the system environment
ENV DEBIAN_FRONTEND=noninteractive
RUN bash /usr/local/bin/build_sys.sh

# Customize the image environment
USER       www-data:root
VOLUME     /config
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD        ["apache2-foreground"]
EXPOSE     8080

# Customize the application environment
RUN bash /usr/local/bin/build_app.sh
