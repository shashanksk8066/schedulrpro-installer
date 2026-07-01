# Schedulr Pro Deployment Framework

This is the production-grade deployment framework for **Schedulr Pro**. It is designed to automatically provision an Ubuntu 24.04 LTS server, install all necessary dependencies, clone the application repository securely, and deploy it fully configured with SSL, queue workers, and optimization.

## Architecture

The framework is highly modular, separating core execution logic from system preparation and application deployment.

### Design Principles
1. **Single Responsibility Principle**: Every module manages one specific component.
2. **Modular Architecture**: Clean separation between core, system, and application layers.
3. **Idempotent Execution**: Running the installer multiple times produces the exact same deterministic state.
4. **Least Privilege Security**: Uses the minimum permissions necessary (e.g., Read-Only GitHub tokens).
5. **Fail Fast**: Aborts immediately upon encountering a critical failure.
6. **Safe Rollback**: Reverts destructive changes safely without affecting unrelated server applications.
7. **Resume Support**: Gracefully skips completed tasks upon restart.
8. **Deterministic Deployment**: Eliminates environmental variables by explicitly controlling all dependencies.
9. **Zero Hardcoded Configuration**: Centralized configuration management via `config/config.sh`.
10. **Production First**: Built exclusively for commercial production deployments.

### Directory Structure

```text
installer/
├── install.sh
├── README.md
├── config/
│   └── config.sh
├── lib/
│   ├── core/
│   │   ├── logger.sh
│   │   ├── common.sh
│   │   ├── validation.sh
│   │   ├── rollback.sh
│   │   └── report.sh
│   ├── system/
│   │   ├── packages.sh
│   │   ├── php.sh
│   │   ├── composer.sh
│   │   ├── mysql.sh
│   │   ├── nginx.sh
│   │   ├── supervisor.sh
│   │   └── ssl.sh
│   └── application/
│       ├── laravel.sh
│       ├── permissions.sh
│       ├── optimization.sh
│       └── verification.sh
├── hooks/
│   ├── pre-install.sh
│   ├── post-install.sh
│   └── ...
└── templates/
    ├── nginx.conf
    ├── .env.template
    └── supervisor-*.conf
```

### Flow Diagram

```
install.sh
        │
        ▼
Configuration
        │
        ▼
Validation
        │
        ▼
Hooks (Pre)
        │
        ▼
Core Modules
        │
        ▼
System Modules
        │
        ▼
Application Modules
        │
        ▼
Verification
        │
        ▼
Reporting
        │
        ▼
Hooks (Post)
        │
        ▼
Installation Complete
```

## Configuration

Upload limits and performance parameters can be tailored for production before installation by modifying `config/config.sh`. The installer automatically configures these across both PHP and Nginx:
- `UPLOAD_MAX_FILESIZE` (e.g. 512M)
- `POST_MAX_SIZE`
- `CLIENT_MAX_BODY_SIZE`
- `PHP_MEMORY_LIMIT`
- `PHP_MAX_EXECUTION_TIME`

## Development Workflow

The installer always installs the latest code from the configured branch (e.g., `main`). There is no Git Tag management required.

```text
Developer
   │
   ├──> git add .
   ├──> git commit -m "Some Fix"
   └──> git push origin main
              │
              ▼
           Installer
              │
              ├──> Clones latest main
              └──> Installs and Deploys
```

## How to Run

1. Clone or copy this installer directory to the target Ubuntu server.
2. Execute the master orchestrator as root:
   ```bash
   sudo bash install.sh
   ```
3. Provide the requested inputs (Domain, Email, GitHub PAT).
4. Wait for the installation to complete.

## Adding Future Modules

To add a new step (e.g., `redis`):
1. Create `lib/system/redis.sh`.
2. Implement the standard interface:
   - `redis_check()`
   - `redis_install()`
   - `redis_verify()`
   - `redis_rollback()`
3. Source it in `install.sh`.
4. Add it to the execution loop array in `install.sh`.

## Security

* **GitHub Token**: The Personal Access Token (PAT) is requested silently, kept only in memory, and immediately unset after the repository is cloned.
* **Metadata Removal**: The `.git` directory is deleted post-clone to ensure history privacy and isolate the deployment.
* **Logging**: All logs are sanitized. Secrets are never written to disk.
# schedulrpro-installer
