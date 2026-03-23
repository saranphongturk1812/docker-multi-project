#!/usr/bin/env sh
set -e

if [ -d /var/www ]; then
  mkdir -p /var/www/storage
  mkdir -p /var/www/storage/framework/cache
  mkdir -p /var/www/storage/framework/sessions
  mkdir -p /var/www/storage/framework/views
  mkdir -p /var/www/bootstrap/cache
  mkdir -p /var/www/database

  if [ ! -f /var/www/database/database.sqlite ]; then
    touch /var/www/database/database.sqlite
  fi

  chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache /var/www/database 2>/dev/null || true
  chmod -R ug+rwX /var/www/storage /var/www/bootstrap/cache /var/www/database 2>/dev/null || true
fi

exec "$@"
