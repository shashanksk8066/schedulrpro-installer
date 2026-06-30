#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Nginx Module
# Description: Installs Nginx and configures the domain.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
nginx_check() {
    is_step_completed "nginx"
}

nginx_install() {
    log_step "Installing Nginx"
    
    export DEBIAN_FRONTEND=noninteractive
    
    log_info "Installing nginx..."
    apt-get install -y nginx
    
    log_info "Configuring Nginx for domain: ${USER_DOMAIN}"
    
    local template_file="${INSTALLER_DIR}/templates/nginx.conf"
    local site_conf="${NGINX_SITES_AVAILABLE}/${USER_DOMAIN}.conf"
    
    if [[ ! -f "$template_file" ]]; then
        log_error "Nginx template not found at $template_file"
        exit 3
    fi
    
    # Replace placeholders and write to sites-available
    sed -e "s/{{DOMAIN}}/${USER_DOMAIN}/g" \
        -e "s|{{APP_DIR}}|${APP_DIR}|g" \
        -e "s/{{PHP_VERSION}}/${REQUIRED_PHP_VERSION}/g" \
        "$template_file" > "$site_conf"
        
    # Enable site
    ln -sf "$site_conf" "${NGINX_SITES_ENABLED}/${USER_DOMAIN}.conf"
    
    # Remove default site if it exists to avoid conflicts
    rm -f "${NGINX_SITES_ENABLED}/default"
    
    # Test and reload
    if nginx -t >/dev/null 2>&1; then
        systemctl reload nginx
        systemctl enable nginx
    else
        log_error "Nginx configuration test failed."
        exit 2
    fi
    
    mark_step_completed "nginx"
    register_rollback "nginx"
}

nginx_verify() {
    if ! type nginx &>/dev/null; then
        log_error "Nginx is not installed."
        return 4
    fi
    
    if ! systemctl is-active --quiet nginx; then
        log_error "Nginx service is not running."
        return 4
    fi
    
    log_success "Nginx verified and running."
    return 0
}

nginx_rollback() {
    log_warn "Removing Nginx configuration for ${USER_DOMAIN}..."
    rm -f "${NGINX_SITES_ENABLED}/${USER_DOMAIN}.conf"
    rm -f "${NGINX_SITES_AVAILABLE}/${USER_DOMAIN}.conf"
    systemctl reload nginx || true
    return 0
}
