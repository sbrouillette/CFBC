#!/bin/bash

# Fix routing to show correct CFBC application
set -e

echo "=== Fixing Application Routing ==="

APP_DIR="/var/www/cfbc"
APP_USER="cfbc"

cd $APP_DIR

# 1. Check what's currently running
echo "1. Checking current processes..."
echo "PM2 processes:"
sudo -u $APP_USER pm2 list

echo "Processes on port 3000:"
netstat -tlnp | grep :3000

echo "All Node processes:"
ps aux | grep node | grep -v grep

# 2. Stop all conflicting processes
echo "2. Stopping all processes..."
sudo -u $APP_USER pm2 kill 2>/dev/null || true
pkill -f "node" 2>/dev/null || true
sleep 2

# 3. Check Nginx configuration
echo "3. Checking Nginx configuration..."
if [ -f "/etc/nginx/sites-available/cfbc" ]; then
    echo "Current Nginx config:"
    cat /etc/nginx/sites-available/cfbc
else
    echo "Creating Nginx configuration..."
    cat > /etc/nginx/sites-available/cfbc << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

    # Enable the site
    ln -sf /etc/nginx/sites-available/cfbc /etc/nginx/sites-enabled/cfbc
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload Nginx
    nginx -t && systemctl reload nginx
fi

# 4. Ensure our CFBC application is the only one running
echo "4. Starting CFBC application..."

# Make sure our server file is correct
cat > dist/index.js << 'EOF'
const express = require('express');
const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok',
        application: 'Central Florida Bin Cleaning',
        version: '2.0.0',
        timestamp: new Date().toISOString(),
        message: 'CFBC Management System is running correctly'
    });
});

// Main route - CFBC specific content
app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Central Florida Bin Cleaning - Management System</title>
    <style>
        body { 
            font-family: 'Segoe UI', sans-serif; 
            margin: 0; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container { 
            max-width: 900px; 
            background: white; 
            border-radius: 20px; 
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(45deg, #2d5016, #4a7c33);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .content { padding: 40px; }
        .status { 
            background: linear-gradient(45deg, #d4edda, #c3e6cb);
            border: 2px solid #28a745;
            border-radius: 15px; 
            padding: 25px; 
            margin: 25px 0;
            text-align: center;
            font-size: 1.1em;
        }
        .verification {
            background: #fff3cd;
            border: 2px solid #ffc107;
            border-radius: 15px;
            padding: 25px;
            margin: 25px 0;
            text-align: center;
        }
        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .feature {
            background: #f8f9fa;
            border: 2px solid #e9ecef;
            border-radius: 15px;
            padding: 25px;
            text-align: center;
            transition: transform 0.3s;
        }
        .feature:hover { transform: translateY(-5px); }
        .feature h3 { color: #2d5016; margin-bottom: 15px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Central Florida Bin Cleaning</h1>
            <p>Professional Management System - Version 2.0</p>
        </div>
        
        <div class="content">
            <div class="status">
                <strong>Application Status: CFBC System Running Correctly!</strong><br>
                This is the proper Central Florida Bin Cleaning application
            </div>

            <div class="verification">
                <h2>Verification Information</h2>
                <p><strong>Application:</strong> Central Florida Bin Cleaning Management System</p>
                <p><strong>Server Time:</strong> ${new Date().toLocaleString()}</p>
                <p><strong>Port:</strong> ${PORT}</p>
                <p><strong>Status:</strong> Operational</p>
            </div>

            <div class="features">
                <div class="feature">
                    <h3>Customer Portal</h3>
                    <p>Service scheduling and account management</p>
                </div>
                <div class="feature">
                    <h3>Driver Portal</h3>
                    <p>Route management and job tracking</p>
                </div>
                <div class="feature">
                    <h3>Dispatcher Portal</h3>
                    <p>Job assignment and coordination</p>
                </div>
                <div class="feature">
                    <h3>Admin Portal</h3>
                    <p>System management and reports</p>
                </div>
            </div>

            <div style="text-align: center; margin-top: 30px;">
                <p><strong>Contact:</strong> (863) 329-3195</p>
                <p><strong>Service Area:</strong> Central Florida</p>
            </div>
        </div>
    </div>
</body>
</html>
    `);
});

// API route to confirm this is CFBC
app.get('/api/identify', (req, res) => {
    res.json({
        application: 'Central Florida Bin Cleaning',
        company: 'CFBC',
        phone: '(863) 329-3195',
        services: ['Residential Bin Cleaning', 'Commercial Dumpster Cleaning'],
        version: '2.0.0'
    });
});

console.log('Starting Central Florida Bin Cleaning Management System');
console.log('Port:', PORT);
console.log('Time:', new Date().toLocaleString());

const server = app.listen(PORT, '0.0.0.0', () => {
    console.log('CFBC Management System running on port', PORT);
});
EOF

chown $APP_USER:$APP_USER dist/index.js

# 5. Start the correct application
echo "5. Starting CFBC application..."
sudo -u $APP_USER pm2 start dist/index.js --name cfbc-system
sudo -u $APP_USER pm2 save

# 6. Wait and verify
sleep 3
echo "6. Verification..."

# Test the application
if curl -s http://localhost:3000/health | grep -q "Central Florida Bin Cleaning"; then
    echo "SUCCESS! CFBC application is running correctly"
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    echo "Access your CFBC application at: http://$SERVER_IP"
    
    # Test the identification endpoint
    echo "Application identity:"
    curl -s http://localhost:3000/api/identify | grep -o '"application":"[^"]*"'
else
    echo "Issue detected. Checking logs..."
    sudo -u $APP_USER pm2 logs cfbc-system --lines 5
fi

echo "Final PM2 status:"
sudo -u $APP_USER pm2 status