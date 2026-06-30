#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Common Module
# Description: Provides state tracking for resume support and shared helpers.
# ==============================================================================

# Ensure runtime directory exists
mkdir -p "$RUNTIME_DIR"

# ------------------------------------------------------------------------------
# State Tracking (Resume Support)
# ------------------------------------------------------------------------------
mark_step_completed() {
    local step_name="$1"
    
    # We use a simple flat file to track completed steps.
    # While config says .json, a flat file is safest for native bash.
    # We append the step name.
    echo "$step_name" >> "$INSTALLER_STATE_FILE.txt"
    log_info "Step marked as completed: ${step_name}"
}

is_step_completed() {
    local step_name="$1"
    
    if [[ -f "$INSTALLER_STATE_FILE.txt" ]]; then
        if grep -q "^${step_name}$" "$INSTALLER_STATE_FILE.txt"; then
            return 0 # true
        fi
    fi
    return 1 # false
}

# ------------------------------------------------------------------------------
# Global Error Handler
# ------------------------------------------------------------------------------
handle_error() {
    local exit_code=$1
    local line_no=$2
    local command="$3"
    
    log_error "Command '${command}' failed with exit code ${exit_code} on line ${line_no}."
    
    # Trigger failure report generation if report module is loaded
    if type generate_failure_report &>/dev/null; then
        generate_failure_report "Unknown" "Unknown" "$command" "$exit_code" "Command failed"
    fi
    
    # Trigger rollback
    if type execute_rollback &>/dev/null; then
        execute_rollback
    fi

    # Remove lock
    rm -f "$INSTALL_LOCK_FILE"
    
    exit "$exit_code"
}

# Trap errors globally if this file is sourced
trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR
