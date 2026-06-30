#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Rollback Module
# Description: Maintains state of destructive actions and reverts them on failure.
# ==============================================================================

# Ensure rollback state file exists
touch "$ROLLBACK_STATE_FILE"

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
rollback_check() {
    return 1 # Rollback itself is never "already installed"
}

rollback_install() {
    # Nothing to install
    return 0
}

rollback_verify() {
    return 0
}

# ------------------------------------------------------------------------------
# Core Functions
# ------------------------------------------------------------------------------
register_rollback() {
    local module_name="$1"
    
    # Prepend the module to the state file so we can read it LIFO (Last In First Out)
    # Since bash doesn't have a simple prepend, we write to a temp file first.
    local temp_file
    temp_file=$(mktemp)
    
    echo "$module_name" > "$temp_file"
    cat "$ROLLBACK_STATE_FILE" >> "$temp_file" 2>/dev/null || true
    mv "$temp_file" "$ROLLBACK_STATE_FILE"
    
    log_info "Registered rollback step for module: $module_name"
}

execute_rollback() {
    if [[ ! -s "$ROLLBACK_STATE_FILE" ]]; then
        log_info "No actions to rollback."
        return 0
    fi
    
    log_warn "Starting rollback of completed actions..."
    
    while IFS= read -r module_name; do
        if [[ -n "$module_name" ]]; then
            log_warn "Rolling back module: $module_name"
            # Attempt to call the module's rollback function
            local rollback_func="${module_name}_rollback"
            if type "$rollback_func" &>/dev/null; then
                "$rollback_func" || log_error "Failed to rollback module: $module_name"
            else
                log_warn "No rollback function found for module: $module_name"
            fi
        fi
    done < "$ROLLBACK_STATE_FILE"
    
    # Clear the rollback state once finished
    > "$ROLLBACK_STATE_FILE"
    
    log_success "Rollback completed safely."
}
