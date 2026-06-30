#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Logger Module
# Description: Handles colored terminal output and file logging.
# ==============================================================================

# ANSI Color Codes
export COLOR_RESET="\e[0m"
export COLOR_INFO="\e[34m"    # Blue
export COLOR_SUCCESS="\e[32m" # Green
export COLOR_WARN="\e[33m"    # Yellow
export COLOR_ERROR="\e[31m"   # Red

# Ensure log directory exists
mkdir -p "$(dirname "$INSTALLER_LOG_FILE")"

# ------------------------------------------------------------------------------
# Core Logging Function
# ------------------------------------------------------------------------------
log_message() {
    local severity="$1"
    local color="$2"
    local message="$3"
    
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # Output to terminal
    echo -e "${color}[${severity}] ${message}${COLOR_RESET}"

    # Output to log file without color codes
    # Note: We must never log GitHub tokens or sensitive URLs.
    local sanitized_message
    sanitized_message=$(echo "$message" | sed -E 's/(https?:\/\/)[^:]+:[^@]+@/\1***:***@/g')

    echo "[${timestamp}] [${severity}] ${sanitized_message}" >> "$INSTALLER_LOG_FILE"
}

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------
log_info() {
    log_message "INFO" "$COLOR_INFO" "$1"
}

log_success() {
    log_message "SUCCESS" "$COLOR_SUCCESS" "$1"
}

log_warn() {
    log_message "WARN" "$COLOR_WARN" "$1"
}

log_error() {
    log_message "ERROR" "$COLOR_ERROR" "$1"
}

log_step() {
    echo -e "\n${COLOR_INFO}======================================================================${COLOR_RESET}"
    log_info "STEP: $1"
    echo -e "${COLOR_INFO}======================================================================${COLOR_RESET}"
}
