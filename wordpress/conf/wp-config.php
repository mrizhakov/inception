<!-- define( 'DB_NAME', getenv('thedatabase') );
define( 'DB_USER', getenv('theuser') );
define( 'DB_PASSWORD', getenv('abc') );
define( 'DB_HOST', getenv('mariadb') );
define( 'WP_HOME', getenv('https://login.42.fr') );
define( 'WP_SITEURL', getenv('https://login.42.fr') ); -->

<?php
define( 'DB_NAME', getenv('DB_NAME') ?: 'wordpress' );
define( 'DB_USER', getenv('DB_USER') ?: 'wpuser' );
define( 'DB_PASSWORD', getenv('DB_PASSWORD') ?: 'password' );
define( 'DB_HOST', getenv('DB_HOST') ?: 'mariadb' );
define( 'WP_HOME', getenv('WP_HOME') ?: 'https://login.42.fr' );
define( 'WP_SITEURL', getenv('WP_SITEURL') ?: 'https://login.42.fr' );