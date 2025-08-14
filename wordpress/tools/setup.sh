#!/bin/bash
set -e

echo "Setting up WordPress..."
echo "DB_HOST=${DB_HOST} DB_NAME=${DB_NAME} DB_USER=${DB_USER}"


chown -R www-data:www-data /var/www/inception/

if [ ! -f /var/www/inception/wp-config.php ]; then
	mv /tmp/wp-config.php /var/www/inception/
fi

echo "Waiting for database..."

# Test database connection instead of just sleeping
for i in {1..30}; do
    if mysql -h${DB_HOST:-mariadb} -u${DB_USER:-mrizakov} -p${DB_PASSWORD:-dockerftw} -e "SELECT 1;" ; then
        echo "Database connection successful!"
        break
    fi
    echo "Attempt $i/30: Database not ready, waiting..."
    sleep 2
done

cd /var/www/inception

echo "Downloading WordPress core..."

wp --allow-root core download || true

if ! wp --allow-root core is-installed;
then
    echo "Installing WordPress core..."
    wp --allow-root core install \
        --url="${WP_URL:-http://localhost:9000}" \
        --title="${WP_TITLE:-Inception WordPress}" \
        --admin_user="${WP_ADMIN_USER:-admin}" \
        --admin_password="${WP_ADMIN_PASSWORD:-admin123}" \
        --admin_email="${WP_ADMIN_EMAIL:-admin@example.com}"
    echo "WordPress installed successfully!"
else
    echo "WordPress is already installed."
fi;
# Create additional user only if variables are set
if [ -n "${WP_USER}" ] && [ -n "${WP_EMAIL}" ] && [ -n "${WP_PASSWORD}" ]; then
    if ! wp --allow-root user get "${WP_USER}" >/dev/null 2>&1; then
        wp --allow-root user create \
            "${WP_USER}" "${WP_EMAIL}" \
            --user_pass="${WP_PASSWORD}" \
            --role="${WP_ROLE:-editor}"
        echo "Additional user '${WP_USER}' created successfully!"
    else
        echo "User '${WP_USER}' already exists."
    fi
fi

chown -R www-data:www-data /var/www/inception/


# Download a new theme and activate it
wp --allow-root theme install raft --activate || echo "Theme installation failed or skipped"
# Start php server in foreground
exec $@