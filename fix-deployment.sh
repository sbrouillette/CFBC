#!/bin/bash

# Fix CFBC React Application Deployment
# Install all dependencies and build properly

set -e

echo "=== Fixing CFBC React Application Build ==="

APP_DIR="/var/www/cfbc-app"

cd $APP_DIR

# Stop any running processes
echo "1. Stopping existing processes..."
pm2 stop cfbc-react-app 2>/dev/null || true
pm2 delete cfbc-react-app 2>/dev/null || true

# Install ALL dependencies (including dev dependencies for build)
echo "2. Installing ALL dependencies including build tools..."
npm install

# Build the React application with all tools available
echo "3. Building React application..."
npm run build

# Check if build was successful
if [ -d "dist" ] && [ -f "dist/index.js" ]; then
    echo "4. Build successful! Starting application..."
    
    # Start the complete React application
    pm2 start dist/index.js --name cfbc-react-app
    pm2 save
    
    # Wait for startup
    sleep 3
    
    # Test the application
    if curl -s http://localhost:3000 > /dev/null; then
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
        
        echo ""
        echo "SUCCESS! Complete CFBC React Application is now running!"
        echo ""
        echo "=== Access Information ==="
        echo "URL: http://$SERVER_IP"
        echo "Application: Complete React Management System"
        echo ""
        echo "=== Login Credentials ==="
        echo "Admin Portal: admin / admin123"
        echo "Customer Portal: customer1 / customer123"
        echo "Driver Portal: driver1 / driver123"
        echo "Dispatcher Portal: dispatcher1 / dispatcher123"
        echo ""
        echo "=== How to Access Portals ==="
        echo "1. Visit http://$SERVER_IP"
        echo "2. Login with any of the accounts above"
        echo "3. After login, visit /portal to access your role-specific dashboard"
        echo ""
        echo "=== Available Features ==="
        echo "✓ Customer Portal - Service requests, scheduling, payment history"
        echo "✓ Driver Portal - Route management, job tracking, GPS navigation"
        echo "✓ Dispatcher Portal - Job assignment, route optimization"
        echo "✓ Admin Portal - User management, system configuration, reports"
        echo ""
        echo "=== Current PM2 Status ==="
        pm2 status
        
    else
        echo "WARNING: Application may not be responding on port 3000"
        echo "Check logs: pm2 logs cfbc-react-app"
    fi
    
else
    echo "ERROR: Build failed! Missing dist directory or index.js"
    echo "Check build logs above for errors"
    echo "Contents of current directory:"
    ls -la
fi

echo ""
echo "Deployment fix completed!"