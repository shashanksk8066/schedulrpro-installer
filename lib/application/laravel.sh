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

# ------------------------------------------------------------------------------
# Clone Logic
# ------------------------------------------------------------------------------
clone_repository() {
    log_info "Preparing to clone application repository..."
    
    # Validate required variables
    if [[ -z "${REPO_URL:-}" ]] || [[ -z "${RELEASE_TAG:-}" ]] || [[ -z "${GITHUB_USERNAME:-}" ]] || [[ -z "${GITHUB_TOKEN:-}" ]] || [[ -z "${APP_DIR:-}" ]]; then
        log_error "Missing required configuration variables for cloning."
        exit 1
    fi
    
    # Verify APP_DIR
    if [[ -d "$APP_DIR" ]]; then
        log_error "Directory ${APP_DIR} already exists. Refusing to overwrite existing installation."
        exit 1
    fi
    
    # Construct authenticated URL
    local clean_url
    clean_url=$(echo "$REPO_URL" | sed -E 's|^https?://||')
    local auth_repo_url="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@${clean_url}"
    
    # Debug Mode Output
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        log_info "--- Debug Info ---"
        log_info "Repository URL: https://****:****@${clean_url}"
        log_info "Clone Mode: ${CLONE_MODE:-tag}"
        if [[ "${CLONE_MODE:-tag}" == "tag" ]]; then
            log_info "Release Tag: ${RELEASE_TAG}"
        else
            log_info "Default Branch: ${DEFAULT_BRANCH:-main}"
        fi
        log_info "Target Directory: ${APP_DIR}"
        log_info "------------------"
    fi
    
    # Validate Release Tag
    if [[ "${CLONE_MODE:-tag}" == "tag" ]]; then
        log_info "Verifying release tag ${RELEASE_TAG}..."
        if ! git ls-remote --tags "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@${clean_url}" "$RELEASE_TAG" 2>/dev/null | grep -q "$RELEASE_TAG"; then
            log_error "Configured release tag \"$RELEASE_TAG\" does not exist."
            log_info "Available tags:"
            git ls-remote --tags "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@${clean_url}" 2>/dev/null | awk -F'/' '{print $3}' | grep -v "\^{}" || true
            unset GITHUB_TOKEN
            exit 2
        fi
    fi
    
    # Build clone command
    local clone_cmd=(git clone --depth=1)
    if [[ "${CLONE_MODE:-tag}" == "tag" ]]; then
        clone_cmd+=(--branch "$RELEASE_TAG")
    else
        clone_cmd+=(--branch "${DEFAULT_BRANCH:-main}")
    fi
    clone_cmd+=("$auth_repo_url" "$APP_DIR")
    
    # Execute clone and capture stderr
    local tmp_git_log
    tmp_git_log=$(mktemp)
    
    log_info "Cloning repository..."
    if "${clone_cmd[@]}" >/dev/null 2>"$tmp_git_log"; then
        log_success "Repository cloned successfully."
    else
        log_error "GitHub cloning failed."
        log_error "Git output:"
        
        # Redact secrets
        local redacted_log
        redacted_log=$(sed -E "s|${GITHUB_TOKEN}|****|g" "$tmp_git_log" | sed -E "s|${GITHUB_USERNAME}|****|g")
        echo -e "${COLOR_WARN}${redacted_log}${COLOR_RESET}"
        
        # Ensure log output reaches installer log safely
        echo "$redacted_log" >> "$INSTALLER_LOG_FILE"
        
        rm -f "$tmp_git_log"
        unset GITHUB_TOKEN
        exit 2
    fi
    
    rm -f "$tmp_git_log"
    
    # Destroy Token & Remove Git Metadata
    unset GITHUB_TOKEN
    log_info "Removing Git metadata..."
    rm -rf "${APP_DIR}/.git"
}

laravel_install() {
    log_step "Deploying Laravel Application"
    
    clone_repository

    
    # 3. Composer Install
    log_info "Running composer install..."
    cd "$APP_DIR" || exit 2
    export COMPOSER_ALLOW_SUPERUSER=1
    composer install --no-dev --optimize-autoloader --no-interaction
    
    # 4. Generate .env
    log_info "Generating production .env file..."
    local env_template="${INSTALLER_DIR}/templates/.env.template"
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
