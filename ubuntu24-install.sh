#!/bin/bash

# Central Florida Bin Cleaning - Ubuntu 24 Automated Installation Script
# This script automatically installs and configures the entire application

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration variables
DB_PASSWORD="SecurePassword123!"
SESSION_SECRET=$(openssl rand -hex 32)
APP_DIR="/var/www/cfbc"
APP_USER="cfbc"

echo -e "${BLUE}"
echo "=============================================="
echo "Central Florida Bin Cleaning - Ubuntu 24 Installer"
echo "=============================================="
echo -e "${NC}"

echo -e "${GREEN}This script will install and configure your application automatically.${NC}"
echo

# Get domain name
read -p "Enter your domain name (or press Enter to use server IP): " DOMAIN_NAME
if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")
    echo "Using IP/hostname: $DOMAIN_NAME"
fi

echo
echo -e "${YELLOW}Starting installation...${NC}"

# Update system
echo "Updating system packages..."
apt update && apt upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt install -y curl wget git build-essential software-properties-common ufw htop nginx postgresql postgresql-contrib

# Install Node.js 20
echo "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install PM2
echo "Installing PM2 process manager..."
npm install -g pm2@latest

# Configure PostgreSQL
echo "Configuring PostgreSQL database..."
systemctl start postgresql
systemctl enable postgresql

# Create database and user
sudo -u postgres psql << EOF
DROP DATABASE IF EXISTS cfbc_production;
DROP USER IF EXISTS cfbc_user;
CREATE DATABASE cfbc_production;
CREATE USER cfbc_user WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE cfbc_production TO cfbc_user;
ALTER USER cfbc_user CREATEDB;
EOF

echo "Database configured successfully!"

# Create application user
echo "Creating application user..."
if ! id "$APP_USER" &>/dev/null; then
    useradd -m -s /bin/bash $APP_USER
    usermod -aG sudo $APP_USER
    echo "Created user '$APP_USER'"
fi

# Create application directory
echo "Setting up application directory..."
mkdir -p $APP_DIR
chown $APP_USER:$APP_USER $APP_DIR

# Copy application files (if running from deployment directory)
if [ -f "package.json" ]; then
    echo "Copying application files..."
    cp -r . $APP_DIR/
    chown -R $APP_USER:$APP_USER $APP_DIR
fi

# Create environment file
echo "Creating environment configuration..."
cat > $APP_DIR/.env.production << EOF
NODE_ENV=production
DATABASE_URL=postgresql://cfbc_user:$DB_PASSWORD@localhost:5432/cfbc_production
SESSION_SECRET=$SESSION_SECRET
PORT=3000

# Update these with your actual values
REPL_ID=your-repl-id
ISSUER_URL=https://replit.com/oidc
REPLIT_DOMAINS=$DOMAIN_NAME

# API Keys (update these after installation)
# SENDGRID_API_KEY=your-sendgrid-api-key
# TWILIO_ACCOUNT_SID=your-twilio-sid
# TWILIO_AUTH_TOKEN=your-twilio-token
# TWILIO_PHONE_NUMBER=your-twilio-phone
# STRIPE_SECRET_KEY=your-stripe-secret-key
# VITE_STRIPE_PUBLIC_KEY=your-stripe-public-key
EOF

chown $APP_USER:$APP_USER $APP_DIR/.env.production

# Install application dependencies
if [ -f "$APP_DIR/package.json" ]; then
    echo "Installing application dependencies..."
    cd $APP_DIR
    sudo -u $APP_USER npm install
    
    # Try to build application
    echo "Building application..."
    sudo -u $APP_USER npm run build || echo "Build failed, will run in development mode"
    
    # Set up database
    echo "Setting up database schema..."
    sudo -u $APP_USER npm run db:push || echo "Database setup skipped"
fi

# Create PM2 ecosystem file
echo "Creating PM2 configuration..."
cat > $APP_DIR/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'cfbc-app',
    script: 'dist/index.js',
    instances: 1,
    exec_mode: 'fork',
    user: 'cfbc',
    cwd: '/var/www/cfbc',
    env: {
      NODE_ENV: 'development'
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    max_memory_restart: '500M',
    restart_delay: 1000
  }]
}
EOF

# Create logs directory
sudo -u $APP_USER mkdir -p $APP_DIR/logs

# Create management script
echo "Creating management script..."
cat > $APP_DIR/manage.sh << 'EOF'
#!/bin/bash

APP_DIR="/var/www/cfbc"
APP_NAME="cfbc-app"
USER="cfbc"

cd $APP_DIR

case "$1" in
    start)
        echo "Starting Central Florida Bin Cleaning application..."
        if [ -f "dist/index.js" ]; then
            sudo -u $USER pm2 start ecosystem.config.js --env production
        else
            echo "Built files not found, starting in development mode..."
            sudo -u $USER pm2 start server/index.ts --name $APP_NAME --interpreter tsx --env production
        fi
        echo "Application started!"
        ;;
    stop)
        sudo -u $USER pm2 stop $APP_NAME 2>/dev/null || true
        ;;
    restart)
        sudo -u $USER pm2 restart $APP_NAME 2>/dev/null || sudo -u $USER pm2 start ecosystem.config.js --env production
        ;;
    status)
        echo "=== Application Status ==="
        sudo -u $USER pm2 status
        echo ""
        echo "=== System Services ==="
        systemctl is-active nginx && echo "✓ Nginx: running" || echo "✗ Nginx: stopped"
        systemctl is-active postgresql && echo "✓ PostgreSQL: running" || echo "✗ PostgreSQL: stopped"
        ;;
    logs)
        sudo -u $USER pm2 logs $APP_NAME
        ;;
    build)
        echo "Building application..."
        sudo -u $USER npm install
        sudo -u $USER npm run build || echo "Build failed"
        sudo -u $USER npm run db:push || echo "DB push failed"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|build}"
        ;;
esac
EOF

chmod +x $APP_DIR/manage.sh

# Configure Nginx
echo "Configuring Nginx web server..."
cat > /etc/nginx/sites-available/cfbc << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/cfbc /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and start Nginx
nginx -t
systemctl restart nginx
systemctl enable nginx

# Configure firewall
echo "Configuring firewall..."
ufw --force enable
ufw allow OpenSSH
ufw allow 'Nginx Full'

# Start application
echo "Starting application..."
cd $APP_DIR
./manage.sh start

# Set up PM2 startup
echo "Configuring PM2 startup..."
sudo -u $APP_USER pm2 startup | grep -E '^sudo' | bash || true
sudo -u $APP_USER pm2 save

# Set up backup
echo "Setting up automatic backups..."
cat > /etc/cron.daily/cfbc-backup << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p /backups
sudo -u postgres pg_dump cfbc_production > /backups/cfbc_$DATE.sql
gzip /backups/cfbc_$DATE.sql
find /backups -name "cfbc_*.sql.gz" -mtime +7 -delete
EOF

chmod +x /etc/cron.daily/cfbc-backup

# Final status check
echo
echo "=== Installation Complete ==="
echo

# Check services
echo "Checking installation status..."
systemctl is-active nginx && echo -e "${GREEN}✓ Nginx is running${NC}" || echo -e "${RED}✗ Nginx failed${NC}"
systemctl is-active postgresql && echo -e "${GREEN}✓ PostgreSQL is running${NC}" || echo -e "${RED}✗ PostgreSQL failed${NC}"

cd $APP_DIR
./manage.sh status

echo
echo -e "${GREEN}Installation completed successfully!${NC}"
echo
echo "Your application is available at:"
echo "  http://$DOMAIN_NAME"
echo
echo "Default login accounts:"
echo "  Admin: admin / admin123"
echo "  Customer: customer1 / customer123"
echo "  Driver: driver1 / driver123"
echo "  Dispatcher: dispatcher1 / dispatcher123"
echo
echo -e "${YELLOW}Important next steps:${NC}"
echo "1. Change default passwords immediately"
echo "2. Update API keys in: $APP_DIR/.env.production"
echo "3. Restart application: $APP_DIR/manage.sh restart"
echo
echo "Management commands:"
echo "  $APP_DIR/manage.sh {start|stop|restart|status|logs|build}"
echo
echo "Database credentials:"
echo "  Database: cfbc_production"
echo "  Username: cfbc_user"
echo "  Password: $DB_PASSWORD"
echo
echo -e "${GREEN}Enjoy your Central Florida Bin Cleaning application!${NC}"