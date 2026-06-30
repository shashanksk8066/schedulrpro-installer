#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Supervisor Module
# Description: Installs and configures Supervisor for queue workers & scheduler.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
supervisor_check() {
    is_step_completed "supervisor"
}

supervisor_install() {
    log_step "Installing Supervisor"
    
    export DEBIAN_FRONTEND=noninteractive
    
    log_info "Installing supervisor..."
    apt-get install -y supervisor
    
    log_info "Configuring Supervisor workers..."
    
    local template_dir="${INSTALLER_DIR}/templates"
    local configs=("supervisor-instagram.conf" "supervisor-facebook.conf" "supervisor-youtube.conf" "supervisor-default.conf" "supervisor-scheduler.conf")
    
    for conf in "${configs[@]}"; do
        local tpl="${template_dir}/${conf}"
        local dest="${SUPERVISOR_CONF_DIR}/${conf}"
        
        if [[ ! -f "$tpl" ]]; then
            log_error "Supervisor template not found: $tpl"
            exit 3
        fi
        
        sed -e "s|{{APP_DIR}}|${APP_DIR}|g" \
            -e "s|{{PHP_VERSION}}|${REQUIRED_PHP_VERSION}|g" \
            "$tpl" > "$dest"
    done
    
    log_info "Reloading Supervisor..."
    supervisorctl reread
    supervisorctl update
    
    mark_step_completed "supervisor"
    register_rollback "supervisor"
}

supervisor_verify() {
    if ! type supervisorctl &>/dev/null; then
        log_error "Supervisor is not installed."
        return 4
    fi
    
    if ! systemctl is-active --quiet supervisor; then
        log_error "Supervisor service is not running."
        return 4
    fi
    
    log_success "Supervisor verified and running."
    return 0
}

supervisor_rollback() {
    log_warn "Removing Supervisor configurations..."
    local configs=("supervisor-instagram.conf" "supervisor-facebook.conf" "supervisor-youtube.conf" "supervisor-default.conf" "supervisor-scheduler.conf")
    
    for conf in "${configs[@]}"; do
        rm -f "${SUPERVISOR_CONF_DIR}/${conf}"
    done
    
    supervisorctl reread || true
    supervisorctl update || true
    return 0
}
