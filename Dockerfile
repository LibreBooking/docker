FROM php:8.1-apache

# Copy the entrypoint program
COPY ./entrypoint.sh /usr/local/bin/ 

# Customize
ARG LB_RELEASE
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
      --location https://github.com/LibreBooking/app/archive/refs/tags/${LB_RELEASE}.tar.gz \
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
