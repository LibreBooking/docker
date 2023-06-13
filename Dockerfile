ARG  PHP_VERSION
FROM php:${PHP_VERSION}-apache

# Install composer
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

# Customize
ARG APP_GH_REF
ENV DEBIAN_FRONTEND=noninteractive

# Update debian packages
RUN set -ex; \
    apt-get update; \
    apt-get upgrade --yes; \
    apt-get install --yes --no-install-recommends git unzip; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Customize php environment
RUN set -ex; \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
    a2enmod rewrite; \
    docker-php-ext-install -j$(nproc) mysqli; \
    pecl install timezonedb; \
    docker-php-ext-enable timezonedb

# Get application and customize
USER www-data
RUN set -ex; \
    curl \
      --fail \
      --silent \
      --location https://github.com/LibreBooking/app/archive/${APP_GH_REF}.tar.gz \
    | tar --extract --gzip --directory=/var/www/html --strip-components=1; \
    if [ -f /var/www/html/composer.json ]; then \
      composer install --ignore-platform-req=ext-gd; \
    fi; \
    sed \
      -i /var/www/html/database_schema/create-user.sql \
      -e "s:^DROP USER ':DROP USER IF EXISTS ':g" \
      -e "s:booked_user:schedule_user:g" \
      -e "s:localhost:%:g"; \
    if ! [ -d /var/www/html/tpl_c ]; then \
      mkdir /var/www/html/tpl_c; \
    fi

# Final customization
USER root
RUN set -ex; \
    touch /app.log; \
    chown www-data:www-data /app.log; \
    mkdir /config

# Labels
LABEL org.opencontainers.image.title="LibreBooking"
LABEL org.opencontainers.image.description="LibreBooking as a container"
LABEL org.opencontainers.image.url="https://github.com/librebooking/docker"
LABEL org.opencontainers.image.source="https://github.com/librebooking/docker"
LABEL org.opencontainers.image.licenses="GPL-3.0"
LABEL org.opencontainers.image.authors="robin.alexander@netplus.ch"

# Copy the entrypoint program
COPY entrypoint.sh /usr/local/bin/ 
RUN  chmod +x /usr/local/bin/entrypoint.sh

# Declarations
VOLUME /config
ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]

