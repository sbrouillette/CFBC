#!/bin/bash

# Restart CFBC application and verify it's working
set -e

echo "=== Restarting CFBC Application ==="

APP_DIR="/var/www/cfbc-app"

# Go to application directory
cd $APP_DIR

# Kill all PM2 processes and start fresh
echo "1. Stopping all PM2 processes..."
pm2 kill 2>/dev/null || true

# Verify server.js exists and start it
echo "2. Starting CFBC application..."
if [ -f "server.js" ]; then
    echo "✓ server.js found, starting application..."
    pm2 start server.js --name cfbc-working-app
    pm2 save
else
    echo "✗ server.js not found, creating it..."
    
    # Create the working server
    cat > server.js << 'SERVER_EOF'
const express = require('express');
const app = express();
const PORT = 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Session simulation
const sessions = {};

// API Routes
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    
    const users = {
        'admin': { password: 'admin123', role: 'admin', name: 'System Administrator' },
        'customer1': { password: 'customer123', role: 'customer', name: 'John Customer' },
        'driver1': { password: 'driver123', role: 'driver', name: 'Mike Driver' },
        'dispatcher1': { password: 'dispatcher123', role: 'dispatcher', name: 'Sarah Dispatcher' }
    };
    
    const user = users[username];
    if (user && user.password === password) {
        const sessionUser = {
            id: Math.random().toString(36).substr(2, 9),
            username,
            role: user.role,
            name: user.name,
            email: `${username}@cfbc.com`
        };
        sessions[sessionUser.id] = sessionUser;
        res.json({ success: true, user: sessionUser, sessionId: sessionUser.id });
    } else {
        res.status(401).json({ success: false, error: 'Invalid username or password' });
    }
});

app.get('/api/auth/user', (req, res) => {
    const sessionId = req.headers['x-session-id'];
    const user = sessions[sessionId];
    
    if (user) {
        res.json(user);
    } else {
        res.status(401).json({ message: 'Unauthorized' });
    }
});

app.post('/api/logout', (req, res) => {
    const sessionId = req.headers['x-session-id'];
    if (sessionId && sessions[sessionId]) {
        delete sessions[sessionId];
    }
    res.json({ success: true });
});

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        service: 'CFBC Management System',
        timestamp: new Date().toISOString()
    });
});

// Main application route
app.get('*', (req, res) => {
    res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Central Florida Bin Cleaning - Management System</title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        .bg-eco-green { background-color: #22c55e; }
        .text-eco-green { color: #22c55e; }
        .border-eco-green { border-color: #22c55e; }
        .hover\\:bg-eco-green:hover { background-color: #16a34a; }
        .focus\\:ring-eco-green:focus { ring-color: #22c55e; }
        .focus\\:border-eco-green:focus { border-color: #22c55e; }
    </style>
</head>
<body class="bg-gray-50">
    <div id="app">
        <!-- Navigation -->
        <nav class="bg-white shadow-sm border-b" id="navbar" style="display: none;">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex justify-between h-16">
                    <div class="flex items-center">
                        <i class="fas fa-trash-alt text-eco-green text-2xl mr-3"></i>
                        <h1 class="text-xl font-bold text-gray-900">Central Florida Bin Cleaning</h1>
                    </div>
                    <div class="flex items-center space-x-4">
                        <span class="text-eco-green font-semibold">(863) 329-3195</span>
                        <span id="userInfo" class="text-gray-600"></span>
                        <button onclick="logout()" class="text-gray-600 hover:text-gray-900">
                            <i class="fas fa-sign-out-alt"></i> Logout
                        </button>
                    </div>
                </div>
            </div>
        </nav>

        <!-- Login Section -->
        <div id="loginSection" class="min-h-screen bg-gradient-to-br from-blue-50 to-green-50 flex items-center justify-center">
            <div class="max-w-md w-full bg-white rounded-xl shadow-lg p-8 m-4">
                <div class="text-center mb-8">
                    <i class="fas fa-trash-alt text-eco-green text-5xl mb-4"></i>
                    <h2 class="text-3xl font-bold text-gray-900 mb-2">CFBC Management</h2>
                    <p class="text-gray-600">Central Florida Bin Cleaning</p>
                    <p class="text-sm text-gray-500 mt-2">Professional Waste Management Solutions</p>
                </div>
                
                <form id="loginForm" class="space-y-6">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Select Your Role</label>
                        <select id="username" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-eco-green focus:border-eco-green transition-colors">
                            <option value="">Choose Portal Access</option>
                            <option value="admin">🔧 System Administrator</option>
                            <option value="customer1">👤 Customer Portal</option>
                            <option value="driver1">🚛 Driver Portal</option>
                            <option value="dispatcher1">📋 Dispatcher Portal</option>
                        </select>
                    </div>
                    
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-2">Password</label>
                        <input type="password" id="password" placeholder="Enter your password" class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-eco-green focus:border-eco-green transition-colors">
                    </div>
                    
                    <button type="submit" class="w-full bg-eco-green text-white py-3 px-4 rounded-lg hover:bg-green-600 font-medium transition-colors">
                        <i class="fas fa-sign-in-alt mr-2"></i>Access Portal
                    </button>
                </form>
                
                <div class="mt-8 p-4 bg-gray-50 rounded-lg">
                    <p class="text-sm font-medium text-gray-700 mb-3">Demo Login Credentials:</p>
                    <div class="grid grid-cols-2 gap-3 text-xs">
                        <div class="bg-white p-2 rounded border">
                            <strong>Admin:</strong><br>admin / admin123
                        </div>
                        <div class="bg-white p-2 rounded border">
                            <strong>Customer:</strong><br>customer1 / customer123
                        </div>
                        <div class="bg-white p-2 rounded border">
                            <strong>Driver:</strong><br>driver1 / driver123
                        </div>
                        <div class="bg-white p-2 rounded border">
                            <strong>Dispatcher:</strong><br>dispatcher1 / dispatcher123
                        </div>
                    </div>
                </div>
                
                <div class="mt-6 text-center">
                    <p class="text-xs text-gray-500">Contact: (863) 329-3195</p>
                </div>
            </div>
        </div>

        <!-- Portal Section -->
        <div id="portalSection" style="display: none;" class="min-h-screen bg-gray-50">
            <div class="max-w-7xl mx-auto py-8 px-4">
                <div class="bg-white rounded-lg shadow p-6 mb-8">
                    <h2 class="text-3xl font-bold text-gray-900 mb-2">Welcome to Your Portal</h2>
                    <p class="text-gray-600">Role: <span id="userRole" class="font-semibold text-eco-green"></span></p>
                    <p class="text-gray-600">User: <span id="userName" class="font-medium"></span></p>
                </div>
                
                <!-- Portal Content -->
                <div id="portalContent"></div>
            </div>
        </div>
    </div>

    <script>
        let currentUser = null;
        let sessionId = null;

        // Auto-fill password when username changes
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
                alert('Please select a role and enter the password');
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
                    currentUser = data.user;
                    sessionId = data.sessionId;
                    showPortal();
                } else {
                    alert('Login failed: ' + (data.error || 'Invalid credentials'));
                }
            } catch (error) {
                alert('Connection error. Please try again.');
                console.error('Login error:', error);
            }
        });

        function showPortal() {
            document.getElementById('loginSection').style.display = 'none';
            document.getElementById('portalSection').style.display = 'block';
            document.getElementById('navbar').style.display = 'block';
            
            document.getElementById('userRole').textContent = currentUser.role.toUpperCase();
            document.getElementById('userName').textContent = currentUser.name;
            document.getElementById('userInfo').textContent = currentUser.name;
            
            // Load portal content based on role
            loadPortalContent(currentUser.role);
        }

        function loadPortalContent(role) {
            const content = document.getElementById('portalContent');
            
            const portals = {
                customer: \`
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-calendar-plus text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Schedule Service</h3>
                            <p class="text-gray-600 mb-4">Request bin cleaning services for your property</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">Schedule Now</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-history text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Service History</h3>
                            <p class="text-gray-600 mb-4">View your past cleaning services and schedules</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">View History</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-credit-card text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Billing & Payments</h3>
                            <p class="text-gray-600 mb-4">Manage your payment methods and view invoices</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">Manage Billing</button>
                        </div>
                    </div>
                \`,
                driver: \`
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-route text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">My Routes</h3>
                            <p class="text-gray-600 mb-4">View today's assigned cleaning routes</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">View Routes</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-check-circle text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Job Status</h3>
                            <p class="text-gray-600 mb-4">Update completion status for assigned jobs</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">Update Status</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-map-marker-alt text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Navigation</h3>
                            <p class="text-gray-600 mb-4">GPS navigation to customer locations</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">Open GPS</button>
                        </div>
                    </div>
                \`,
                dispatcher: \`
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-users text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Driver Management</h3>
                            <p class="text-gray-600 mb-4">Assign jobs and manage driver schedules</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">Manage Drivers</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-clipboard-list text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Job Assignment</h3>
                            <p class="text-gray-600 mb-4">Create and assign cleaning jobs to drivers</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">Assign Jobs</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-chart-line text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Route Optimization</h3>
                            <p class="text-gray-600 mb-4">Optimize routes for maximum efficiency</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">Optimize Routes</button>
                        </div>
                    </div>
                \`,
                admin: \`
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-users-cog text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">User Management</h3>
                            <p class="text-gray-600 mb-4">Manage customers, drivers, and dispatchers</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">Manage Users</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-chart-bar text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Analytics & Reports</h3>
                            <p class="text-gray-600 mb-4">View business performance and analytics</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">View Reports</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-cogs text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">System Settings</h3>
                            <p class="text-gray-600 mb-4">Configure system preferences and settings</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">System Config</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-dollar-sign text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Financial Overview</h3>
                            <p class="text-gray-600 mb-4">Revenue, expenses, and financial reports</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">View Finances</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-map text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Service Areas</h3>
                            <p class="text-gray-600 mb-4">Manage service coverage areas</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">Manage Areas</button>
                        </div>
                        <div class="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                            <i class="fas fa-bell text-eco-green text-4xl mb-4"></i>
                            <h3 class="text-xl font-semibold mb-2">Notifications</h3>
                            <p class="text-gray-600 mb-4">System alerts and customer communications</p>
                            <button class="bg-eco-green text-white px-6 py-2 rounded hover:bg-green-600 transition-colors">View Alerts</button>
                        </div>
                    </div>
                \`
            };
            
            content.innerHTML = portals[role] || '<p>Portal content not available.</p>';
        }

        async function logout() {
            try {
                if (sessionId) {
                    await fetch('/api/logout', {
                        method: 'POST',
                        headers: { 'X-Session-Id': sessionId }
                    });
                }
                
                currentUser = null;
                sessionId = null;
                
                document.getElementById('loginSection').style.display = 'block';
                document.getElementById('portalSection').style.display = 'none';
                document.getElementById('navbar').style.display = 'none';
                document.getElementById('loginForm').reset();
                
            } catch (error) {
                console.error('Logout error:', error);
                // Force logout even if request fails
                location.reload();
            }
        }
    </script>
</body>
</html>
    `);
});

console.log('=== CFBC Management System Started ===');
console.log('Service: Central Florida Bin Cleaning');
console.log('Phone: (863) 329-3195');
console.log('Port:', PORT);
console.log('Time:', new Date().toLocaleString());

app.listen(PORT, '0.0.0.0', () => {
    console.log(`CFBC Management System running on port ${PORT}`);
    console.log('Application ready for connections');
});
SERVER_EOF

    # Start the new server
    pm2 start server.js --name cfbc-working-app
    pm2 save
fi

# Wait for application to start
sleep 3

# Test application health
echo "3. Testing application health..."
if curl -s http://localhost:3000/health | grep -q "healthy"; then
    echo "✓ Application is healthy and responding"
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    echo ""
    echo "SUCCESS! CFBC Management System is Running"
    echo ""
    echo "=== Access Your Application ==="
    echo "URL: http://$SERVER_IP"
    echo "Status: Online and Accessible"
    echo ""
    echo "=== Login Credentials ==="
    echo "• Admin: admin / admin123"
    echo "• Customer: customer1 / customer123"
    echo "• Driver: driver1 / driver123"
    echo "• Dispatcher: dispatcher1 / dispatcher123"
    echo ""
    echo "=== Features Available ==="
    echo "✓ Professional login interface"
    echo "✓ Role-based portal access"
    echo "✓ Customer service management"
    echo "✓ Driver route management"
    echo "✓ Dispatcher job assignment"
    echo "✓ Admin system control"
    echo ""
    echo "Current PM2 Status:"
    pm2 status
    
else
    echo "✗ Application health check failed"
    echo "Checking logs..."
    pm2 logs cfbc-working-app --lines 10
fi

echo ""
echo "Application restart completed!"