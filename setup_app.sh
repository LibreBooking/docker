#!/bin/bash
# vim: set expandtab ts=2 sw=2 ai :

set -e
set -u
set -o pipefail
trap 'echo "Exit status $? at line $LINENO from: $BASH_COMMAND"' ERR

PS4='+ ${BASH_SOURCE:-}:${FUNCNAME[0]:-}:L${LINENO:-}:   '
set -x

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
  mkdir --mode 0775 /var/www/html/tpl_c
fi

mkdir --mode 0775 /var/www/html/Web/uploads/reservation
