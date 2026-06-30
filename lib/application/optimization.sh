#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Optimization Module
# Description: Optimizes Laravel for production and restarts queue workers.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
optimization_check() {
    is_step_completed "optimization"
}

optimization_install() {
    log_step "Optimizing Application"
    
    cd "$APP_DIR" || exit 3
    
    log_info "Caching application configurations..."
    sudo -u www-data php artisan config:cache
    
    log_info "Caching application routes..."
    sudo -u www-data php artisan route:cache
    
    log_info "Caching application views..."
    sudo -u www-data php artisan view:cache
    
    log_info "Caching application events..."
    sudo -u www-data php artisan event:cache
    
    log_info "Restarting queue workers safely..."
    sudo -u www-data php artisan queue:restart
    
    mark_step_completed "optimization"
}

optimization_verify() {
    # Implicitly verified if artisan commands passed
    log_success "Optimization completed."
    return 0
}

optimization_rollback() {
    log_warn "Clearing Laravel caches..."
    cd "$APP_DIR" || return 0
    sudo -u www-data php artisan optimize:clear || true
    return 0
}
