#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Node.js Module
# Description: Installs Node.js and NPM for frontend asset compilation.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
node_check() {
    is_step_completed "node"
}

node_install() {
    log_step "Installing Node.js"
    
    export DEBIAN_FRONTEND=noninteractive
    
    log_info "Adding NodeSource repository for Node.js ${REQUIRED_NODE_VERSION}.x..."
    if ! curl -fsSL "https://deb.nodesource.com/setup_${REQUIRED_NODE_VERSION}.x" | bash - > /dev/null 2>&1; then
        log_error "Failed to setup NodeSource repository."
        exit 2
    fi
    
    log_info "Installing nodejs..."
    if ! apt-get install -y nodejs > /dev/null 2>&1; then
        log_error "Failed to install nodejs package."
        exit 2
    fi
    
    mark_step_completed "node"
    register_rollback "node"
}

node_verify() {
    if ! type node &>/dev/null; then
        log_error "Node.js is not installed."
        return 4
    fi
    
    if ! type npm &>/dev/null; then
        log_error "NPM is not installed."
        return 4
    fi
    
    local installed_node
    installed_node=$(node -v | tr -d 'v')
    
    if [[ "$installed_node" != "${REQUIRED_NODE_VERSION}"* ]]; then
        log_warn "Node version mismatch. Expected ${REQUIRED_NODE_VERSION}.x, found ${installed_node}"
    fi
    
    log_success "Node.js verified (Version: ${installed_node})."
    return 0
}

node_rollback() {
    log_warn "Removing Node.js..."
    apt-get remove -y nodejs >/dev/null 2>&1 || true
    rm -f /etc/apt/sources.list.d/nodesource.list
    apt-get update >/dev/null 2>&1 || true
    return 0
}
