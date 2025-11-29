#!/bin/bash

set -ex

# Constants
readonly DFT_LOGGING_FLR="/var/log/librebooking"
readonly DFT_LOGGING_LEVEL="none"
readonly DFT_LOGGING_SQL=false
readonly DFT_APP_PATH=""

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

# Exit if incompatible mount (images prior to V2)
if [ "$(mount | grep /var/www/html)" = "/var/www/html" ]; then
  echo "The volume must be mapped to container directory /config" >2
  exit 1
fi

# Initialize variables
file_env LB_INSTALL_PWD
file_env LB_DATABASE_PASSWORD

LB_LOGGING_FOLDER=${LB_LOGGING_FOLDER:-${DFT_LOGGING_FLR}}
LB_LOGGING_LEVEL=${LB_LOGGING_LEVEL:-${DFT_LOGGING_LEVEL}}
LB_LOGGING_SQL=${LB_LOGGING_SQL:-${DFT_LOGGING_SQL}}
APP_PATH=${APP_PATH:-${DFT_APP_PATH}}

# If volume was used with images older than v2, then archive useless files
pushd /config
if [ -d Web ]; then
  mkdir archive
  mv $(ls --ignore=archive) archive
  if [ -f archive/config/config.php ]; then
    cp archive/config/config.php config.php
  fi
fi
popd

# No configuration file inside directory /config
if ! [ -f /config/config.php ]; then
  echo "Initialize file config.php"
  cp /var/www/html/config/config.dist.php /config/config.php

  ## Set primary configuration settings
  sed \
    -i /config/config.php \
    -e "s:\(\['registration.captcha.enabled'\].*\) 'true':\1 'false':" \
    -e "s:\(\['database'\]\['user'\].*\) '.*':\1 '${LB_DATABASE_USER}':" \
    -e "s:\(\['database'\]\['password'\].*\) '.*':\1 '${LB_DATABASE_PASSWORD}':" \
    -e "s:\(\['database'\]\['name'\].*\) '.*':\1 '${LB_DATABASE_NAME}':" \
    -e "s:\('captcha.enabled'.*\) true:\1 false:" \
    -e "s:\('user'.*\) '.*':\1 '${LB_DATABASE_USER}':" \
    -e "s:\('password'.*\) '.*':\1 '${LB_DATABASE_PASSWORD}':" \
    -e "s:\('name'.*\) '.*':\1 '${LB_DATABASE_NAME}':"
fi

# Link the configuration file
if ! [ -f /var/www/html/config/config.php ]; then
  ln -s /config/config.php /var/www/html/config/config.php
fi

# Set secondary configuration settings
sed \
  -i /config/config.php \
  -e "s:\(\['install.password'\].*\) '.*':\1 '${LB_INSTALL_PASSWORD}':" \
  -e "s:\(\['default.timezone'\].*\) '.*':\1 '${LB_DEFAULT_TIMEZONE}':" \
  -e "s:\(\['database'\]\['hostspec'\].*\) '.*':\1 '${LB_DATABASE_HOSTSPEC}':" \
  -e "s:\(\['logging'\]\['folder'\].*\) '.*':\1 '${LB_LOGGING_FOLDER}':" \
  -e "s:\(\['logging'\]\['level'\].*\) '.*':\1 '${LB_LOGGING_LEVEL}':" \
  -e "s:\(\['logging'\]\['sql'\].*\) '.*':\1 '${LB_LOGGING_SQL}':" \
  -e "s:\('install.password'.*\) '.*':\1 '${LB_INSTALL_PASSWORD}':" \
  -e "s:\('default.timezone'.*\) '.*':\1 '${LB_DEFAULT_TIMEZONE}':" \
  -e "s:\('hostspec'.*\) '.*':\1 '${LB_DATABASE_HOSTSPEC}':" \
  -e "s:\('folder'.*\) '.*':\1 '${LB_LOGGING_FOLDER}':" \
  -e "s:\('level'.*\) '.*':\1 '${LB_LOGGING_LEVEL}':" \
  -e "s:\('sql'.*\) '.*':\1 '${LB_LOGGING_SQL}':"

# Create the plugins configuration file inside the volume
for source in $(find /var/www/html/plugins -type f -name "*dist*"); do
  target=$(echo "${source}" | sed -e "s/.dist//")
  if ! [ -f "/config/$(basename ${target})" ]; then
    cp --no-clobber "${source}" "/config/$(basename ${target})"
  fi
  if ! [ -f ${target} ]; then
    ln -s "/config/$(basename ${target})" "${target}"
  fi
done

# Set the php timezone file
if [ -f /usr/share/zoneinfo/${LB_DEFAULT_TIMEZONE} ]; then
  INI_FILE="/usr/local/etc/php/conf.d/librebooking.ini"
  echo "[Date]" >> ${INI_FILE}
  echo "date.timezone=\"${LB_DEFAULT_TIMEZONE}\"" >> ${INI_FILE}
fi

# Missing log directory
if ! [ -d "${LB_LOGGING_FOLDER}" ]; then
  mkdir -p "${LB_LOGGING_FOLDER}"
fi

# A URL path prefix was set
if ! [ -z "${APP_PATH}" ]; then
  ## Set server document root 1 directory up
  sed \
    -i /etc/apache2/sites-enabled/000-default.conf \
    -e "s:/var/www/html:/var/www:"

  ## Create a link to the html directory
  pushd /var/www
  ln -s html "${APP_PATH}"
  popd

  ## Adapt the .htaccess file
  sed \
    -i /var/www/${APP_PATH}/.htaccess \
    -e "s:\(RewriteCond .*\)/Web/:\1\.\*/Web/:" \
    -e "s:\(RewriteRule .*\) /Web/:\1 /${APP_PATH}/Web/:"
fi

# Switch to the apache server
exec "$@"
