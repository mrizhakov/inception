#!/bin/bash

# MariaDB initialization script for container startup
# Sets up database and users from environment variables
# Passes control to mysqld_safe daemon at completion
echo "=== SCRIPT VERSION 2025-08-08 UPDATED ==="

# Debug mode (uncomment to enable): 
set -ex

# Environment variable examples:
DB_NAME=inceptiondb
DB_USER=mrizakov
DB_PASSWORD=dockerftw
DB_PASS_ROOT=dockerftw

echo "Creating necessary directories..."
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# Check if database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "=== Verifying mysql_install_db completion ==="
    if [ -d "/var/lib/mysql/mysql" ]; then
        echo "✓ System database 'mysql' directory created"
    else
        echo "✗ System database 'mysql' directory missing"
        exit 1
    fi

    if [ -f "/var/lib/mysql/ibdata1" ]; then
        echo "✓ InnoDB system tablespace created"
    else
        echo "✗ InnoDB system tablespace missing"
    fi

    echo "=== Data directory contents ==="
    ls -la /var/lib/mysql/

    echo "=== Checking file ownership ==="
    ls -la /var/lib/mysql/ | head -5
    
    DATABASE_INITIALIZED=false
else
    echo "MariaDB data directory already exists, skipping initialization..."
    DATABASE_INITIALIZED=true
fi

echo "Starting MariaDB service for initialization..."
service mariadb start

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to start..."
while ! mysqladmin ping --silent; do
    sleep 1
done

# Only configure database if it was just initialized
if [ "$DATABASE_INITIALIZED" = "false" ]; then
    echo "Configuring database and user permissions..."
    mariadb -v -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO 'root'@'%' IDENTIFIED BY '$DB_PASS_ROOT';
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$DB_PASS_ROOT');
FLUSH PRIVILEGES;
EOF
else
    echo "Database already configured, skipping user setup..."
fi

echo "Waiting for configuration to complete..."
sleep 5

echo "Stopping temporary MariaDB instance..."
service mariadb stop
echo "Launching MariaDB daemon..."
exec "$@"
