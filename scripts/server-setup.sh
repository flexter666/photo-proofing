#!/bin/bash

# Photo Proofing Portal - Server Setup Script
# This script prepares a fresh Debian server for deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_USER="${DEPLOY_USER:-proofing}"
DEPLOY_PATH="${DEPLOY_PATH:-/opt/photo-proofing}"
PROJECT_REPO="${PROJECT_REPO:-https://github.com/flexter666/photo-proofing.git}"

# Logging functions
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root for initial server setup"
fi

log "Starting Photo Proofing Portal server setup..."

# Update system packages
log "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install essential packages
log "Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    nano \
    ufw \
    fail2ban \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    logrotate

# Install Docker
log "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker
    
    log "Docker installed successfully"
else
    log "Docker is already installed"
fi

# Create deployment user
log "Creating deployment user: $DEPLOY_USER"
if ! id "$DEPLOY_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$DEPLOY_USER"
    usermod -aG docker "$DEPLOY_USER"
    log "User $DEPLOY_USER created and added to Docker group"
else
    log "User $DEPLOY_USER already exists"
    usermod -aG docker "$DEPLOY_USER"
fi

# Create deployment directory
log "Creating deployment directory: $DEPLOY_PATH"
mkdir -p "$DEPLOY_PATH"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$DEPLOY_PATH"

# Setup SSH directory for deployment user
log "Setting up SSH access for deployment user..."
sudo -u "$DEPLOY_USER" mkdir -p "/home/$DEPLOY_USER/.ssh"
chmod 700 "/home/$DEPLOY_USER/.ssh"
touch "/home/$DEPLOY_USER/.ssh/authorized_keys"
chmod 600 "/home/$DEPLOY_USER/.ssh/authorized_keys"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"

# Configure firewall
log "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Setup log rotation for Docker
log "Setting up log rotation for Docker..."
cat > /etc/logrotate.d/docker-containers << EOF
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=10M
    missingok
    delaycompress
    copytruncate
}
EOF

# Create NAS mount point if it doesn't exist
log "Creating NAS mount point..."
mkdir -p /mnt/nas/proofing
chown -R "$DEPLOY_USER:$DEPLOY_USER" /mnt/nas

# Clone repository to deployment directory
log "Cloning repository to deployment directory..."
sudo -u "$DEPLOY_USER" git clone "$PROJECT_REPO" "$DEPLOY_PATH" || {
    warn "Repository clone failed or directory already exists"
    if [ -d "$DEPLOY_PATH/.git" ]; then
        log "Repository already exists, pulling latest changes..."
        sudo -u "$DEPLOY_USER" bash -c "cd $DEPLOY_PATH && git pull"
    fi
}

# Set proper permissions
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$DEPLOY_PATH"

# Create systemd service for the application (optional)
log "Creating systemd service..."
cat > /etc/systemd/system/photo-proofing.service << EOF
[Unit]
Description=Photo Proofing Portal
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$DEPLOY_PATH
ExecStart=/usr/bin/docker compose -f docker-compose.yml up -d
ExecStop=/usr/bin/docker compose -f docker-compose.yml down
User=$DEPLOY_USER
Group=$DEPLOY_USER

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable photo-proofing.service

# Create backup directory
log "Creating backup directory..."
mkdir -p "$DEPLOY_PATH/backups"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$DEPLOY_PATH/backups"

# Setup backup cron job
log "Setting up backup cron job..."
sudo -u "$DEPLOY_USER" crontab -l 2>/dev/null | { cat; echo "0 2 * * * cd $DEPLOY_PATH && /bin/bash scripts/deploy.sh --backup > /tmp/backup.log 2>&1"; } | sudo -u "$DEPLOY_USER" crontab -

log "Server setup completed successfully!"
echo ""
info "Next steps:"
echo "1. Add your SSH public key to /home/$DEPLOY_USER/.ssh/authorized_keys"
echo "2. Copy .env.example to .env and configure with your settings"
echo "3. Update GitHub repository secrets with server details:"
echo "   - DEPLOY_HOST: $(curl -s ifconfig.me || hostname -I | awk '{print $1}')"
echo "   - DEPLOY_USER: $DEPLOY_USER"
echo "   - DEPLOY_PATH: $DEPLOY_PATH"
echo "   - DEPLOY_SSH_KEY: (your private SSH key)"
echo "4. Configure your domain DNS to point to this server"
echo "5. Update Caddyfile with your domain name"
echo ""
info "The application can be managed with:"
echo "- Start: systemctl start photo-proofing"
echo "- Stop: systemctl stop photo-proofing"
echo "- Status: systemctl status photo-proofing"
echo "- Logs: journalctl -u photo-proofing -f"
echo ""
info "Manual deployment: cd $DEPLOY_PATH && sudo -u $DEPLOY_USER bash scripts/deploy.sh"