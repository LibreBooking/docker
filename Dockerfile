ARG VERSION_PHP=8.3
ARG VERSION_COMPOSER=lts

FROM composer:${VERSION_COMPOSER} AS comp
FROM php:${VERSION_PHP}-apache

# Labels
LABEL org.opencontainers.image.title="LibreBooking"
LABEL org.opencontainers.image.description="LibreBooking as a container"
LABEL org.opencontainers.image.url="https://github.com/librebooking/docker"
LABEL org.opencontainers.image.source="https://github.com/librebooking/docker"
LABEL org.opencontainers.image.licenses="GPL-3.0"
LABEL org.opencontainers.image.authors="colisee@hotmail.com"

# Copy entrypoint
COPY --chmod=755 entrypoint.sh /usr/local/bin/

# Create cron jobs
COPY --chown=www-data:www-data lb-jobs-cron /config/

# Copy composer
COPY --from=comp /usr/bin/composer /usr/bin/composer

# Update and install required debian packages
ENV DEBIAN_FRONTEND=noninteractive
RUN set -ex; \
    apt-get update; \
    apt-get upgrade --yes; \
    apt-get install --yes --no-install-recommends \
      cron \
      git \
      libjpeg-dev \
      libldap-dev \
      libpng-dev \
      libfreetype6-dev \
      unzip; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Customize
RUN set -ex; \
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
    { \
     echo 'RemoteIPHeader X-Real-IP'; \
     echo 'RemoteIPInternalProxy 10.0.0.0/8'; \
     echo 'RemoteIPInternalProxy 172.16.0.0/12'; \
     echo 'RemoteIPInternalProxy 192.168.0.0/16'; \
    } > /etc/apache2/conf-available/remoteip.conf; \
    a2enconf remoteip; \
    a2enmod rewrite; \
    a2enmod headers; \
    a2enmod remoteip; \
    docker-php-ext-configure gd --with-jpeg --with-freetype; \
    docker-php-ext-install mysqli gd ldap; \
    pecl install timezonedb; \
    docker-php-ext-enable timezonedb; \
    rm /etc/cron.d/e2scrub_all

# Get and customize librebooking
USER www-data
ARG APP_GH_REF
RUN set -ex; \
    curl \
      --fail \
      --silent \
      --location https://api.github.com/repos/librebooking/app/tarball/${APP_GH_REF} \
    | tar --extract --gzip --directory=/var/www/html --strip-components=1; \
    if [ -f /var/www/html/composer.json ]; then \
      sed \
        -i /var/www/html/composer.json \
        -e "s:\(.*\)nickdnk/graph-sdk\(.*\)7.0\(.*\):\1joelbutcher/facebook-graph-sdk\26.1\3:" ;\
      composer install; \
    fi; \
    sed \
      -i /var/www/html/database_schema/create-user.sql \
      -e "s:^DROP USER ':DROP USER IF EXISTS ':g" \
      -e "s:booked_user:schedule_user:g" \
      -e "s:localhost:%:g"; \
    if ! [ -d /var/www/html/tpl_c ]; then \
      mkdir /var/www/html/tpl_c; \
    fi

# Environment
USER       root
WORKDIR    /
VOLUME     /config
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD        ["apache2-foreground"]
