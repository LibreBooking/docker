#!/bin/sh
set -eu

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
