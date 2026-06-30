#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Master Orchestrator
# Description: Automates the deployment of Schedulr Pro on Ubuntu 24.04 LTS.
# ==============================================================================

set -Eeuo pipefail

# ------------------------------------------------------------------------------
# Initialization
# ------------------------------------------------------------------------------
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source Configuration
if [[ -f "${INSTALLER_DIR}/config/config.sh" ]]; then
    source "${INSTALLER_DIR}/config/config.sh"
else
    echo -e "\e[31m[ERROR] Configuration file missing: config/config.sh\e[0m"
    exit 1
fi

# Source Core Modules
source "${INSTALLER_DIR}/lib/core/logger.sh"
source "${INSTALLER_DIR}/lib/core/common.sh"
source "${INSTALLER_DIR}/lib/core/validation.sh"
source "${INSTALLER_DIR}/lib/core/rollback.sh"
source "${INSTALLER_DIR}/lib/core/report.sh"

# Source System Modules
source "${INSTALLER_DIR}/lib/system/packages.sh"
source "${INSTALLER_DIR}/lib/system/php.sh"
source "${INSTALLER_DIR}/lib/system/composer.sh"
source "${INSTALLER_DIR}/lib/system/mysql.sh"
source "${INSTALLER_DIR}/lib/system/nginx.sh"
source "${INSTALLER_DIR}/lib/system/supervisor.sh"
source "${INSTALLER_DIR}/lib/system/ssl.sh"

# Source Application Modules
source "${INSTALLER_DIR}/lib/application/laravel.sh"
source "${INSTALLER_DIR}/lib/application/permissions.sh"
source "${INSTALLER_DIR}/lib/application/optimization.sh"
source "${INSTALLER_DIR}/lib/application/verification.sh"

# ------------------------------------------------------------------------------
# User Inputs
# ------------------------------------------------------------------------------
prompt_inputs() {
    echo -e "${COLOR_INFO}==========================================${COLOR_RESET}"
    echo -e "${COLOR_INFO}          Schedulr Pro Installer          ${COLOR_RESET}"
    echo -e "${COLOR_INFO}==========================================${COLOR_RESET}"
    echo ""
    
    # Domain Name
    read -rp "Enter Domain Name (e.g. example.com): " USER_DOMAIN
    export USER_DOMAIN
    
    # Email Address
    read -rp "Enter Email Address (For SSL): " USER_EMAIL
    export USER_EMAIL
    
    # GitHub Token (Hidden)
    read -rsp "Enter GitHub Personal Access Token: " GITHUB_TOKEN
    echo ""
    export GITHUB_TOKEN
}

# ------------------------------------------------------------------------------
# Hook Execution Runner
# ------------------------------------------------------------------------------
run_hook() {
    local hook_name="$1"
    local hook_script="${INSTALLER_DIR}/hooks/${hook_name}.sh"
    
    if [[ -x "$hook_script" && -s "$hook_script" ]]; then
        log_info "Executing hook: ${hook_name}"
        "$hook_script"
    fi
}

# ------------------------------------------------------------------------------
# Module Runner Logic
# ------------------------------------------------------------------------------
run_module() {
    local module_name="$1"
    
    local check_func="${module_name}_check"
    local install_func="${module_name}_install"
    local verify_func="${module_name}_verify"
    
    if "$check_func"; then
        log_warn "Module [${module_name}] is already completed. Skipping..."
        return 0
    fi
    
    "$install_func"
    "$verify_func"
}

# ------------------------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------------------------
main() {
    local START_TIME
    START_TIME=$(date +%s)
    
    prompt_inputs
    
    # Pre-Flight Validation
    run_module "validation"
    
    # Pre-Install Hooks
    run_hook "pre-install"
    
    # Linear Dependency Chain
    local modules=(
        "packages"
        "php"
        "composer"
        "mysql"
        "nginx"
        "laravel"
        "supervisor"
        "ssl"
        "permissions"
        "optimization"
    )
    
    for mod in "${modules[@]}"; do
        run_module "$mod"
    done
    
    # Verification
    run_module "verification"
    
    # Generate Success Report
    generate_success_report "$START_TIME"
    
    # Post-Install Hooks
    run_hook "post-install"
    
    # Cleanup Lock
    release_lock
    
    log_step "Installation Complete!"
    log_success "Schedulr Pro has been successfully deployed at https://${USER_DOMAIN}"
}

main "$@"
