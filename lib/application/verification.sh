#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Verification Module
# Description: Comprehensive post-flight functional validation.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
verification_check() {
    return 1 # Verification always runs at the end
}

verification_install() {
    log_step "Final Post-Flight Verification"
    
    local has_error=0
    
    check_service() {
        local svc=$1
        if systemctl is-active --quiet "$svc"; then
            log_success "Service: $svc is running."
        else
            log_error "Service: $svc is NOT running."
            has_error=1
        fi
    }
    
    log_info "Verifying Infrastructure Services..."
    check_service "php${REQUIRED_PHP_VERSION}-fpm"
    check_service "mysql"
    check_service "nginx"
    check_service "supervisor"
    
    log_info "Verifying Supervisor Workers..."
    local workers=("schedulr-instagram" "schedulr-facebook" "schedulr-youtube" "schedulr-default" "schedulr-scheduler")
    for worker in "${workers[@]}"; do
        if supervisorctl status | grep "$worker" | grep -iq "RUNNING"; then
            log_success "Worker: $worker is RUNNING."
        else
            log_error "Worker: $worker is NOT running."
            has_error=1
        fi
    done
    
    log_info "Verifying Application Dependencies..."
    if [[ -f "${APP_DIR}/.env" ]]; then
        log_success "Application: .env exists."
        if grep -q "^APP_KEY=base64:" "${APP_DIR}/.env"; then
            log_success "Application: APP_KEY is set."
        else
            log_error "Application: APP_KEY is missing."
            has_error=1
        fi
    else
        log_error "Application: .env is missing."
        has_error=1
    fi
    
    if [[ -L "${APP_DIR}/public/storage" ]] || [[ -d "${APP_DIR}/public/storage" ]]; then
        log_success "Application: Storage link exists."
    else
        log_error "Application: Storage link missing."
        has_error=1
    fi
    
    if [[ -f "${APP_DIR}/package.json" ]]; then
        if [[ -f "${APP_DIR}/public/build/manifest.json" ]]; then
            log_success "Application: Vite manifest exists."
        else
            log_error "Application: Vite manifest missing. Frontend build failed."
            has_error=1
        fi
    fi
    
    log_info "Verifying Configuration Limits..."
    
    local php_upload
    php_upload=$(php -i 2>/dev/null | grep -i "^upload_max_filesize" | head -n1 | awk '{print $3}')
    if [[ "$php_upload" == "$UPLOAD_MAX_FILESIZE" ]]; then
        log_success "PHP upload_max_filesize = $php_upload"
    else
        log_error "PHP upload_max_filesize mismatch (Expected: $UPLOAD_MAX_FILESIZE, Found: $php_upload)"
        has_error=1
    fi
    
    local php_post
    php_post=$(php -i 2>/dev/null | grep -i "^post_max_size" | head -n1 | awk '{print $3}')
    if [[ "$php_post" == "$POST_MAX_SIZE" ]]; then
        log_success "PHP post_max_size = $php_post"
    else
        log_error "PHP post_max_size mismatch (Expected: $POST_MAX_SIZE, Found: $php_post)"
        has_error=1
    fi
    
    local nginx_client
    if type nginx &>/dev/null; then
        nginx_client=$(nginx -T 2>/dev/null | grep -i "client_max_body_size" | head -n1 | awk '{print $2}' | tr -d ';')
        if [[ "$nginx_client" == "$CLIENT_MAX_BODY_SIZE" ]]; then
            log_success "Nginx client_max_body_size = $nginx_client"
        else
            log_error "Nginx client_max_body_size mismatch (Expected: $CLIENT_MAX_BODY_SIZE, Found: $nginx_client)"
            has_error=1
        fi
    fi
    
    log_info "Verifying Database Connection..."
    # We verify database connection by running a silent artisan command. 
    # If the app can boot and query the DB, it works.
    if sudo -u www-data php "${APP_DIR}/artisan" db:monitor >/dev/null 2>&1 || sudo -u www-data php "${APP_DIR}/artisan" migrate:status >/dev/null 2>&1; then
        log_success "Application: Database connection and migrations verified."
    else
        log_error "Application: Database connection or migrations failed."
        has_error=1
    fi
    
    log_info "Verifying Domain Connectivity..."
    
    # Check HTTP (Port 80)
    if curl -sL -o /dev/null -w "%{http_code}" "http://${USER_DOMAIN}" | grep -q '200\|301\|302'; then
        log_success "Network: HTTP port 80 is responding."
    else
        log_warn "Network: HTTP port 80 is not returning 200/301/302. DNS may not be propagated."
    fi
    
    # Check HTTPS (Port 443)
    if curl -sL -o /dev/null -w "%{http_code}" "https://${USER_DOMAIN}" | grep -q '200\|301\|302'; then
        log_success "Network: HTTPS port 443 is responding."
    else
        log_warn "Network: HTTPS port 443 is not returning 200/301/302. Check your DNS and firewall."
    fi
    
    if [[ "$has_error" -eq 1 ]]; then
        log_error "Final verification failed. The installation is incomplete or broken."
        exit 4
    fi
    
    mark_step_completed "verification"
}

verification_verify() {
    return 0
}

verification_rollback() {
    return 0
}
