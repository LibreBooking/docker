ARG VERSION_PHP=8.3
ARG VERSION_COMPOSER=lts
ARG VERSION_GIT=2.52.0

FROM composer:${VERSION_COMPOSER} AS comp

# Get upstream
FROM alpine/git:${VERSION_GIT} AS upstream
ARG APP_GH_ADD_SHA=false
ARG APP_GH_REF=refs/heads/develop
ARG GIT_TREE=${APP_GH_REF##*/}
ARG UPSTREAM_URL="https://github.com/librebooking/librebooking"
WORKDIR /upstream
RUN <<EORUN
set -eux
git clone ${UPSTREAM_URL} /upstream
git checkout ${GIT_TREE}
if [ "${APP_GH_ADD_SHA}" = "true" ]; then
  git describe --tags --long > config/custom-version.txt
fi
rm -rf .git
EORUN

FROM php:${VERSION_PHP}-apache
# Labels
LABEL org.opencontainers.image.title="LibreBooking"
LABEL org.opencontainers.image.description="LibreBooking as a container"
LABEL org.opencontainers.image.url="https://github.com/librebooking/docker"
LABEL org.opencontainers.image.source="https://github.com/librebooking/docker"
LABEL org.opencontainers.image.licenses="GPL-3.0"
LABEL org.opencontainers.image.authors="colisee@hotmail.com"

# Copy entrypoint scripts
COPY --chmod=0755 bin /usr/local/bin/

# Create cron jobs
COPY --chown=www-data:www-data --chmod=0755 \
     lb-jobs-cron /config/

# Copy composer
COPY --from=comp /usr/bin/composer /usr/bin/composer

# Copy Librebooking
COPY --from=upstream \
     --chown=www-data:root --chmod=0775 \
     /upstream/ /var/www/html/

# Update and install required debian packages
ENV DEBIAN_FRONTEND=noninteractive
RUN --mount=type=bind,source=setup.sh,target=/tmp/setup.sh <<EORUN
bash /tmp/setup.sh
EORUN

# Environment
USER       www-data
WORKDIR    /
VOLUME     /config
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD        ["apache2-foreground"]
EXPOSE     8080
