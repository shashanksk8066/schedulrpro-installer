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
    apt-get install -y "php${REQUIRED_PHP_VERSION}-cli" "${PHP_EXTENSIONS[@]}"
    
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
