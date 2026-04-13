#!/bin/bash
# vim: set expandtab ts=2 sw=2 ai :

set -e
set -u
set -o pipefail
trap 'echo "Exit status $? at line $LINENO from: $BASH_COMMAND"' ERR

PS4='+ ${BASH_SOURCE:-}:${FUNCNAME[0]:-}:L${LINENO:-}:   '
set -x

# Install dependencies
apt-get update
apt-get upgrade --yes
apt-get install --yes --no-install-recommends \
  libjpeg-dev \
  libldap-dev \
  libpng-dev \
  libfreetype6-dev \
  unzip
apt-get clean

# Customize Apache
cat >/etc/apache2/conf-available/remoteip.conf <<EOF
RemoteIPHeader X-Real-IP
RemoteIPInternalProxy 10.0.0.0/8
RemoteIPInternalProxy 172.16.0.0/12
RemoteIPInternalProxy 192.168.0.0/16
EOF

sed \
  -i /etc/apache2/ports.conf \
  -e 's/Listen 80/Listen 8080/' \
  -e 's/Listen 443/Listen 8443/'
sed \
  -i /etc/apache2/sites-available/000-default.conf \
  -e 's/<VirtualHost \*:80>/<VirtualHost \*:8080>/'

a2enconf remoteip
a2enmod rewrite
a2enmod headers
a2enmod remoteip

# Customize php
cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
touch /usr/local/etc/php/conf.d/librebooking.ini

docker-php-ext-configure gd --with-jpeg --with-freetype
docker-php-ext-install mysqli gd ldap
pecl install timezonedb
docker-php-ext-enable timezonedb

# Customize log
mkdir --parent /var/log/librebooking
chown www-data:root /var/log/librebooking
chmod g+rwx /var/log/librebooking

# Customize permissions
chown www-data:root \
  /var/www \
  /usr/local/etc/php/conf.d/librebooking.ini
chmod g+rwx \
  /var/www \
  /usr/local/etc/php/conf.d/librebooking.ini
chown --recursive www-data:root \
  /etc/apache2/sites-available
chmod --recursive g+rwx \
  /etc/apache2/sites-available
