#!/usr/bin/env bash
set -euo pipefail

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
  -e "CREATE DATABASE IF NOT EXISTS npm;" \
  -e "CREATE USER IF NOT EXISTS 'npm'@'%' IDENTIFIED BY '${MYSQL_NPM_PASSWORD}';" \
  -e "GRANT ALL PRIVILEGES ON npm.* TO 'npm'@'%';" \
  -e "FLUSH PRIVILEGES;"
