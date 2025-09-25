#!/usr/bin/env bash
set -euo pipefail

# Elderly Daycare Platform — Developer Bootstrap Script (Phase A)
# Purpose: streamline local setup by fetching development secrets and provisioning prerequisites.
# NOTE: This script is a scaffold and will be expanded in Phase B once Vault and service accounts are provisioned.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VAULT_ADDR="${VAULT_ADDR:-https://vault.dev.elderly-daycare.com}"
VAULT_ROLE="${VAULT_ROLE:-dev-backend}"  # Update once roles are finalized
ENV_FILE="$PROJECT_ROOT/.env"

log() {
  printf '\n[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1"
}

require_binary() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing dependency: $1. Please install it before proceeding."
    exit 1
  fi
}

main() {
  log "Validating prerequisites"
  require_binary vault
  require_binary jq

  if [ -f "$ENV_FILE" ]; then
    log ".env already exists. Skipping secret fetch. Remove the file to regenerate."
    exit 0
  fi

  log "Authenticating with Vault (role: $VAULT_ROLE)"
  # Placeholder for Vault login via OIDC or CLI auth method
  # Example:
  # vault login -method=oidc role=$VAULT_ROLE

  log "Fetching development secrets"
  # Example secret retrieval (to be implemented):
  # DB_JSON=$(vault kv get -format=json secret/data/app/dev/database | jq -r '.data.data')
  # DB_HOST=$(echo "$DB_JSON" | jq -r '.host')

  log "Writing .env file"
  cat >"$ENV_FILE" <<'EOF'
APP_NAME="Elderly Daycare Platform"
APP_ENV=local
APP_KEY=  # run `php artisan key:generate`
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=elderly_daycare_dev
DB_USERNAME=dev_user
DB_PASSWORD=change_me

# Placeholder secrets — replace with values fetched from Vault
MAIL_MAILER=log
STRIPE_KEY=pk_test_placeholder
STRIPE_SECRET=sk_test_placeholder

# Queue/Cache defaults
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
EOF

  log "Reminder: update placeholders with fetched secrets once automation is implemented."
  log "Run 'php artisan key:generate' and 'docker-compose up -d' to complete setup."
}

main "$@"
