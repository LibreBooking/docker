#!/bin/bash

set -ex

DFT_LOG_FLR="/var/log/librebooking/log"
DFT_LOG_LEVEL="debug"
DFT_LOG_SQL=false

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

install() {

  # Clean directory
  rm -rf /var/www/html/*

  # Copy librebooking application
  cp -r /usr/src/lb/* /var/www/html/

  # Install and run composer
  if ! test -f /var/www/html/composer-setup.php; then
    pushd /var/www/html
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    php composer.phar install --ignore-platform-req=ext-gd
    popd
  fi
}

# First-time volume initialization
if ! test -d /var/www/html/config; then
  echo "First-time initialization"

  # Install application
  install

  # Fixes
  ## File create-user.sql
  sed \
    -i /var/www/html/database_schema/create-user.sql \
    -e "s:^DROP USER ':DROP USER IF EXISTS ':g" \
    -e "s:booked_user:schedule_user:g" \
    -e "s:localhost:%:g"

  ## Missing directory tpl_c
  if ! test -d /var/www/html/tpl_c; then
    mkdir /var/www/html/tpl_c
    chown www-data:www-data /var/www/html/tpl_c
  fi

  # Set initial configuration
  file_env LB_INSTALL_PWD
  file_env LB_DB_USER_PWD

  LB_LOG_FOLDER=${LB_LOG_FOLDER:-${DFT_LOG_FLR}}
  LB_LOG_LEVEL=${LB_LOG_LEVEL:-${DFT_LOG_LEVEL}}
  LB_LOG_SQL=${LB_LOG_SQL:-${DFT_LOG_SQL}}

  cp /var/www/html/config/config.dist.php /var/www/html/config/config.php
  sed \
    -i /var/www/html/config/config.php \
    -e "s:\(\['registration.captcha.enabled'\]\) = 'true':\1 = 'false':" \
    -e "s:\(\['database'\]\['user'\]\) = '.*':\1 = '${LB_DB_USER}':" \
    -e "s:\(\['database'\]\['password'\]\) = '.*':\1 = '${LB_DB_USER_PWD}':" \
    -e "s:\(\['database'\]\['hostspec'\]\) = '127.0.0.1':\1 = '${LB_DB_HOST}':" \
    -e "s:\(\['database'\]\['name'\]\) = '.*':\1 = '${LB_DB_NAME}':" \
    -e "s:\(\['install.password'\]\) = '.*':\1 = '${LB_INSTALL_PWD}':" \
    -e "s:\(\['default.timezone'\]\) = '.*':\1 = '${TZ}':" \
    -e "s:\(\['logging'\]\['folder'\]\) = '/var/log/librebooking/log':\1 = '${LB_LOG_FOLDER}':" \
    -e "s:\(\['logging'\]\['level'\]\) = 'debug':\1 = '${LB_LOG_LEVEL}':" \
    -e "s:\(\['logging'\]\['sql'\]\) = 'false':\1 = '${LB_LOG_SQL}':"

  # Change ownership
  chown -R www-data:www-data /var/www/html
fi

# Upgrade invocation
if test "${1}" = "upgrade"; then

  ## Backup existing config.php
  cp /var/www/html/config/config.php /tmp/config.php

  ## Install application
  install

  ## Restore original config.php
  mv /tmp/config.php /var/www/html/config/config.php

  ## Change ownership
  chown -R www-data:www-data /var/www/html

else
# Not an upgrade invocation

  ## Set timezone
  if test -f /usr/share/zoneinfo/${TZ}; then
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime

    INI_FILE="/usr/local/etc/php/conf.d/librebooking.ini"
    echo "[date]" > ${INI_FILE}
    echo "date.timezone=\"${TZ}\"" >> ${INI_FILE}
    echo "" >> ${INI_FILE}
    echo "extension=timezonedb.so" >> ${INI_FILE}
  fi

  ## Get log directory
  log_flr=$(grep \
    -e "\['logging'\]\['folder'\]" \
    /var/www/html/config/config.php \
    | cut -d " " -f3 | cut -d "'" -f2)
  log_flr=${log_flr:-${DFT_LOG_FLR}}

  ## Missing log directory
  if ! test -d "${log_flr}"; then
    mkdir -p "${log_flr}"
    chown -R www-data:www-data "${log_flr}"
  fi

  ## Missing log file
  if ! test -f "${log_flr}/app.log"; then
    touch "${log_flr}/app.log"
    chown www-data:www-data "${log_flr}/app.log"
  fi

  ## Workaround for configure.php
  touch /app.log
  chown www-data:www-data /app.log

  exec "$@"
fi
