#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Permissions Module
# Description: Enforces secure ownership and permissions for the application.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
permissions_check() {
    is_step_completed "permissions"
}

permissions_install() {
    log_step "Securing File Permissions"
    
    if [[ ! -d "$APP_DIR" ]]; then
        log_error "Application directory not found. Cannot set permissions."
        exit 3
    fi
    
    log_info "Setting ownership to www-data:www-data..."
    chown -R www-data:www-data "$APP_DIR"
    
    log_info "Setting directory and file permissions..."
    find "$APP_DIR" -type d -exec chmod 755 {} \;
    find "$APP_DIR" -type f -exec chmod 644 {} \;
    
    # Specific Laravel permissions
    log_info "Securing storage and cache directories..."
    chmod -R ug+rwx "${APP_DIR}/storage" "${APP_DIR}/bootstrap/cache"
    
    mark_step_completed "permissions"
}

permissions_verify() {
    # Check if a known directory is owned by www-data
    local owner
    owner=$(stat -c '%U' "${APP_DIR}/storage")
    if [[ "$owner" != "www-data" ]]; then
        log_error "Permissions verify failed: storage directory is not owned by www-data."
        return 4
    fi
    
    log_success "File permissions verified."
    return 0
}

permissions_rollback() {
    # Permissions aren't destructively rolled back, we just return true.
    return 0
}
