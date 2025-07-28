#!/bin/bash

# Deploy complete CFBC React application from Replit to Ubuntu
set -e

echo "=== Deploying Complete CFBC React Application ==="

# You need to create a complete deployment package
echo "Creating deployment package with all files..."

cat << 'PACKAGE_INFO' > README_DEPLOYMENT.md
# Central Florida Bin Cleaning - Complete Application Deployment

This script will deploy the complete React application with:

## Features Included:
- Multi-role authentication system
- Customer Portal with service requests
- Driver Portal with route management  
- Dispatcher Portal with job assignment
- Admin Portal with user management
- PostgreSQL database integration
- Session management
- Complete UI components

## Files Required:
You need to transfer these files from your Replit project:

### Frontend (client/):
- client/src/App.tsx
- client/src/pages/*.tsx (all portal files)
- client/src/components/ui/*.tsx
- client/src/hooks/*.ts
- client/src/lib/*.ts
- client/index.html
- client/package.json

### Backend (server/):
- server/index.ts
- server/routes.ts
- server/storage.ts
- server/db.ts
- server/replitAuth.ts (if using Replit auth)
- server/localAuth.ts (for local auth)

### Configuration:
- package.json (root)
- tsconfig.json
- vite.config.ts
- tailwind.config.ts
- drizzle.config.ts

## Deployment Steps:

1. Copy all files from Replit to /var/www/cfbc-complete/
2. Install dependencies: npm install
3. Build the application: npm run build
4. Configure database connection
5. Start with PM2: pm2 start

## Manual Transfer Required:

Since you have the complete application in Replit, you need to:

1. Create deployment package:
   tar -czf cfbc-complete.tar.gz client/ server/ shared/ *.json *.ts *.js

2. Upload to your Ubuntu server:
   scp cfbc-complete.tar.gz user@your-server:/var/www/

3. Extract and deploy:
   tar -xzf cfbc-complete.tar.gz
   cd cfbc-complete
   npm install --production
   npm run build
   pm2 start dist/index.js --name cfbc-react-app

This will give you the actual React application with all portals and features.
PACKAGE_INFO

echo "Deployment package information created in README_DEPLOYMENT.md"
echo ""
echo "IMPORTANT: You need to manually transfer your complete Replit application"
echo "because I can only see the current files, not create the full React app from scratch."
echo ""
echo "Here's what you need to do:"
echo ""
echo "1. In your Replit environment, create a deployment package:"
echo "   tar -czf cfbc-complete-deployment.tar.gz client/ server/ shared/ *.json *.ts *.js components.json postcss.config.js"
echo ""
echo "2. Download this package to your local machine"
echo ""
echo "3. Upload it to your Ubuntu server:"
echo "   scp cfbc-complete-deployment.tar.gz root@your-server-ip:/var/www/"
echo ""
echo "4. On your Ubuntu server, extract and deploy:"
echo "   cd /var/www"
echo "   tar -xzf cfbc-complete-deployment.tar.gz"
echo "   mv cfbc-complete-deployment cfbc-react"
echo "   cd cfbc-react"
echo "   npm install --production"
echo "   npm run build"
echo "   pm2 stop cfbc-updated"
echo "   pm2 start dist/index.js --name cfbc-react-app"
echo ""
echo "This will give you access to:"
echo "- Customer Portal at /portal (after login as customer)"
echo "- Driver Portal at /portal (after login as driver)"  
echo "- Dispatcher Portal at /portal (after login as dispatcher)"
echo "- Admin Portal at /portal (after login as admin)"
echo "- Complete React UI with all components"
echo ""
echo "Would you like me to help you create the deployment package?"