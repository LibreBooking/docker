FROM php:7-apache

# Copy the entrypoint program
COPY ./entrypoint.sh /usr/local/bin/ 

# Customize
ARG APP_GH_REF
ENV DEBIAN_FRONTEND=noninteractive
RUN set -ex; \
    # Update debian packages
    apt-get update; \
    apt-get upgrade --yes; \
    # Install composer
    apt-get install --yes --no-install-recommends git unzip; \
    # Install mysqli extension for php
    docker-php-ext-install -j$(nproc) mysqli; \
    # Copy librebooking source code
    mkdir /usr/src/lb; \
    curl \
      --fail \
      --silent \
      --location https://github.com/LibreBooking/app/archive/${APP_GH_REF}.tar.gz \
    | tar --extract --gzip --directory=/usr/src/lb --strip-components=1; \
    # Make entrypoint executable
    chmod ugo+x /usr/local/bin/entrypoint.sh; \
    # Set a php.ini file as recommended by the authors of php:?-apache
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
    # Clear apt cache
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Declarations
VOLUME /var/www/html
ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]

# Labels
LABEL org.opencontainers.image.title="LibreBooking"
LABEL org.opencontainers.image.description="LibreBooking as a container"
LABEL org.opencontainers.image.url="https://github.com/librebooking/docker"
LABEL org.opencontainers.image.source="https://github.com/librebooking/docker"
LABEL org.opencontainers.image.licenses="GPL-3.0"
LABEL org.opencontainers.image.authors="robin.alexander@netplus.ch"