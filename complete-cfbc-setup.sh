#!/bin/bash

# Complete CFBC React Application Setup
# This script deploys the actual React app to replace the basic HTML

set -e

echo "=== Deploying Complete CFBC React Application ==="

APP_DIR="/var/www/cfbc-app"
CFBC_DIR="/var/www/cfbc"

# Stop existing processes
echo "1. Stopping existing applications..."
cd $CFBC_DIR
pm2 stop cfbc-updated 2>/dev/null || true
pm2 stop cfbc-app 2>/dev/null || true
pm2 delete cfbc-updated 2>/dev/null || true
pm2 delete cfbc-app 2>/dev/null || true

# Check for deployment package
if [ ! -f "cfbc-complete-deployment.tar.gz" ]; then
    echo "ERROR: cfbc-complete-deployment.tar.gz not found"
    echo ""
    echo "Please upload the deployment package:"
    echo "scp cfbc-complete-deployment.tar.gz root@your-server:/var/www/cfbc/"
    echo ""
    echo "The package should contain:"
    echo "- client/ (React frontend)"
    echo "- server/ (Express backend)"
    echo "- shared/ (Database schemas)"
    echo "- Configuration files"
    exit 1
fi

# Create new app directory
echo "2. Setting up React application directory..."
rm -rf $APP_DIR
mkdir -p $APP_DIR

# Extract the complete application
echo "3. Extracting complete React application..."
tar -xzf cfbc-complete-deployment.tar.gz -C $APP_DIR --strip-components=0

cd $APP_DIR

# Install dependencies
echo "4. Installing application dependencies..."
npm install --production

# Create production environment
echo "5. Creating production environment..."
cat > .env << 'ENV_EOF'
NODE_ENV=production
DATABASE_URL=postgresql://cfbc_user:SecurePassword123!@localhost:5432/cfbc_production
SESSION_SECRET=cfbc-production-secret-key-$(date +%s)
PORT=3000
ENV_EOF

# Build the React application
echo "6. Building React application..."
npm run build

# Start the complete React application
echo "7. Starting complete CFBC React application..."
pm2 start dist/index.js --name cfbc-react-app
pm2 save

# Wait for application to start
sleep 3

# Test the application
echo "8. Testing React application..."
if curl -s http://localhost:3000 | grep -q "Central Florida Bin Cleaning"; then
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    echo ""
    echo "SUCCESS! Complete CFBC React Application Deployed!"
    echo ""
    echo "=== Application Access ==="
    echo "URL: http://$SERVER_IP"
    echo "Type: Complete React Management System"
    echo ""
    echo "=== Login Accounts ==="
    echo "Admin: admin / admin123"
    echo "Customer: customer1 / customer123"
    echo "Driver: driver1 / driver123"
    echo "Dispatcher: dispatcher1 / dispatcher123"
    echo ""
    echo "=== Portal Access ==="
    echo "After login, visit /portal for role-specific dashboards"
    echo ""
    echo "=== Features Available ==="
    echo "✓ Customer Portal - Service scheduling and management"
    echo "✓ Driver Portal - Route management and job tracking"
    echo "✓ Dispatcher Portal - Job assignment and optimization"
    echo "✓ Admin Portal - User management and reporting"
    echo "✓ Multi-role authentication system"
    echo "✓ Professional React UI components"
    echo ""
    echo "=== Management ==="
    echo "Status: pm2 status"
    echo "Logs: pm2 logs cfbc-react-app"
    echo "Restart: pm2 restart cfbc-react-app"
    
    # Update PM2 status
    echo ""
    echo "=== Current PM2 Status ==="
    pm2 status
else
    echo ""
    echo "WARNING: Application may not have started correctly"
    echo "Check logs: pm2 logs cfbc-react-app"
    echo "Check build: ls -la dist/"
fi

echo ""
echo "Complete CFBC React Application deployment finished!"