#!/bin/bash

set -ex

file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    local varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    local fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
    if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    if [ -n "${varValue}" ]; then
        export "$var"="${varValue}"
    elif [ -n "${fileVarValue}" ]; then
        export "$var"="$(cat "${fileVarValue}")"
    elif [ -n "${def}" ]; then
        export "$var"="$def"
    fi
    unset "$fileVar"
}

file_env LB_INSTALL_PWD
file_env LB_DB_USER_PWD

# First-time volume initialization
if ! test -d /var/www/html/config; then
  echo "First-time initialization"

  # Copy librebooking application
  cp -r /usr/src/lb/* /var/www/html/
  cp /var/www/html/config/config.dist.php /var/www/html/config/config.php

  # Set timezone
  if test -f /usr/share/zoneinfo/${TZ}; then
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
    pecl install timezonedb

    INI_FILE="/usr/local/etc/php/conf.d/librebooking.ini"
    echo "[date]" > ${INI_FILE}
    echo "date.timezone=\"${TZ}\"" >> ${INI_FILE}
    echo "" >> ${INI_FILE}
    echo "extension=timezonedb.so" >> ${INI_FILE}
  fi

  # Fixes
  ## File create-user.sql
  sed -i /usr/src/lb/database_schema/create-user.sql -e "s:^DROP USER ':DROP USER IF EXISTS ':g"
  sed -i /usr/src/lb/database_schema/create-user.sql -e "s:booked_user:schedule_user:g"
  sed -i /usr/src/lb/database_schema/create-user.sql -e "s:localhost:%:g"

  ## Missing directory tpl_c
  if ! test -d /var/www/html/tpl_c; then
    mkdir /var/www/html/tpl_c
    chown www-data:www-data /var/www/html/tpl_c
  fi

  # Set initial configuration
  sed -i /var/www/html/config/config.php -e "s:\(\['registration.captcha.enabled'\]\) = 'true':\1 = 'false':"
  sed -i /var/www/html/config/config.php -e "s:\(\['database'\]\['user'\]\) = '.*':\1 = '${LB_DB_USER}':"
  sed -i /var/www/html/config/config.php -e "s:\(\['database'\]\['password'\]\) = '.*':\1 = '${LB_DB_USER_PWD}':"
  sed -i /var/www/html/config/config.php -e "s:\(\['database'\]\['hostspec'\]\) = '127.0.0.1':\1 = '${LB_DB_HOST}':"
  sed -i /var/www/html/config/config.php -e "s:\(\['database'\]\['name'\]\) = '.*':\1 = '${LB_DB_NAME}':"
  sed -i /var/www/html/config/config.php -e "s:\(\['install.password'\]\) = '.*':\1 = '${LB_INSTALL_PWD}':"
  sed -i /var/www/html/config/config.php -e "s:\(\['default.timezone'\]\) = '.*':\1 = '${TZ}':"
  sed -i /var/www/html/config/config.php -e "s:\(\['logging'\]\['folder'\]\) = '/var/log/librebooking/log':\1 = '/var/log/librebooking':"
  sed -i /var/www/html/config/config.php -e "s:\(\['logging'\]\['level'\]\) = 'debug':\1 = 'none':"
fi

# Fixes
## Missing log directory
if ! test -d /var/log/librebooking; then
  mkdir /var/log/librebooking
  chown www-data:www-data /var/log/librebooking
  touch /var/log/librebooking/app.log
fi

# Install and run composer
if ! test -f /var/www/html/composer-setup.php; then
  pushd /var/www/html
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
  php composer-setup.php
  php -r "unlink('composer-setup.php');"
  php composer.phar install --ignore-platform-req=ext-gd
  chown -R www-data:www-data /var/www/html
  popd
fi

exec "$@"
