# Photo Proofing Portal

A professional photo proofing and approval system built with FastAPI, PostgreSQL, and Caddy.

## Features

- 🚀 FastAPI backend with automatic API documentation
- 🐘 PostgreSQL database with migrations
- 🔒 Caddy reverse proxy with automatic HTTPS
- 🐳 Docker Compose for development and production
- 🔄 CI/CD pipeline with GitHub Actions
- 📦 Container registry integration (GHCR)
- 🔧 Development tools and hot-reload
- 📊 Health checks and monitoring
- 🗂️ Media file management
- 🔐 Security-focused configuration

## Quick Start

### Prerequisites

- Docker and Docker Compose v2
- Git
- Make (optional, for convenience commands)

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/flexter666/photo-proofing.git
   cd photo-proofing
   ```

2. **Create environment file**
   ```bash
   cp .env.example .env
   # Edit .env with your local settings (defaults work for development)
   ```

3. **Start development environment**
   ```bash
   make dev
   # or
   docker compose up --build
   ```

4. **Access the application**
   - API: http://localhost:8000
   - API Documentation: http://localhost:8000/docs
   - Database: localhost:5432 (postgres/postgres)

### Available Make Commands

```bash
make help          # Show all available commands
make dev           # Start development environment
make dev-d         # Start development in background
make build         # Build production image
make test          # Run tests
make fmt           # Format code
make lint          # Lint code
make db-migrate    # Run database migrations
make db-reset      # Reset database (WARNING: deletes data)
make shell         # Open shell in web container
make clean         # Clean up Docker resources
```

## Production Deployment

### Server Setup

1. **Prepare the server** (run as root on fresh Debian/Ubuntu server):
   ```bash
   curl -fsSL https://raw.githubusercontent.com/flexter666/photo-proofing/main/scripts/server-setup.sh | bash
   ```

2. **Configure SSH access**:
   - Add your SSH public key to `/home/proofing/.ssh/authorized_keys`
   - Test SSH connection: `ssh proofing@your-server-ip`

3. **Configure environment**:
   ```bash
   cd /opt/photo-proofing
   cp .env.example .env
   # Edit .env with production settings
   ```

### GitHub Secrets Configuration

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DEPLOY_HOST` | Server IP or hostname | `192.168.1.100` |
| `DEPLOY_USER` | SSH username | `proofing` |
| `DEPLOY_PATH` | Deployment directory | `/opt/photo-proofing` |
| `DEPLOY_SSH_KEY` | Private SSH key | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `DEPLOY_PORT` | SSH port (optional) | `22` |
| `DATABASE_URL` | Production database URL | `postgresql://user:pass@db:5432/proofing` |
| `SECRET_KEY` | Application secret key | `your-very-long-random-secret-key` |
| `DOMAIN` | Your domain name | `photos.yourdomain.com` |

### Domain Configuration

1. **DNS Setup**: Point your domain to your server's IP address
2. **Update Caddyfile**: Edit `caddy/Caddyfile` and replace `your-domain.com` with your actual domain
3. **Configure Let's Encrypt**: Uncomment and set your email in the Caddyfile for SSL certificates

### Deployment Process

1. **Push to main branch** - triggers automatic deployment via GitHub Actions
2. **Manual deployment** (if needed):
   ```bash
   ssh proofing@your-server
   cd /opt/photo-proofing
   ./scripts/deploy.sh
   ```

### NAS Integration

If you have a NAS mounted at `/mnt/nas/proofing`, the deployment script will detect it automatically. To manually configure:

1. Update `docker-compose.yml` media volume:
   ```yaml
   volumes:
     media:
       driver: local
       driver_opts:
         type: none
         o: bind
         device: /mnt/nas/proofing
   ```

## Development

### Project Structure

```
├── app/                    # FastAPI application
│   ├── __init__.py
│   └── main.py            # Main application file
├── tests/                 # Test files
├── scripts/               # Deployment scripts
├── caddy/                 # Caddy configuration
├── .github/workflows/     # CI/CD pipelines
├── docker-compose.yml     # Production compose
├── docker-compose.override.yml  # Development overrides
├── Dockerfile            # Application container
├── requirements.txt      # Python dependencies
├── .env.example         # Environment template
└── Makefile            # Development commands
```

### Adding New Features

1. **Create feature branch**: `git checkout -b feature/your-feature`
2. **Develop with hot-reload**: `make dev`
3. **Add tests**: Add tests in `tests/` directory
4. **Run quality checks**: `make lint && make fmt && make test`
5. **Create pull request**: Push branch and create PR

### Database Migrations

```bash
# Create new migration
make db-migration name="add_users_table"

# Run migrations
make db-migrate

# Reset database (development only)
make db-reset
```

### Testing

```bash
# Run all tests
make test

# Run tests with coverage
make test-coverage

# Run specific test file
docker compose run --rm web python -m pytest tests/test_main.py -v
```

## Monitoring and Maintenance

### Health Checks

- Application: `curl http://localhost:8000/health`
- Services: `docker compose ps`
- Logs: `docker compose logs -f`

### Backups

```bash
# Create backup
./scripts/deploy.sh --backup

# Restore from backup
make restore file=backups/backup_20231201_120000.sql.gz
```

### Updating

1. **Update code**: Push changes to main branch (triggers auto-deployment)
2. **Update dependencies**: Modify `requirements.txt` and rebuild
3. **Update infrastructure**: Modify Docker Compose files as needed

## Troubleshooting

### Common Issues

1. **Port already in use**: Stop conflicting services or change ports in `docker-compose.override.yml`
2. **Permission errors**: Ensure proper file ownership: `sudo chown -R $USER:$USER .`
3. **Database connection issues**: Check if PostgreSQL container is healthy: `docker compose ps`
4. **SSL certificate issues**: Verify domain DNS and Caddy logs: `docker compose logs caddy`

### Getting Help

1. **Check logs**: `docker compose logs -f [service_name]`
2. **Access container shell**: `make shell`
3. **Database shell**: `make db-shell`
4. **Health checks**: Visit `/health` endpoint

## Security

- Secrets are never committed to the repository
- All services run with restart policies
- Firewall configured to allow only necessary ports
- Automatic security updates enabled
- SSL/TLS certificates auto-renewed by Caddy

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass and code is properly formatted
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
