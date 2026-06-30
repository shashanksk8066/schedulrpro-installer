#!/usr/bin/env bash
# ==============================================================================
# Schedulr Pro Installer - Laravel Module
# Description: Deploys Laravel application from GitHub and configures environment.
# ==============================================================================

# ------------------------------------------------------------------------------
# Module Interface
# ------------------------------------------------------------------------------
laravel_check() {
    is_step_completed "laravel"
}

laravel_install() {
    log_step "Deploying Laravel Application"
    
    # 1. Clone Repository
    log_info "Cloning application repository (Tag: ${RELEASE_TAG})..."
    
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_error "GitHub Personal Access Token is empty. Cannot clone private repository."
        exit 1
    fi
    
    # Extract scheme/host/path from REPO_URL to insert token
    # e.g., https://github.com/user/repo.git -> https://user:TOKEN@github.com/user/repo.git
    local auth_repo_url
    auth_repo_url=$(echo "$REPO_URL" | sed -E "s|(https?://)|\1git:${GITHUB_TOKEN}@|")
    
    # Clone specific tag with depth 1
    if git clone --branch "$RELEASE_TAG" --depth=1 "$auth_repo_url" "$APP_DIR" >/dev/null 2>&1; then
        log_success "Repository cloned successfully."
    else
        log_error "GitHub authentication failed or repository not found."
        log_error "Please verify that the supplied Personal Access Token is valid and has read access to the repository."
        exit 2
    fi
    
    # 2. Secure Token & Remove Git Metadata
    unset GITHUB_TOKEN
    log_info "Removing Git metadata..."
    rm -rf "${APP_DIR}/.git"
    
    # 3. Composer Install
    log_info "Running composer install..."
    cd "$APP_DIR" || exit 2
    export COMPOSER_ALLOW_SUPERUSER=1
    composer install --no-dev --optimize-autoloader --no-interaction
    
    # 4. Generate .env
    log_info "Generating production .env file..."
    local env_template="$(dirname "$0")/../../templates/.env.template"
    if [[ ! -f "$env_template" ]]; then
        log_error "Environment template not found at $env_template"
        exit 3
    fi
    
    local db_password=""
    if [[ -f "$DB_PASS_FILE" ]]; then
        db_password=$(cat "$DB_PASS_FILE")
    else
        log_error "Database password file not found. MySQL module may have failed."
        exit 3
    fi
    
    sed -e "s|{{APP_URL}}|https://${USER_DOMAIN}|g" \
        -e "s|{{DB_NAME}}|${DB_NAME}|g" \
        -e "s|{{DB_USER}}|${DB_USER}|g" \
        -e "s|{{DB_PASSWORD}}|${db_password}|g" \
        "$env_template" > "${APP_DIR}/.env"
        
    # Generate Application Key
    log_info "Generating application key..."
    php artisan key:generate --force
    
    # 5. Storage Link & Migrations
    log_info "Linking storage..."
    php artisan storage:link
    
    log_info "Running database migrations..."
    php artisan migrate --force
    
    mark_step_completed "laravel"
    register_rollback "laravel"
}

laravel_verify() {
    if [[ ! -d "$APP_DIR" ]]; then
        log_error "Application directory not found."
        return 4
    fi
    
    if [[ ! -f "${APP_DIR}/.env" ]]; then
        log_error "Environment file not found."
        return 4
    fi
    
    log_success "Laravel application deployed."
    return 0
}

laravel_rollback() {
    log_warn "Removing Laravel application from ${APP_DIR}..."
    rm -rf "$APP_DIR"
    return 0
}
