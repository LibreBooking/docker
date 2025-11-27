#!/bin/sh
set -eu

# Constants
readonly DFT_LOG_FLR="/var/log/librebooking"
readonly DFT_LOG_LEVEL="none"
readonly DFT_LOG_SQL=false
readonly DFT_LB_ENV="production"
readonly DFT_LB_PATH=""

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

# Initialize variables
file_env LB_DB_USER_PWD

LB_LOG_FOLDER=${LB_LOG_FOLDER:-${DFT_LOG_FLR}}
LB_LOG_LEVEL=${LB_LOG_LEVEL:-${DFT_LOG_LEVEL}}
LB_LOG_SQL=${LB_LOG_SQL:-${DFT_LOG_SQL}}
LB_ENV=${LB_ENV:-${DFT_LB_ENV}}
LB_PATH=${LB_PATH:-${DFT_LB_PATH}}

# Set the php timezone file
if [ -f /usr/share/zoneinfo/${TZ} ]; then
  INI_FILE="/usr/local/etc/php/conf.d/librebooking.ini"
  echo "[Date]" >> ${INI_FILE}
  echo "date.timezone=\"${TZ}\"" >> ${INI_FILE}
fi

# Link the configuration file
if ! [ -f /var/www/html/config/config.php ]; then
  ln -s /config/config.php /var/www/html/config/config.php
fi

# Load cron jobs under user www-data
crontab -u www-data /config/lb-jobs-cron

# Switch to cron
exec /usr/sbin/cron -f -L 5
