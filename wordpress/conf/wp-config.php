<?php
define( 'DB_NAME', getenv('DB_NAME') ?: 'wordpress' );
define( 'DB_USER', getenv('DB_USER') ?: 'wpuser' );
define( 'DB_PASSWORD', getenv('DB_PASSWORD') ?: 'password' );
define( 'DB_HOST', getenv('DB_HOST') ?: 'mariadb' );
define( 'WP_HOME', getenv('WP_HOME') ?: 'https://login.42.fr' );
define( 'WP_SITEURL', getenv('WP_SITEURL') ?: 'https://login.42.fr' );


// Table prefix - REQUIRED
$table_prefix = 'wp_';

// WordPress path - REQUIRED
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

// Load WordPress - REQUIRED (this is what you're missing!)
require_once ABSPATH . 'wp-settings.php';