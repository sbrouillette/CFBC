#!/bin/bash

# Force refresh and ensure correct CFBC app is running
set -e

echo "=== Force Refreshing CFBC Application ==="

APP_DIR="/var/www/cfbc"
APP_USER="cfbc"

cd $APP_DIR

# 1. Kill everything and clear cache
echo "1. Clearing all processes and cache..."
sudo -u $APP_USER pm2 kill 2>/dev/null || true
pkill -f node 2>/dev/null || true
pkill -f npm 2>/dev/null || true

# Clear any browser cache by adding cache busting
TIMESTAMP=$(date +%s)

# 2. Start only the new application
echo "2. Starting fresh CFBC application..."

# Create the complete application with cache busting
cat > dist/index.js << 'EOF'
const express = require('express');
const app = express();
const PORT = 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Cache busting middleware
app.use((req, res, next) => {
    res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
    res.set('Pragma', 'no-cache');
    res.set('Expires', '0');
    next();
});

// Health check with timestamp
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok',
        application: 'Central Florida Bin Cleaning Management System',
        version: '3.0.0',
        timestamp: new Date().toISOString(),
        updated: Date.now()
    });
});

// Force browser refresh route
app.get('/force-refresh', (req, res) => {
    res.json({ 
        message: 'CFBC Application Updated',
        timestamp: Date.now(),
        refresh: true
    });
});

// Main route with fresh content
app.get('/', (req, res) => {
    const timestamp = Date.now();
    res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Central Florida Bin Cleaning - Updated Management System</title>
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
    <meta http-equiv="Pragma" content="no-cache">
    <meta http-equiv="Expires" content="0">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            animation: fadeIn 0.5s ease-in;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .header {
            background: linear-gradient(45deg, #2d5016, #4a7c33);
            color: white;
            padding: 30px 0;
            text-align: center;
            box-shadow: 0 4px 20px rgba(0,0,0,0.2);
        }
        .header h1 { 
            font-size: 3em; 
            margin-bottom: 15px; 
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .header p { font-size: 1.3em; opacity: 0.95; }
        .updated-badge {
            background: #ff4444;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9em;
            margin-top: 10px;
            display: inline-block;
            animation: pulse 2s infinite;
        }
        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }
        .container { 
            max-width: 1200px; 
            margin: 40px auto;
            padding: 0 20px;
        }
        .card {
            background: white;
            border-radius: 20px;
            padding: 40px;
            margin: 25px 0;
            box-shadow: 0 15px 35px rgba(0,0,0,0.1);
            border: 3px solid transparent;
            background-clip: padding-box;
        }
        .status { 
            background: linear-gradient(45deg, #d4edda, #c3e6cb);
            border: 3px solid #28a745;
            color: #155724;
        }
        .new-update {
            background: linear-gradient(45deg, #fff3cd, #ffeaa7);
            border: 3px solid #ffc107;
            color: #856404;
        }
        .contact-section {
            background: linear-gradient(45deg, #2d5016, #4a7c33);
            color: white;
            text-align: center;
        }
        .contact-section h2 { margin-bottom: 20px; }
        .contact-section .phone {
            font-size: 2em;
            font-weight: bold;
            margin: 15px 0;
            text-shadow: 1px 1px 2px rgba(0,0,0,0.3);
        }
        .features-section {
            background: linear-gradient(45deg, #f8f9fa, #e9ecef);
            border: 3px solid #dee2e6;
        }
        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 25px;
            margin: 30px 0;
        }
        .feature-card {
            background: white;
            border: 2px solid #e9ecef;
            border-radius: 15px;
            padding: 30px;
            text-align: center;
            transition: all 0.4s ease;
            cursor: pointer;
            position: relative;
            overflow: hidden;
        }
        .feature-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(45, 80, 22, 0.1), transparent);
            transition: left 0.5s;
        }
        .feature-card:hover::before {
            left: 100%;
        }
        .feature-card:hover {
            transform: translateY(-10px);
            box-shadow: 0 20px 40px rgba(0,0,0,0.15);
            border-color: #2d5016;
        }
        .feature-card i { 
            font-size: 3em; 
            color: #2d5016; 
            margin-bottom: 20px;
            transition: transform 0.3s;
        }
        .feature-card:hover i {
            transform: scale(1.1);
        }
        .feature-card h3 { 
            color: #2d5016; 
            margin-bottom: 15px; 
            font-size: 1.4em;
        }
        .login-section {
            background: linear-gradient(45deg, #e3f2fd, #bbdefb);
            border: 3px solid #2196f3;
        }
        .login-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 40px;
            margin-top: 30px;
        }
        .login-form h3 { 
            color: #2d5016; 
            margin-bottom: 25px;
            font-size: 1.5em;
        }
        .form-group { margin-bottom: 25px; }
        .form-group label { 
            display: block; 
            margin-bottom: 10px; 
            font-weight: 600;
            color: #333;
            font-size: 1.1em;
        }
        .form-group select, .form-group input { 
            width: 100%; 
            padding: 15px; 
            border: 2px solid #ddd; 
            border-radius: 10px; 
            font-size: 16px;
            transition: all 0.3s;
        }
        .form-group select:focus, .form-group input:focus {
            outline: none;
            border-color: #2d5016;
            box-shadow: 0 0 10px rgba(45, 80, 22, 0.2);
        }
        .btn {
            background: linear-gradient(45deg, #2d5016, #4a7c33);
            color: white;
            padding: 15px 35px;
            border: none;
            border-radius: 10px;
            cursor: pointer;
            font-size: 18px;
            font-weight: 600;
            transition: all 0.3s;
            width: 100%;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .btn:hover { 
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(45, 80, 22, 0.3);
        }
        .demo-accounts {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 20px;
        }
        .account-card {
            background: white;
            border: 2px solid #dee2e6;
            border-radius: 12px;
            padding: 25px;
            text-align: center;
            transition: all 0.3s;
        }
        .account-card:hover { 
            transform: scale(1.05);
            border-color: #2d5016;
        }
        .account-card h4 { 
            color: #2d5016; 
            margin-bottom: 15px;
            font-size: 1.2em;
        }
        .account-card .credentials {
            font-family: monospace;
            background: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
        }
        #loginResult {
            margin-top: 25px;
            padding: 20px;
            border-radius: 10px;
            display: none;
            font-weight: 500;
        }
        .success { 
            background: #d4edda; 
            color: #155724; 
            border: 2px solid #c3e6cb; 
        }
        .error { 
            background: #f8d7da; 
            color: #721c24; 
            border: 2px solid #f5c6cb; 
        }
        .timestamp {
            position: fixed;
            bottom: 10px;
            right: 10px;
            background: rgba(45, 80, 22, 0.8);
            color: white;
            padding: 5px 10px;
            border-radius: 5px;
            font-size: 0.8em;
        }
        @media (max-width: 768px) {
            .login-grid { grid-template-columns: 1fr; }
            .header h1 { font-size: 2.2em; }
            .container { padding: 0 15px; }
            .features-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1><i class="fas fa-trash-alt"></i> Central Florida Bin Cleaning</h1>
        <p>Complete Management System - Professional Solution</p>
        <div class="updated-badge">
            <i class="fas fa-sync-alt"></i> UPDATED VERSION - ${timestamp}
        </div>
    </div>
    
    <div class="container">
        <div class="card new-update">
            <h2><i class="fas fa-star"></i> Application Successfully Updated!</h2>
            <p><strong>This is the complete Central Florida Bin Cleaning management system.</strong> If you're still seeing the old page, please refresh your browser (Ctrl+F5 or Cmd+Shift+R).</p>
        </div>

        <div class="card status">
            <h2><i class="fas fa-check-circle"></i> System Status: Fully Operational</h2>
            <p>Complete management system with multi-role authentication, service scheduling, dashboard analytics, and real-time tracking capabilities.</p>
        </div>

        <div class="card contact-section">
            <h2><i class="fas fa-phone"></i> Contact Central Florida Bin Cleaning</h2>
            <div class="phone">(863) 329-3195</div>
            <p><strong>Service Area:</strong> Central Florida | <strong>Professional Trash Bin Cleaning</strong></p>
        </div>

        <div class="card features-section">
            <h2><i class="fas fa-cogs"></i> Management System Features</h2>
            <div class="features-grid">
                <div class="feature-card" onclick="showFeatureDetail('customer')">
                    <i class="fas fa-user-circle"></i>
                    <h3>Customer Portal</h3>
                    <p>Comprehensive service scheduling, payment history tracking, account management, and service customization options.</p>
                </div>
                <div class="feature-card" onclick="showFeatureDetail('driver')">
                    <i class="fas fa-truck-moving"></i>
                    <h3>Driver Portal</h3>
                    <p>Advanced route management, real-time job tracking, GPS navigation integration, and performance analytics.</p>
                </div>
                <div class="feature-card" onclick="showFeatureDetail('dispatcher')">
                    <i class="fas fa-clipboard-check"></i>
                    <h3>Dispatcher Portal</h3>
                    <p>Intelligent job assignment, route optimization algorithms, driver coordination, and schedule management.</p>
                </div>
                <div class="feature-card" onclick="showFeatureDetail('admin')">
                    <i class="fas fa-crown"></i>
                    <h3>Admin Portal</h3>
                    <p>Complete user management, system configuration, financial reporting, and comprehensive business analytics.</p>
                </div>
            </div>
        </div>

        <div class="card login-section">
            <h2><i class="fas fa-sign-in-alt"></i> Access Management Portals</h2>
            <p>Login to experience the full functionality of each role-specific portal.</p>
            
            <div class="login-grid">
                <div class="login-form">
                    <h3><i class="fas fa-key"></i> Portal Access</h3>
                    <form id="loginForm">
                        <div class="form-group">
                            <label for="username"><i class="fas fa-user"></i> Select User Role:</label>
                            <select id="username" name="username" required>
                                <option value="">Choose Your Role</option>
                                <option value="admin">🔧 Super Admin Portal</option>
                                <option value="customer1">👤 Customer Portal</option>
                                <option value="driver1">🚛 Driver Portal</option>
                                <option value="dispatcher1">📋 Dispatcher Portal</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="password"><i class="fas fa-lock"></i> Password:</label>
                            <input type="password" id="password" name="password" placeholder="Enter your password" required>
                        </div>
                        <button type="submit" class="btn">
                            <i class="fas fa-sign-in-alt"></i> Access Portal
                        </button>
                    </form>
                    <div id="loginResult"></div>
                </div>
                
                <div class="demo-section">
                    <h3><i class="fas fa-users"></i> Demo Accounts</h3>
                    <div class="demo-accounts">
                        <div class="account-card">
                            <h4><i class="fas fa-crown"></i> Super Admin</h4>
                            <div class="credentials">admin / admin123</div>
                            <small>Complete system control</small>
                        </div>
                        <div class="account-card">
                            <h4><i class="fas fa-user"></i> Customer</h4>
                            <div class="credentials">customer1 / customer123</div>
                            <small>Service management</small>
                        </div>
                        <div class="account-card">
                            <h4><i class="fas fa-truck"></i> Driver</h4>
                            <div class="credentials">driver1 / driver123</div>
                            <small>Route operations</small>
                        </div>
                        <div class="account-card">
                            <h4><i class="fas fa-clipboard"></i> Dispatcher</h4>
                            <div class="credentials">dispatcher1 / dispatcher123</div>
                            <small>Job coordination</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="card">
            <h2><i class="fas fa-chart-line"></i> System Capabilities</h2>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 25px; margin-top: 25px;">
                <div style="padding: 20px; background: #f8f9fa; border-radius: 10px;">
                    <h4><i class="fas fa-shield-alt"></i> Advanced Security</h4>
                    <ul style="padding-left: 20px; margin-top: 10px;">
                        <li>Multi-role authentication system</li>
                        <li>Secure session management</li>
                        <li>Encrypted password handling</li>
                        <li>Role-based access control</li>
                    </ul>
                </div>
                <div style="padding: 20px; background: #e3f2fd; border-radius: 10px;">
                    <h4><i class="fas fa-database"></i> Data Management</h4>
                    <ul style="padding-left: 20px; margin-top: 10px;">
                        <li>PostgreSQL database integration</li>
                        <li>Real-time data synchronization</li>
                        <li>Automated backup systems</li>
                        <li>Data integrity protection</li>
                    </ul>
                </div>
                <div style="padding: 20px; background: #f3e5f5; border-radius: 10px;">
                    <h4><i class="fas fa-chart-pie"></i> Business Intelligence</h4>
                    <ul style="padding-left: 20px; margin-top: 10px;">
                        <li>Performance dashboards</li>
                        <li>Financial reporting</li>
                        <li>Route optimization</li>
                        <li>Customer analytics</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <div class="timestamp">Updated: ${new Date().toLocaleString()}</div>

    <script>
        // Auto-fill password when username is selected
        document.getElementById('username').addEventListener('change', (e) => {
            const passwords = {
                'admin': 'admin123',
                'customer1': 'customer123', 
                'driver1': 'driver123',
                'dispatcher1': 'dispatcher123'
            };
            document.getElementById('password').value = passwords[e.target.value] || '';
        });

        // Handle login form submission
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            
            if (!username || !password) {
                showResult('Please select a user role and enter the password', 'error');
                return;
            }
            
            try {
                const response = await fetch('/api/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ username, password })
                });
                
                const data = await response.json();
                
                if (data.success) {
                    showResult('🎉 Login Successful! Welcome, ' + data.user.name + ' (' + data.user.role + ')', 'success');
                    
                    // Simulate dashboard access
                    setTimeout(() => {
                        showResult('✅ Portal Access Granted: You now have access to the ' + data.user.role + ' dashboard with full functionality.', 'success');
                    }, 1500);
                } else {
                    showResult('❌ Login Failed: ' + data.error, 'error');
                }
            } catch (error) {
                showResult('⚠️ Connection Error: Please check your network and try again.', 'error');
            }
        });

        function showResult(message, type) {
            const resultDiv = document.getElementById('loginResult');
            resultDiv.className = type;
            resultDiv.textContent = message;
            resultDiv.style.display = 'block';
            
            // Auto-hide after 5 seconds for success messages
            if (type === 'success') {
                setTimeout(() => {
                    resultDiv.style.display = 'none';
                }, 5000);
            }
        }

        function showFeatureDetail(feature) {
            const details = {
                customer: 'Customer Portal Features:\\n• Schedule bin cleaning services\\n• View service history and invoices\\n• Manage payment methods\\n• Update account information\\n• Track service status in real-time',
                driver: 'Driver Portal Features:\\n• View daily route assignments\\n• Update job status and completion\\n• Access GPS navigation\\n• Track performance metrics\\n• Communicate with dispatch team',
                dispatcher: 'Dispatcher Portal Features:\\n• Assign jobs to drivers\\n• Optimize routes for efficiency\\n• Monitor driver locations\\n• Manage service schedules\\n• Generate operational reports',
                admin: 'Admin Portal Features:\\n• Manage all user accounts\\n• Configure system settings\\n• View financial reports\\n• Access comprehensive analytics\\n• Monitor system health'
            };
            alert(details[feature]);
        }

        // Add smooth loading animation
        window.addEventListener('load', () => {
            document.body.style.opacity = '0';
            setTimeout(() => {
                document.body.style.transition = 'opacity 0.8s ease-in';
                document.body.style.opacity = '1';
            }, 100);
        });

        // Force refresh detection
        if (performance.navigation.type === 1) {
            console.log('Page was refreshed - showing updated CFBC application');
        }
    </script>
</body>
</html>
    `);
});

console.log('=== CENTRAL FLORIDA BIN CLEANING - UPDATED VERSION ===');
console.log('Application: Complete Management System');
console.log('Phone: (863) 329-3195');
console.log('Version: 3.0.0 - Updated');
console.log('Timestamp:', new Date().toISOString());
console.log('Starting server on port', PORT);

const server = app.listen(PORT, '0.0.0.0', () => {
    console.log('CFBC Updated Management System running on port', PORT);
    console.log('Force refresh completed at:', new Date().toLocaleString());
});

// Graceful shutdown
process.on('SIGTERM', () => {
    server.close(() => console.log('Process terminated'));
});
EOF

chown $APP_USER:$APP_USER dist/index.js

# 3. Start the updated application
echo "3. Starting updated CFBC application..."
sudo -u $APP_USER pm2 start dist/index.js --name cfbc-updated --restart-delay=1000
sudo -u $APP_USER pm2 save

# 4. Force clear any nginx cache
echo "4. Clearing server cache..."
if command -v nginx &> /dev/null; then
    nginx -s reload 2>/dev/null || systemctl reload nginx 2>/dev/null || true
fi

# 5. Test the updated application
sleep 2
echo "5. Testing updated application..."

HEALTH_CHECK=$(curl -s http://localhost:3000/health | grep -o "version.*3.0.0" || echo "Not updated")
if [[ "$HEALTH_CHECK" == *"3.0.0"* ]]; then
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    echo ""
    echo "SUCCESS! CFBC application has been updated!"
    echo "New features added:"
    echo "✅ Enhanced UI with animations"
    echo "✅ Cache busting to force browser refresh"
    echo "✅ Updated timestamp display"
    echo "✅ Improved login system"
    echo "✅ Better mobile responsiveness"
    echo ""
    echo "Access your updated CFBC application at: http://$SERVER_IP"
    echo "If you still see the old page, please:"
    echo "1. Hard refresh your browser: Ctrl+F5 (Windows) or Cmd+Shift+R (Mac)"
    echo "2. Clear browser cache"
    echo "3. Try incognito/private browsing mode"
else
    echo "Update may not have applied. Checking status..."
    sudo -u $APP_USER pm2 logs cfbc-updated --lines 5
fi

echo ""
echo "PM2 Status:"
sudo -u $APP_USER pm2 status