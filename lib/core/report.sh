#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Reporting Module
# Description: Generates installation and failure reports.
# ==============================================================================

# Ensure runtime directory exists
mkdir -p "$RUNTIME_DIR"

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
report_check() {
    return 1 # Report module is run dynamically at the end
}

report_install() {
    # Handled via explicit function calls below
    return 0
}

report_verify() {
    return 0
}

report_rollback() {
    return 0
}

# ------------------------------------------------------------------------------
# Core Functions
# ------------------------------------------------------------------------------
generate_success_report() {
    local start_time=$1
    local end_time
    end_time=$(date +%s)
    
    local duration=$((end_time - start_time))
    
    local php_ver=""
    if type php &>/dev/null; then
        php_ver=$(php -v | head -n1 | cut -d' ' -f2)
    fi
    
    local mysql_ver=""
    if type mysql &>/dev/null; then
        mysql_ver=$(mysql -V | awk '{print $5}' | tr -d ',')
    fi
    
    local nginx_ver=""
    if type nginx &>/dev/null; then
        nginx_ver=$(nginx -v 2>&1 | awk -F'/' '{print $2}')
    fi
    
    local os_ver
    os_ver=$(lsb_release -rs 2>/dev/null || echo "unknown")

    log_step "Generating Installation Report"
    
    cat <<EOF > "$INSTALL_REPORT_FILE"
======================================================================
Schedulr Pro Installation Report
======================================================================
Installation Status: SUCCESS
Generated At:        $(date "+%Y-%m-%d %H:%M:%S")
Domain Name:         ${USER_DOMAIN:-Unknown}
Installation Dir:    $INSTALL_DIR

----------------------------------------------------------------------
Software Versions
----------------------------------------------------------------------
Installer Version:   $INSTALLER_VERSION
App Version:         $APP_VERSION
Ubuntu Version:      $os_ver
PHP Version:         ${php_ver:-Not installed}
MySQL Version:       ${mysql_ver:-Not installed}
Nginx Version:       ${nginx_ver:-Not installed}

----------------------------------------------------------------------
Timestamps
----------------------------------------------------------------------
Duration:            ${duration} seconds

======================================================================
EOF
    
    log_success "Report generated at $INSTALL_REPORT_FILE"
}

generate_failure_report() {
    local module=$1
    local step=$2
    local command=$3
    local exit_code=$4
    local error_msg=$5
    
    cat <<EOF > "$FAILURE_REPORT_FILE"
======================================================================
Schedulr Pro Failure Report
======================================================================
Installation Status: FAILED
Generated At:        $(date "+%Y-%m-%d %H:%M:%S")

Failed Module:       $module
Failed Step:         $step
Executed Command:    $command
Exit Code:           $exit_code
Error Message:       $error_msg

Rollback triggered. See $INSTALLER_LOG_FILE for full details.
======================================================================
EOF
}
