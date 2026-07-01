#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - MySQL Module
# Description: Installs MySQL, creates DB and user, and grants privileges.
# ==============================================================================

export DB_PASS_FILE="${RUNTIME_DIR}/.db_password"

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
mysql_check() {
    is_step_completed "mysql"
}

mysql_install() {
    log_step "Installing MySQL Server"
    
    export DEBIAN_FRONTEND=noninteractive
    
    log_info "Installing mysql-server..."
    if ! apt-get install -y mysql-server > /dev/null 2>&1; then
        log_error "Failed to install MySQL server."
        exit 2
    fi
    
    log_info "Securing MySQL and creating database..."
    
    # Start mysql if not running
    systemctl start mysql
    systemctl enable mysql
    
    # Generate random secure password
    local new_password
    new_password=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24)
    
    # Save it so the Laravel module can read it
    echo "$new_password" > "$DB_PASS_FILE"
    chmod 600 "$DB_PASS_FILE"
    
    # Create DB and User
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${new_password}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${new_password}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    mark_step_completed "mysql"
    register_rollback "mysql"
}

mysql_verify() {
    if ! type mysql &>/dev/null; then
        log_error "MySQL is not installed."
        return 4
    fi
    
    if ! systemctl is-active --quiet mysql; then
        log_error "MySQL service is not running."
        return 4
    fi
    
    log_success "MySQL verified and running."
    return 0
}

mysql_rollback() {
    log_warn "Dropping database ${DB_NAME} and user ${DB_USER}..."
    mysql -u root <<EOF
DROP DATABASE IF EXISTS \`${DB_NAME}\`;
DROP USER IF EXISTS '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
    rm -f "$DB_PASS_FILE"
    return 0
}
