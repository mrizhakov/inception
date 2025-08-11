#!/bin/bash
set -e

echo "Setting up WordPress..."

chown -R www-data:www-data /var/www/inception/

if [ ! -f /var/www/inception/wp-config.php ]; then
	mv /tmp/wp-config.php /var/www/inception/
fi

echo "Waiting for database..."

sleep 10

echo "Downloading WordPress core..."

wp --allow-root --path="/var/www/inception/" core download || true

if ! wp --allow-root --path="/var/www/inception/" core is-installed;
then
    echo "Installing WordPress core..."
    wp  --allow-root --path="/var/www/inception/" core install \
        --url=$WP_URL \
        --title=$WP_TITLE \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL
        echo "WordPress installed successfully!"
else
    echo "WordPress is already installed."
fi;
# Create non-admin user
if ! wp --allow-root --path="/var/www/inception/" user get $WP_USER;
then
    wp  --allow-root --path="/var/www/inception/" user create \
        $WP_USER \
        $WP_EMAIL \
        --user_pass=$WP_PASSWORD \
        --role=$WP_ROLE
fi;

chown -R www-data:www-data /var/www/inception/


# Download a new theme and activate it
wp --allow-root --path="/var/www/inception/" theme install raft --activate 
# Start php server in foreground
exec $@