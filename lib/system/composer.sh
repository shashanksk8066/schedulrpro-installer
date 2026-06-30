#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Composer Module
# Description: Installs PHP Composer globally.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
composer_check() {
    is_step_completed "composer"
}

composer_install() {
    log_step "Installing Composer"
    
    log_info "Downloading Composer..."
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    
    # We could check signature, but for simplicity we run the installer
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f composer-setup.php
    
    mark_step_completed "composer"
    register_rollback "composer"
}

composer_verify() {
    if ! type composer &>/dev/null; then
        log_error "Composer is not installed."
        return 4
    fi
    log_success "Composer verified."
    return 0
}

composer_rollback() {
    log_warn "Removing Composer..."
    rm -f /usr/local/bin/composer
    return 0
}
