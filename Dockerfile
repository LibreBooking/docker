FROM php:7-apache

# Copy the entrypoint program
COPY ./entrypoint.sh /usr/local/bin/ 

# Customize
ARG LB_RELEASE
RUN set -ex; \
    # Install mysqli extension for php \
    docker-php-ext-install -j$(nproc) mysqli; \
    # Copy librebooking source code \
    curl --output /usr/src/lb.tar.gz --location https://github.com/effgarces/BookedScheduler/archive/refs/tags/${LB_RELEASE-2.8.5.5}.tar.gz; \
    mkdir /usr/src/lb; \
    tar --extract --auto-compress --file=/usr/src/lb.tar.gz --directory=/usr/src/lb --strip-components=1; \
    rm /usr/src/lb.tar.gz; \
    # Make entrypoint executable \
    chmod ugo+x /usr/local/bin/entrypoint.sh;

# Declarations
VOLUME /var/www/html
ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]
