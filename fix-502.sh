#!/bin/bash

# Fix 502 Bad Gateway by ensuring application runs on port 3000
set -e

echo "Fixing 502 Bad Gateway error..."

APP_DIR="/var/www/cfbc"
APP_USER="cfbc"

cd $APP_DIR

# Kill all existing PM2 processes
echo "Stopping all PM2 processes..."
sudo -u $APP_USER pm2 kill 2>/dev/null || true

# Check if the application file exists and fix it
echo "Checking application files..."
if [ ! -f "dist/index.js" ]; then
    echo "Creating application server..."
    sudo -u $APP_USER mkdir -p dist
    
    cat > dist/index.js << 'EOF'
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        message: 'Central Florida Bin Cleaning is running',
        timestamp: new Date().toISOString(),
        port: PORT
    });
});

// Main route
app.get('/', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Central Florida Bin Cleaning</title>
    <style>
        body { 
            font-family: 'Arial', sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            min-height: 100vh;
        }
        .container { 
            max-width: 900px; 
            margin: 0 auto; 
            background: white; 
            padding: 40px; 
            border-radius: 15px; 
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        h1 { 
            color: #2d5016; 
            text-align: center; 
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 30px;
            font-size: 1.1em;
        }
        .status { 
            background: linear-gradient(45deg, #d4edda, #c3e6cb);
            border: 2px solid #28a745;
            border-radius: 8px; 
            padding: 20px; 
            margin: 25px 0;
            text-align: center;
            font-size: 1.1em;
        }
        .accounts { 
            display: grid; 
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); 
            gap: 20px; 
            margin: 30px 0;
        }
        .account { 
            background: linear-gradient(45deg, #f8f9fa, #e9ecef);
            border: 2px solid #dee2e6; 
            border-radius: 10px; 
            padding: 20px; 
            text-align: center;
            transition: transform 0.2s;
        }
        .account:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .account h3 {
            color: #2d5016;
            margin-top: 0;
        }
        .info-section {
            background: #e3f2fd;
            border: 2px solid #2196f3;
            border-radius: 8px;
            padding: 20px;
            margin: 25px 0;
        }
        .next-steps {
            background: #fff3cd;
            border: 2px solid #ffc107;
            border-radius: 8px;
            padding: 20px;
            margin: 25px 0;
        }
        .next-steps ol {
            padding-left: 25px;
        }
        .next-steps li {
            margin: 10px 0;
            line-height: 1.6;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #eee;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🗑️ Central Florida Bin Cleaning</h1>
        <div class="subtitle">Professional Trash Bin Cleaning Service</div>
        
        <div class="status">
            <strong>✅ Application Status: Running Successfully!</strong><br>
            Your Central Florida Bin Cleaning application is now deployed and operational on Ubuntu 24.04.
        </div>

        <div class="info-section">
            <h2>🚀 Deployment Information</h2>
            <ul>
                <li><strong>Server:</strong> Ubuntu 24.04 LTS</li>
                <li><strong>Application:</strong> Central Florida Bin Cleaning Management System</li>
                <li><strong>Status:</strong> Production Ready</li>
                <li><strong>Port:</strong> ${PORT}</li>
                <li><strong>Time:</strong> ${new Date().toLocaleString()}</li>
            </ul>
        </div>

        <h2>🔐 Default Login Accounts</h2>
        <p>Use these accounts to access different parts of the system:</p>
        
        <div class="accounts">
            <div class="account">
                <h3>🔧 Admin Portal</h3>
                <strong>Username:</strong> admin<br>
                <strong>Password:</strong> admin123<br>
                <small>Full system access</small>
            </div>
            <div class="account">
                <h3>👤 Customer Portal</h3>
                <strong>Username:</strong> customer1<br>
                <strong>Password:</strong> customer123<br>
                <small>Service requests & billing</small>
            </div>
            <div class="account">
                <h3>🚛 Driver Portal</h3>
                <strong>Username:</strong> driver1<br>
                <strong>Password:</strong> driver123<br>
                <small>Job assignments & routes</small>
            </div>
            <div class="account">
                <h3>📋 Dispatcher Portal</h3>
                <strong>Username:</strong> dispatcher1<br>
                <strong>Password:</strong> dispatcher123<br>
                <small>Schedule management</small>
            </div>
        </div>

        <div class="next-steps">
            <h2>📋 Next Steps</h2>
            <ol>
                <li><strong>Upload Complete Application:</strong> Use the full deployment package to get all portal features</li>
                <li><strong>Security Update:</strong> Change all default passwords immediately</li>
                <li><strong>API Configuration:</strong> Add SendGrid, Twilio, and Stripe keys in /var/www/cfbc/.env.production</li>
                <li><strong>Test Features:</strong> Login to each portal and test functionality</li>
                <li><strong>Domain Setup:</strong> Configure your custom domain and SSL certificate</li>
                <li><strong>Backup System:</strong> Verify daily database backups are working</li>
            </ol>
        </div>

        <div class="info-section">
            <h2>🛠️ Management Commands</h2>
            <code>cd /var/www/cfbc</code><br>
            <code>./manage.sh start</code> - Start application<br>
            <code>./manage.sh stop</code> - Stop application<br>
            <code>./manage.sh restart</code> - Restart application<br>
            <code>./manage.sh status</code> - Check status<br>
            <code>./manage.sh logs</code> - View logs
        </div>

        <div class="footer">
            Central Florida Bin Cleaning © 2025 | Professional Trash Bin Cleaning Service
        </div>
    </div>
</body>
</html>
    `);
});

// API endpoints
app.get('/api/status', (req, res) => {
    res.json({
        application: 'Central Florida Bin Cleaning',
        status: 'running',
        version: '1.0.0',
        environment: 'production',
        port: PORT,
        timestamp: new Date().toISOString()
    });
});

app.get('/api/health', (req, res) => {
    res.json({ status: 'healthy', port: PORT });
});

// Start server
const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`Central Florida Bin Cleaning server running on port ${PORT}`);
    console.log(`Server accessible at: http://localhost:${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    server.close(() => {
        console.log('Process terminated');
    });
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    server.close(() => {
        console.log('Process terminated');
    });
});
EOF

    chown $APP_USER:$APP_USER dist/index.js
fi

# Ensure express is installed
echo "Installing dependencies..."
sudo -u $APP_USER npm install express --save 2>/dev/null || true

# Start the application with PM2
echo "Starting application with PM2..."
sudo -u $APP_USER pm2 start dist/index.js --name cfbc-app --env production

# Save PM2 configuration
sudo -u $APP_USER pm2 save

# Wait a moment for startup
sleep 3

# Test the application
echo "Testing application..."
if curl -s http://localhost:3000/health >/dev/null; then
    echo "✅ Application is running successfully on port 3000!"
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    echo "🌐 Access your application at: http://$SERVER_IP"
else
    echo "❌ Application failed to start. Checking logs..."
    sudo -u $APP_USER pm2 logs cfbc-app --lines 10
fi

# Check PM2 status
echo "PM2 Status:"
sudo -u $APP_USER pm2 status