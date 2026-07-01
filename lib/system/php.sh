#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - PHP Module
# Description: Installs PHP and required extensions from ondrej/php PPA.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
php_check() {
    is_step_completed "php"
}

php_install() {
    log_step "Installing PHP $REQUIRED_PHP_VERSION"
    
    export DEBIAN_FRONTEND=noninteractive
    
    log_info "Adding ondrej/php PPA..."
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    apt-get update -y
    
    log_info "Installing PHP $REQUIRED_PHP_VERSION and extensions..."
    if ! apt-get install -y "php${REQUIRED_PHP_VERSION}-cli" "${PHP_EXTENSIONS[@]}" > /dev/null 2>&1; then
        log_error "Failed to install PHP $REQUIRED_PHP_VERSION."
        exit 2
    fi
    
    log_info "Updating PHP upload limits..."
    log_info "Updating PHP execution limits..."
    
    for SAPI in "cli" "fpm"; do
        local php_ini="/etc/php/${REQUIRED_PHP_VERSION}/${SAPI}/php.ini"
        if [[ -f "$php_ini" ]]; then
            sed -i "s/^upload_max_filesize.*/upload_max_filesize = ${UPLOAD_MAX_FILESIZE}/g" "$php_ini"
            sed -i "s/^post_max_size.*/post_max_size = ${POST_MAX_SIZE}/g" "$php_ini"
            sed -i "s/^memory_limit.*/memory_limit = ${PHP_MEMORY_LIMIT}/g" "$php_ini"
            sed -i "s/^max_execution_time.*/max_execution_time = ${PHP_MAX_EXECUTION_TIME}/g" "$php_ini"
            sed -i "s/^max_input_time.*/max_input_time = ${PHP_MAX_INPUT_TIME}/g" "$php_ini"
        fi
    done
    
    log_info "Reloading PHP-FPM..."
    systemctl reload "php${REQUIRED_PHP_VERSION}-fpm"
    
    mark_step_completed "php"
    register_rollback "php"
}

php_verify() {
    local php_ver
    if ! type php &>/dev/null; then
        log_error "PHP is not installed."
        return 4
    fi
    
    php_ver=$(php -v | head -n1 | grep -oP "PHP $REQUIRED_PHP_VERSION")
    if [[ -z "$php_ver" ]]; then
        log_error "Installed PHP version does not match required version ($REQUIRED_PHP_VERSION)."
        return 4
    fi
    
    log_success "PHP $REQUIRED_PHP_VERSION verified."
    return 0
}

php_rollback() {
    log_warn "PHP packages will not be automatically uninstalled to prevent breaking other apps."
    return 0
}
