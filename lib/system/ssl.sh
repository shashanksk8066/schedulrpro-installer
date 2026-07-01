#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - SSL Module
# Description: Installs Certbot and configures Let's Encrypt SSL.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
ssl_check() {
    is_step_completed "ssl"
}

ssl_install() {
    log_step "Installing SSL Certificate"
    
    export DEBIAN_FRONTEND=noninteractive
    
    log_info "Installing certbot and python3-certbot-nginx..."
    if ! apt-get install -y certbot python3-certbot-nginx > /dev/null 2>&1; then
        log_error "Failed to install Certbot."
        exit 2
    fi
    
    if [[ -z "${USER_DOMAIN:-}" ]] || [[ -z "${USER_EMAIL:-}" ]]; then
        log_error "Domain or Email not provided. Cannot configure SSL."
        exit 3
    fi
    
    log_info "Requesting Let's Encrypt SSL for ${USER_DOMAIN}..."
    
    # Run certbot non-interactively
    if certbot --nginx -d "$USER_DOMAIN" --non-interactive --agree-tos -m "$USER_EMAIL" --redirect; then
        log_success "SSL Certificate installed successfully."
    else
        log_error "Certbot failed to obtain an SSL certificate."
        exit 2
    fi
    
    mark_step_completed "ssl"
    register_rollback "ssl"
}

ssl_verify() {
    if ! type certbot &>/dev/null; then
        log_error "Certbot is not installed."
        return 4
    fi
    
    if [[ ! -d "/etc/letsencrypt/live/${USER_DOMAIN}" ]]; then
        log_error "SSL certificate directory not found for ${USER_DOMAIN}."
        return 4
    fi
    
    log_success "SSL configuration verified."
    return 0
}

ssl_rollback() {
    log_warn "Removing SSL certificate for ${USER_DOMAIN}..."
    if type certbot &>/dev/null; then
        certbot delete --cert-name "$USER_DOMAIN" --non-interactive || true
    fi
    return 0
}
