#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Frontend Module
# Description: Detects and compiles frontend assets (Vite/NPM) if required.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
frontend_check() {
    is_step_completed "frontend"
}

frontend_install() {
    log_step "Building Frontend Assets"
    
    if [[ ! -f "${APP_DIR}/package.json" ]]; then
        log_info "No package.json detected. Skipping frontend build."
        mark_step_completed "frontend"
        return 0
    fi
    
    log_info "Frontend project detected. Installing NPM dependencies..."
    cd "$APP_DIR" || exit 3
    
    if ! npm install --no-audit --no-fund > /dev/null 2>&1; then
        log_error "NPM install failed."
        exit 2
    fi
    
    log_info "Compiling production assets (Vite)..."
    if ! npm run build > /dev/null 2>&1; then
        log_error "Frontend build (npm run build) failed."
        exit 2
    fi
    
    if [[ ! -f "${APP_DIR}/public/build/manifest.json" ]]; then
        log_error "Vite manifest not found. The build may have failed silently."
        exit 4
    fi
    
    log_success "Frontend assets compiled successfully."
    mark_step_completed "frontend"
    register_rollback "frontend"
}

frontend_verify() {
    if [[ -f "${APP_DIR}/package.json" ]]; then
        if [[ ! -f "${APP_DIR}/public/build/manifest.json" ]]; then
            log_error "Vite manifest is missing during verification."
            return 4
        fi
        log_success "Frontend build verified."
    fi
    return 0
}

frontend_rollback() {
    log_warn "Removing frontend build artifacts..."
    rm -rf "${APP_DIR}/node_modules"
    rm -rf "${APP_DIR}/public/build"
    return 0
}
