#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer Configuration
# Description: Single source of truth for all installer configuration values.
#              All modules must source this file.
# ==============================================================================

# ------------------------------------------------------------------------------
# Version & Meta Information
# ------------------------------------------------------------------------------
export INSTALLER_VERSION="1.0.0"
export APP_NAME="Schedulr Pro"
export APP_VERSION="1.0.0"

# ------------------------------------------------------------------------------
# Source Control (GitHub)
# ------------------------------------------------------------------------------
export REPO_URL="https://github.com/shashanksk8066/schedulrpro-software-v1.git"
export GITHUB_USERNAME="shashanksk8066"
export DEFAULT_BRANCH="main"
export DEBUG_MODE=true

# ------------------------------------------------------------------------------
# Deployment Directories
# ------------------------------------------------------------------------------
export INSTALL_DIR="/opt/schedulr-pro"
export APP_DIR="${INSTALL_DIR}/app"
export RUNTIME_DIR="${INSTALL_DIR}/runtime"
export LOG_DIR="${INSTALL_DIR}/logs"
export BACKUP_DIR="${INSTALL_DIR}/backups"
export INSTALLER_CACHE_DIR="${INSTALL_DIR}/installer"

# ------------------------------------------------------------------------------
# Global Lock File
# ------------------------------------------------------------------------------
export INSTALL_LOCK_FILE="/tmp/schedulrpro-installer.lock"

# ------------------------------------------------------------------------------
# Logging & Reporting Paths
# ------------------------------------------------------------------------------
export INSTALLER_LOG_FILE="${LOG_DIR}/schedulrpro-installer.log"
export INSTALL_REPORT_FILE="${RUNTIME_DIR}/install-report.txt"
export FAILURE_REPORT_FILE="${RUNTIME_DIR}/failure-report.txt"
export INSTALLER_STATE_FILE="${RUNTIME_DIR}/installer-state.json"
export ROLLBACK_STATE_FILE="${RUNTIME_DIR}/rollback-state.json"

# ------------------------------------------------------------------------------
# System Requirements
# ------------------------------------------------------------------------------
export REQUIRED_UBUNTU_VERSION="24.04"
export REQUIRED_PHP_VERSION="8.4"
export REQUIRED_MYSQL_VERSION="8.0"
export REQUIRED_NGINX_VERSION="1.24"
export REQUIRED_COMPOSER_VERSION="2.7"

# ------------------------------------------------------------------------------
# PHP Extensions
# ------------------------------------------------------------------------------
export PHP_EXTENSIONS=(
    "php${REQUIRED_PHP_VERSION}-fpm"
    "php${REQUIRED_PHP_VERSION}-mysql"
    "php${REQUIRED_PHP_VERSION}-mbstring"
    "php${REQUIRED_PHP_VERSION}-xml"
    "php${REQUIRED_PHP_VERSION}-curl"
    "php${REQUIRED_PHP_VERSION}-zip"
    "php${REQUIRED_PHP_VERSION}-bcmath"
    "php${REQUIRED_PHP_VERSION}-intl"
    "php${REQUIRED_PHP_VERSION}-redis"
)

# ------------------------------------------------------------------------------
# System Paths
# ------------------------------------------------------------------------------
export NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
export NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
export SUPERVISOR_CONF_DIR="/etc/supervisor/conf.d"

# ------------------------------------------------------------------------------
# Database Configurations (Dynamic Generation)
# Note: DB_PASSWORD will be generated randomly at runtime
# ------------------------------------------------------------------------------
export DB_NAME="schedulrpro"
export DB_USER="schedulrpro_user"
