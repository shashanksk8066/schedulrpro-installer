#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Validation Module
# Description: Pre-flight environmental validation and lock management.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
validation_check() {
    is_step_completed "validation"
}

validation_install() {
    log_step "Pre-flight Validations"
    
    validate_root
    acquire_lock
    validate_ubuntu_version
    validate_ports
    validate_resources
    validate_github_token
    
    mark_step_completed "validation"
}

validation_verify() {
    # Implicitly verified if install passes without aborting
    return 0
}

validation_rollback() {
    release_lock
}

# ------------------------------------------------------------------------------
# Validation Functions
# ------------------------------------------------------------------------------
validate_root() {
    if [[ "$EUID" -ne 0 ]]; then
        log_error "This installer must be run as root."
        exit 1
    fi
    log_success "Root privileges verified."
}

acquire_lock() {
    if [[ -f "$INSTALL_LOCK_FILE" ]]; then
        log_error "Another installation is currently running (Lock file exists: $INSTALL_LOCK_FILE)."
        log_error "If this is a mistake, delete the lock file and try again."
        exit 1
    fi
    touch "$INSTALL_LOCK_FILE"
    log_success "Installation lock acquired."
}

release_lock() {
    rm -f "$INSTALL_LOCK_FILE"
}

validate_ubuntu_version() {
    local os_version
    os_version=$(lsb_release -rs 2>/dev/null || echo "unknown")
    
    if [[ "$os_version" != "$REQUIRED_UBUNTU_VERSION" ]]; then
        log_error "Unsupported OS Version: $os_version. Schedulr Pro requires Ubuntu $REQUIRED_UBUNTU_VERSION LTS."
        exit 1
    fi
    log_success "Ubuntu Version $os_version verified."
}

validate_ports() {
    if ss -tulpn | grep -E ":80\b" > /dev/null; then
        # It's possible Nginx is already running from a previous failed run
        # but if we are on a totally fresh server, 80 should be free.
        # We will issue a warning instead of a hard fail, as we use Nginx.
        log_warn "Port 80 is currently in use. The installer will reconfigure Nginx."
    else
        log_success "Port 80 is available."
    fi

    if ss -tulpn | grep -E ":443\b" > /dev/null; then
        log_warn "Port 443 is currently in use."
    else
        log_success "Port 443 is available."
    fi
}

validate_resources() {
    local mem_kb
    mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    
    if [[ "$mem_kb" -lt 1000000 ]]; then
        log_warn "System memory is below 1GB. Schedulr Pro may experience performance issues."
    else
        log_success "System memory verified."
    fi
}

validate_github_token() {
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_error "GitHub Personal Access Token is empty. Authentication failed."
        log_error "Please verify that the supplied Personal Access Token is valid and has read access to the repository."
        exit 1
    fi
    log_success "GitHub Token validation passed."
}
