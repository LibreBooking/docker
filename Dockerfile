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

# Copy entrypoint scripts
COPY --chmod=755 bin /usr/local/bin/

# Create cron jobs
COPY --chown=www-data:www-data --chmod=0755 lb-jobs-cron /config/

# Copy composer
COPY --from=comp /usr/bin/composer /usr/bin/composer

# Update and install required debian packages
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008 # 'Pin versions in apt get install'
RUN <<EORUN
set -xeu
apt-get update
apt-get upgrade --yes
apt-get install --yes --no-install-recommends \
  cron \
  git \
  libjpeg-dev \
  libldap-dev \
  libpng-dev \
  libfreetype6-dev \
  unzip
apt-get clean
rm -rf /var/lib/apt/lists/*
EORUN

# Customize the http & php environment
RUN <<EORUN
set -xeu
cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
cat > /etc/apache2/conf-available/remoteip.conf <<EOF
RemoteIPHeader X-Real-IP
RemoteIPInternalProxy 10.0.0.0/8
RemoteIPInternalProxy 172.16.0.0/12
RemoteIPInternalProxy 192.168.0.0/16
EOF
a2enconf remoteip
a2enmod rewrite
a2enmod headers
a2enmod remoteip
docker-php-ext-configure gd --with-jpeg --with-freetype
docker-php-ext-install mysqli gd ldap
pecl install timezonedb
docker-php-ext-enable timezonedb
mkdir --parent /var/log/librebooking
chown --recursive www-data:root /var/log/librebooking
chmod --recursive g+rwx /var/log/librebooking
touch /usr/local/etc/php/conf.d/librebooking.ini
sed \
  -i /etc/apache2/ports.conf \
  -e 's/Listen 80/Listen 8080/' \
  -e 's/Listen 443/Listen 8443/'
sed \
  -i /etc/apache2/sites-available/000-default.conf \
  -e 's/<VirtualHost *:80>/<VirtualHost *:8080>/'
EORUN

# Get and customize librebooking
ARG APP_GH_REF
ARG APP_GH_ADD_SHA=false
RUN <<EORUN
set -xeu
LB_TARBALL_URL="https://api.github.com/repos/LibreBooking/librebooking/tarball/${APP_GH_REF}"
curl \
  --fail \
  --silent \
  --location ${LB_TARBALL_URL} \
| tar --extract --gzip --directory=/var/www/html --strip-components=1
if [ "${APP_GH_ADD_SHA}" = "true" ]; then
  LB_SHORT_SHA=""
  # TARBALL_FILENAME will be like the result of a `git describe` For
  # example: 'LibreBooking-librebooking-v4.1.0-126-g6cc8a4c.tar.gz' where
  # 'g6cc8a4c' is the short SHA prefixed with 'g'. So the short SHA is
  # '6cc8a4c'
  TARBALL_FILENAME=$(\
    curl \
      --head \
      --fail \
      --silent \
      --show-error \
      --location ${LB_TARBALL_URL} \
    | sed -nE 's/.*filename="?([^";]+)"?.*/\1/p')
  LB_SHORT_SHA=$(echo "${TARBALL_FILENAME}" | sed -E 's/.*-g([0-9a-f]+)\.tar\.gz/\1/')
  if [ -n "${LB_SHORT_SHA}" ]; then
    printf '%s\n' "${LB_SHORT_SHA}" > /var/www/html/config/version-suffix.txt
  else
    echo "ERROR determining the LB_SHORT_SHA value from TARBALL_FILENAME ${TARBALL_FILENAME}" >&2
    exit 1
  fi
fi
if [ -f /var/www/html/composer.json ]; then
  sed \
    -i /var/www/html/composer.json \
    -e "s:\(.*\)nickdnk/graph-sdk\(.*\)7.0\(.*\):\1joelbutcher/facebook-graph-sdk\26.1\3:"
  composer install
fi
sed \
  -i /var/www/html/database_schema/create-user.sql \
  -e "s:^DROP USER ':DROP USER IF EXISTS ':g" \
  -e "s:booked_user:schedule_user:g" \
  -e "s:localhost:%:g"
if ! [ -d /var/www/html/tpl_c ]; then
  mkdir /var/www/html/tpl_c
fi
mkdir /var/www/html/Web/uploads/reservation
EORUN

RUN <<EORUN
set -xeu
chown www-data:root \
  /var/www/html/config \
  /var/www/html/tpl_c \
  /var/www/html/Web/uploads/images \
  /var/www/html/Web/uploads/reservation \
  /usr/local/etc/php/conf.d/librebooking.ini
chmod g+rwx \
  /var/www/html/config \
  /var/www/html/tpl_c \
  /var/www/html/Web/uploads/images \
  /var/www/html/Web/uploads/reservation \
  /usr/local/etc/php/conf.d/librebooking.ini
chown --recursive www-data:root \
  /var/www/html/plugins
chmod --recursive g+rwx \
  /var/www/html/plugins
EORUN

# Environment
USER       www-data
WORKDIR    /
VOLUME     /config
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD        ["apache2-foreground"]
EXPOSE     8080
