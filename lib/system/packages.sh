#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Packages Module
# Description: Installs base Ubuntu packages required by the installer and app.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
packages_check() {
    is_step_completed "packages"
}

packages_install() {
    log_step "Installing System Packages"
    
    export DEBIAN_FRONTEND=noninteractive
    
    log_info "Updating apt package index..."
    apt-get update -y
    
    log_info "Installing base dependencies..."
    apt-get install -y curl git unzip software-properties-common jq net-tools
    
    mark_step_completed "packages"
    register_rollback "packages"
}

packages_verify() {
    if ! type git &>/dev/null; then
        log_error "Git is not installed."
        return 4
    fi
    if ! type curl &>/dev/null; then
        log_error "Curl is not installed."
        return 4
    fi
    if ! type unzip &>/dev/null; then
        log_error "Unzip is not installed."
        return 4
    fi
    log_success "Base system packages installed successfully."
    return 0
}

packages_rollback() {
    log_warn "System packages are not rolled back automatically to prevent breaking other apps."
    return 0
}
