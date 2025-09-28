# Photo Proofing Portal - Development Makefile

.PHONY: help dev build test fmt lint clean logs shell db-shell backup restore

# Default target
help: ## Show this help message
	@echo "Photo Proofing Portal - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Development
dev: ## Start development environment with hot reload
	@echo "Starting development environment..."
	@docker compose up --build

dev-d: ## Start development environment in background
	@echo "Starting development environment in background..."
	@docker compose up --build -d

dev-logs: ## Show development logs
	@docker compose logs -f

# Building
build: ## Build production Docker image
	@echo "Building production image..."
	@docker build -t ghcr.io/$${GHCR_OWNER:-your-org}/photo-proofing:local .

build-prod: ## Build and tag production image
	@echo "Building production image with proper tags..."
	@docker build -t ghcr.io/$${GHCR_OWNER:-your-org}/photo-proofing:$${VERSION:-latest} .
	@docker build -t ghcr.io/$${GHCR_OWNER:-your-org}/photo-proofing:$$(git rev-parse --short HEAD) .

# Testing
test: ## Run tests (requires test setup)
	@echo "Running tests..."
	@docker compose run --rm web python -m pytest tests/ -v

test-coverage: ## Run tests with coverage report
	@echo "Running tests with coverage..."
	@docker compose run --rm web python -m pytest tests/ --cov=app --cov-report=html

# Code Quality
fmt: ## Format code with black and isort
	@echo "Formatting code..."
	@docker compose run --rm web python -m black app/
	@docker compose run --rm web python -m isort app/

lint: ## Lint code with flake8 and mypy
	@echo "Linting code..."
	@docker compose run --rm web python -m flake8 app/
	@docker compose run --rm web python -m mypy app/

# Database
db-migrate: ## Run database migrations
	@echo "Running database migrations..."
	@docker compose run --rm web alembic upgrade head

db-migration: ## Create new database migration (usage: make db-migration name="migration_name")
	$(eval name ?= auto_migration)
	@echo "Creating new migration: $(name)"
	@docker compose run --rm web alembic revision --autogenerate -m "$(name)"

db-reset: ## Reset database (WARNING: deletes all data)
	@echo "WARNING: This will delete all database data!"
	@read -p "Are you sure? [y/N] " -n 1 -r; echo; if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		docker volume rm photo-proofing_postgres_dev_data 2>/dev/null || true; \
		docker compose up -d db; \
		sleep 5; \
		$(MAKE) db-migrate; \
	fi

# Utilities
shell: ## Open shell in web container
	@docker compose run --rm web /bin/bash

db-shell: ## Open PostgreSQL shell
	@docker compose exec db psql -U postgres -d proofing_dev

logs: ## Show all service logs
	@docker compose logs -f

clean: ## Clean up Docker resources
	@echo "Cleaning up Docker resources..."
	@docker compose down -v
	@docker system prune -f
	@docker volume prune -f

# Production
prod-up: ## Start production environment
	@echo "Starting production environment..."
	@docker compose -f docker-compose.yml up -d

prod-down: ## Stop production environment
	@echo "Stopping production environment..."
	@docker compose -f docker-compose.yml down

prod-logs: ## Show production logs
	@docker compose -f docker-compose.yml logs -f

# Backup and Restore
backup: ## Backup database
	@echo "Creating database backup..."
	@mkdir -p backups
	@docker compose exec db pg_dump -U postgres proofing_dev | gzip > backups/backup_$$(date +%Y%m%d_%H%M%S).sql.gz
	@echo "Backup saved to backups/"

restore: ## Restore database from backup file (usage: make restore file="backup_file.sql.gz")
	$(eval file ?= )
	@if [ -z "$(file)" ]; then echo "Usage: make restore file=backup_file.sql.gz"; exit 1; fi
	@echo "Restoring database from $(file)..."
	@gunzip -c $(file) | docker compose exec -T db psql -U postgres -d proofing_dev

# Install development dependencies
install-dev: ## Install development dependencies
	@echo "Installing development dependencies..."
	@pip install -r requirements-dev.txt