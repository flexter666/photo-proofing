#!/bin/bash

# Photo Proofing Portal - Deployment Script
# This script handles the deployment process on the server

set -e

# Configuration
PROJECT_NAME="photo-proofing"
DEPLOY_PATH="${DEPLOY_PATH:-/opt/photo-proofing}"
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   warn "This script should not be run as root for security reasons."
fi

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
fi

if ! docker info &> /dev/null; then
    error "Docker daemon is not running or current user doesn't have permission."
fi

# Check if docker-compose is available
if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    error "Docker Compose (v2) is not available. Please install Docker Compose v2."
fi

# Navigate to deployment directory
log "Navigating to deployment directory: $DEPLOY_PATH"
cd "$DEPLOY_PATH" || error "Could not navigate to $DEPLOY_PATH"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    error ".env file not found. Please create it from .env.example"
fi

# Backup current state (optional)
if [ "$1" = "--backup" ]; then
    log "Creating backup..."
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup database
    if docker compose ps db | grep -q "Up"; then
        log "Backing up database..."
        docker compose exec -T db pg_dump -U postgres proofing | gzip > "$BACKUP_DIR/database.sql.gz"
    fi
    
    # Backup media files
    if [ -d "media" ]; then
        log "Backing up media files..."
        tar -czf "$BACKUP_DIR/media.tar.gz" media/
    fi
    
    log "Backup completed in $BACKUP_DIR"
fi

# Check if NAS mount exists and update docker-compose accordingly
if [ -d "/mnt/nas/proofing" ]; then
    log "NAS mount detected at /mnt/nas/proofing"
    # TODO: Update docker-compose.yml to use NAS mount for media volume
    warn "NAS mount detected but not automatically configured. Please update docker-compose.yml manually."
else
    log "No NAS mount detected, using local volume for media"
fi

# Pull latest images
log "Pulling latest Docker images..."
docker compose -f "$COMPOSE_FILE" pull

# Stop services gracefully
log "Stopping services..."
docker compose -f "$COMPOSE_FILE" down --timeout 30

# Start services
log "Starting services..."
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans

# Wait for services to be healthy
log "Waiting for services to be healthy..."
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if docker compose -f "$COMPOSE_FILE" ps --services --filter "status=running" | grep -q "web"; then
        if docker compose -f "$COMPOSE_FILE" exec -T web curl -f http://localhost:8000/health &> /dev/null; then
            log "Services are healthy!"
            break
        fi
    fi
    sleep 5
    elapsed=$((elapsed + 5))
    echo -n "."
done

if [ $elapsed -ge $timeout ]; then
    error "Services failed to become healthy within $timeout seconds"
fi

# Run database migrations
log "Running database migrations..."
docker compose -f "$COMPOSE_FILE" exec -T web alembic upgrade head || warn "Migration failed or not configured"

# Clean up old images
log "Cleaning up old Docker images..."
docker image prune -f

# Show status
log "Deployment completed successfully!"
log "Services status:"
docker compose -f "$COMPOSE_FILE" ps

log "Application should be available at your configured domain"
log "Check logs with: docker compose -f $COMPOSE_FILE logs -f"