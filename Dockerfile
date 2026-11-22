ARG VERSION_PHP=8.5.12
ARG VERSION_COMPOSER=lts
ARG VERSION_GIT=2.52.0
ARG VERSION_PIE=bin

FROM composer:${VERSION_COMPOSER} AS comp
FROM ghcr.io/php/pie:${VERSION_PIE} AS pie

# Get upstream
FROM alpine/git:${VERSION_GIT} AS upstream
ARG APP_GH_ADD_SHA=false
ARG APP_GH_REF=""
ARG UPSTREAM_URL="https://github.com/librebooking/librebooking"
WORKDIR /upstream

RUN <<EOF
set -eu

git clone "${UPSTREAM_URL}" .
if [ -n "${APP_GH_REF}" ]; then
  git checkout "${APP_GH_REF#refs/heads/}"
fi

if [ "${APP_GH_ADD_SHA}" = "true" ]; then
  git describe --tags --long >config/custom-version.txt
fi
EOF

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

# Copy pie
COPY --from=pie /pie /usr/bin/pie

# Copy supercronic
COPY --from=supercronic \
     /go/bin/supercronic /usr/local/bin/supercronic

# Copy Librebooking
COPY --from=upstream \
     --chown=www-data:root --chmod=0775 \
     --exclude=.git* \
     /upstream/ /var/www/html/

# Customize the system environment
ENV DEBIAN_FRONTEND=noninteractive
RUN bash /usr/local/bin/build_sys.sh

# Customize the image environment
# hadolint ignore=DL3066
USER       www-data:root
VOLUME     /config
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD        ["apache2-foreground"]
EXPOSE     8080

# Customize the application environment
RUN bash /usr/local/bin/build_app.sh
