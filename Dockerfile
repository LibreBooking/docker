FROM php:7-apache

RUN apt-get -y install gcc make autoconf libc-dev pkg-config \
    && pecl install timezonedb \
    && bash -c "echo extension=timezonedb.so > /usr/local/etc/php/conf.d/docker-php-ext-timezonedb.ini"

# Copy the entrypoint program
COPY ./entrypoint.sh /usr/local/bin/ 

# Customize
ARG LB_RELEASE
RUN set -ex; \
    # Install mysqli extension for php \
    docker-php-ext-install -j$(nproc) mysqli; \
    # Copy librebooking source code \
    mkdir /usr/src/lb; \
    curl \
      --fail \
      --silent \
      --location https://github.com/LibreBooking/app/archive/refs/tags/${LB_RELEASE}.tar.gz \
    | tar --extract --gzip --directory=/usr/src/lb --strip-components=1; \
    # Make entrypoint executable \
    chmod ugo+x /usr/local/bin/entrypoint.sh;

# Declarations
VOLUME /var/www/html
ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
