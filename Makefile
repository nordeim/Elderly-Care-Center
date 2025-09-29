up: ## Build and start containers
    docker compose up --build -d

down: ## Stop and remove containers and volumes
    docker compose down -v

restart: ## Restart app container
    docker restart elderly-app

logs: ## Tail app logs
    docker logs -f elderly-app

migrate: ## Run migrations
    docker exec elderly-app php artisan migrate

migrate:fresh: ## Drop all tables and re-run migrations
    docker exec elderly-app php artisan migrate:fresh --seed

migrate:refresh: ## Rollback and re-run all migrations
    docker exec elderly-app php artisan migrate:refresh

migrate:rollback: ## Rollback last migration batch
    docker exec elderly-app php artisan migrate:rollback

migrate:status: ## Show migration status
    docker exec elderly-app php artisan migrate:status

seed: ## Run database seeders
    docker exec elderly-app php artisan db:seed

tinker: ## Open Laravel tinker shell
    docker exec -it elderly-app php artisan tinker

artisan: ## Run arbitrary artisan command
    docker exec -it elderly-app php artisan

bash: ## Open container shell
    docker exec -it elderly-app bash

health: ## Check health endpoint
    curl -fsS http://localhost:8000/healthz

cache: ## Build Laravel caches
    docker exec elderly-app php artisan config:cache && \
    docker exec elderly-app php artisan route:cache && \
    docker exec elderly-app php artisan view:cache

clear: ## Clear Laravel caches
    docker exec elderly-app php artisan config:clear || true && \
    docker exec elderly-app php artisan route:clear || true && \
    docker exec elderly-app php artisan view:clear || true

test: ## Run PHPUnit tests
    docker exec elderly-app php artisan test

lint: ## Run Laravel Pint or PHP-CS-Fixer
    docker exec elderly-app ./vendor/bin/pint

npm-dev: ## Start Vite development server (CTRL+C to stop)
    docker compose exec -it elderly-app npm run dev

npm-build: ## Build frontend assets for production
    docker compose exec elderly-app npm run build

npm-ci: ## Reinstall Node dependencies inside container
    docker compose exec elderly-app npm ci

env:check: ## Validate required .env variables
    grep -E '^APP_KEY=|^DB_HOST=|^DB_DATABASE=|^DB_USERNAME=|^DB_PASSWORD=' .env || echo "Missing required .env vars"

key:check: ## Check APP_KEY presence
    grep -E '^APP_KEY=.+$' .env || echo "APP_KEY missing or empty"

reset: ## Stop containers and remove volumes
    docker compose down -v && docker volume prune -f

prune: ## Remove dangling images and volumes
    docker system prune -f && docker volume prune -f

help: ## Show available commands
    @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

