#!/bin/bash
# filepath: /home/mrizakov/Documents/inception/mariaDB/scripts/setup.sh

#===============================================================================
# MariaDB Container Setup Script
# 
# Purpose: Initialize MariaDB database with custom database and user
# Usage: Called automatically by Docker container startup
#===============================================================================

set -e  # Exit on any error

#===============================================================================
# CONFIGURATION
#===============================================================================

# Database configuration from environment variables
readonly DB_NAME="${DB_NAME:-inceptiondb}"
readonly DB_USER="${DB_USER:-mrizakov}"
readonly DB_PASSWORD="${DB_PASSWORD:-dockerftw}"
readonly DB_PASS_ROOT="${DB_PASS_ROOT:-dockerftw}"

# Paths
readonly MYSQL_DATA_DIR="/var/lib/mysql"
readonly MYSQL_RUN_DIR="/run/mysqld"
readonly MYSQL_LOG_DIR="/var/log/mysql"
readonly MYSQL_SOCKET="${MYSQL_RUN_DIR}/mysqld.sock"

#===============================================================================
# UTILITY FUNCTIONS
#===============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log_section() {
    echo ""
    echo "=== $* ==="
}

error_exit() {
    echo "ERROR: $*" >&2
    exit 1
}

wait_for_mysql() {
    local max_attempts=30
    local attempt=1
    
    log "Waiting for MariaDB to start..."
    
    while [ $attempt -le $max_attempts ]; do
        if mysqladmin -S "$MYSQL_SOCKET" ping --silent 2>/dev/null; then
            log "MariaDB is ready! (attempt $attempt/$max_attempts)"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts: MariaDB not ready, waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    error_exit "MariaDB failed to start after $max_attempts attempts"
}

#===============================================================================
# SETUP FUNCTIONS
#===============================================================================

setup_directories() {
    log_section "Setting up directories"
    
    mkdir -p "$MYSQL_RUN_DIR" "$MYSQL_LOG_DIR"
    chown mysql:mysql "$MYSQL_RUN_DIR" "$MYSQL_LOG_DIR"
    
    log "✓ Created and configured directories"
}

initialize_database() {
    if [ -d "$MYSQL_DATA_DIR/mysql" ]; then
        log "MariaDB data directory exists - skipping initialization"
        return 1  # Return 1 to indicate no initialization needed
    fi
    
    log_section "Initializing MariaDB"
    
    mysql_install_db \
        --user=mysql \
        --datadir="$MYSQL_DATA_DIR" \
        --skip-name-resolve \
        || error_exit "Failed to initialize MariaDB data directory"
    
    # Verify initialization
    [ -d "$MYSQL_DATA_DIR/mysql" ] || error_exit "System database 'mysql' not created"
    [ -f "$MYSQL_DATA_DIR/ibdata1" ] || error_exit "InnoDB system tablespace not created"
    
    log "✓ MariaDB data directory initialized successfully"
    return 0  # Return 0 to indicate initialization was performed
}

fix_permissions() {
    log_section "Fixing file permissions"
    
    chown -R mysql:mysql "$MYSQL_DATA_DIR" "$MYSQL_RUN_DIR" "$MYSQL_LOG_DIR"
    chmod -R 755 "$MYSQL_DATA_DIR"
    
    log "✓ File permissions updated"
}

start_mysql_for_setup() {
    log_section "Starting MariaDB for initial setup"
    
    # Start MariaDB in background for configuration
    mysqld_safe \
        --user=mysql \
        --datadir="$MYSQL_DATA_DIR" \
        --socket="$MYSQL_SOCKET" \
        --skip-networking &
    
    # Wait for it to be ready
    wait_for_mysql
}

configure_database() {
    log_section "Configuring database and users"
    
    mysql -S "$MYSQL_SOCKET" -u root <<EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASS_ROOT';

-- Create application database
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;

-- Create application user
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';

-- Allow root connections from remote hosts (for administration)
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '$DB_PASS_ROOT';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

-- Apply changes
FLUSH PRIVILEGES;
EOF

    log "✓ Database '$DB_NAME' and user '$DB_USER' configured"
}

stop_setup_mysql() {
    log_section "Stopping setup MariaDB instance"
    
    mysqladmin -S "$MYSQL_SOCKET" -u root -p"$DB_PASS_ROOT" shutdown
    
    log "✓ Setup instance stopped"
}

start_production_mysql() {
    log_section "Starting MariaDB in production mode"
    
    log "Database: $DB_NAME"
    log "User: $DB_USER"
    log "Accepting connections on: 0.0.0.0:3306"
    
    # Start MariaDB in production mode (PID 1, accepts network connections)
    exec mysqld \
        --user=mysql \
        --datadir="$MYSQL_DATA_DIR" \
        --bind-address=0.0.0.0 \
        --port=3306
}

#===============================================================================
# MAIN EXECUTION
#===============================================================================

main() {
    log_section "MariaDB Container Setup Started"
    
    # Setup phase
    setup_directories
    fix_permissions
    
    # Initialize database if needed
    if initialize_database; then
        # Database was just initialized, need to configure it
        start_mysql_for_setup
        configure_database
        stop_setup_mysql
        log "✓ Database initialization and configuration completed"
    else
        log "✓ Using existing database configuration"
    fi
    
    # Start production server
    start_production_mysql
}

#===============================================================================
# SCRIPT ENTRY POINT
#===============================================================================

# Enable debug mode if DEBUG environment variable is set
[ "${DEBUG:-}" = "true" ] && set -x

# Run main function
main "$@"