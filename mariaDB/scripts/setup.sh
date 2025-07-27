#!/bin/bash

# MariaDB initialization script for container startup
# Sets up database and users from environment variables
# Passes control to mysqld_safe daemon at completion

# Debug mode (uncomment to enable): set -ex

# Environment variable examples:
DB_NAME=inceptiondb
DB_USER=mrizakov
DB_PASSWORD=dockerftw
DB_PASS_ROOT=dockerftw

echo "Starting MariaDB service for initialization..."
service mariadb start

echo "Configuring database and user permissions..."
mariadb -v -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO 'root'@'%' IDENTIFIED BY '$DB_PASS_ROOT';
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$DB_PASS_ROOT');
EOF

echo "Waiting for configuration to complete..."
sleep 5

echo "Stopping temporary MariaDB instance..."
service mariadb stop

echo "Launching MariaDB daemon..."
exec $@