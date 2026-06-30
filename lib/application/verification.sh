#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Verification Module
# Description: Final post-flight functional validation.
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
    
    # Check Domain Connectivity
    log_info "Verifying domain connectivity via HTTPS..."
    if ! curl -sL -o /dev/null -w "%{http_code}" "https://${USER_DOMAIN}" | grep -q '200\|301\|302'; then
        log_warn "Could not verify HTTPS connectivity. Check your DNS records or firewall."
        # We don't fail here because DNS might not have propagated internally.
    else
        log_success "Domain connectivity verified."
    fi
    
    # Check Supervisor Workers
    log_info "Verifying queue workers..."
    local workers=("instagram" "facebook" "youtube" "default" "scheduler")
    for worker in "${workers[@]}"; do
        if supervisorctl status "$worker" 2>/dev/null | grep -iq "RUNNING"; then
            log_success "Worker '$worker' is running."
        else
            log_error "Worker '$worker' is NOT running."
            has_error=1
        fi
    done
    
    # Storage Writable
    if [[ -w "${APP_DIR}/storage" ]]; then
        log_success "Storage directory is writable."
    else
        log_error "Storage directory is NOT writable by www-data."
        has_error=1
    fi
    
    if [[ "$has_error" -eq 1 ]]; then
        log_error "Final verification failed."
        exit 4
    fi
    
    mark_step_completed "verification"
}

verification_verify() {
    return 0
}

verification_rollback() {
    # Verification is non-destructive
    return 0
}
