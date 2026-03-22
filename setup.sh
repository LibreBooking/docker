#!/bin/bash
# vim: set expandtab ts=2 sw=2 ai :

set -e
set -u
set -o pipefail
trap 'echo "Exit status $? at line $LINENO from: $BASH_COMMAND"' ERR

PS4='+ ${BASH_SOURCE:-}:${FUNCNAME[0]:-}:L${LINENO:-}:   '
set -x

apt-get update
apt-get upgrade --yes
apt-get install --yes --no-install-recommends \
  cron \
  libjpeg-dev \
  libldap-dev \
  libpng-dev \
  libfreetype6-dev \
  unzip
apt-get clean
rm -rf /var/lib/apt/lists/*

# Customize the http & php environment
cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
cat >/etc/apache2/conf-available/remoteip.conf <<EOF
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

if [ -f /var/www/html/composer.json ]; then
  sed \
    -i /var/www/html/composer.json \
    -e "s:\(.*\)nickdnk/graph-sdk\(.*\)7.0\(.*\):\1joelbutcher/facebook-graph-sdk\26.1\3:"
  composer install
  composer require pear/net_ldap2
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

chown --recursive www-data:root \
  /var/www/html/config \
  /var/www/html/plugins \
  /var/www/html/tpl_c \
  /var/www/html/Web/uploads/images \
  /var/www/html/Web/uploads/reservation \
  /usr/local/etc/php/conf.d/librebooking.ini
chmod --recursive g+rwx \
  /var/www/html/config \
  /var/www/html/plugins \
  /var/www/html/tpl_c \
  /var/www/html/Web/uploads/images \
  /var/www/html/Web/uploads/reservation \
  /usr/local/etc/php/conf.d/librebooking.ini
