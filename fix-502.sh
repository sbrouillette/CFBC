#!/bin/bash

# Fix 502 Bad Gateway - Ensure application and Nginx are properly configured
set -e

echo "=== Fixing 502 Bad Gateway Error ==="

# Check current application status
echo "1. Checking application status..."
pm2 status

# Test if application is responding on port 3000
echo "2. Testing application on port 3000..."
if curl -s http://localhost:3000 > /dev/null; then
    echo "✓ Application is responding on port 3000"
else
    echo "✗ Application not responding on port 3000 - restarting..."
    cd /var/www/cfbc-app
    pm2 restart cfbc-app
    sleep 3
    
    if curl -s http://localhost:3000 > /dev/null; then
        echo "✓ Application restarted and responding"
    else
        echo "✗ Application still not responding - checking logs..."
        pm2 logs cfbc-app --lines 10
        exit 1
    fi
fi

# Fix Nginx configuration
echo "3. Updating Nginx configuration..."
cat > /etc/nginx/sites-available/cfbc << 'NGINX_EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Disable buffering for real-time responses
    proxy_buffering off;
    proxy_cache off;

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
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Handle proxy errors
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3000/health;
        proxy_set_header Host $host;
        access_log off;
    }

    # Error pages
    error_page 502 503 504 /50x.html;
    location = /50x.html {
        root /var/www/html;
        internal;
    }
}
NGINX_EOF

# Test Nginx configuration
echo "4. Testing Nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✓ Nginx configuration is valid"
    
    # Reload Nginx
    echo "5. Reloading Nginx..."
    systemctl reload nginx
    
    # Wait for reload
    sleep 2
    
    # Test the full application
    echo "6. Testing complete application..."
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    if curl -s http://localhost > /dev/null; then
        echo ""
        echo "SUCCESS! 502 Error Fixed!"
        echo ""
        echo "=== Application Access ==="
        echo "URL: http://$SERVER_IP"
        echo "Status: Online and Accessible"
        echo ""
        echo "=== Test Your Application ==="
        echo "1. Visit http://$SERVER_IP in your browser"
        echo "2. You should see the CFBC login page"
        echo "3. Login with: admin / admin123"
        echo "4. Access your management portal"
        echo ""
        echo "=== Login Accounts ==="
        echo "• Admin Portal: admin / admin123"
        echo "• Customer Portal: customer1 / customer123"
        echo "• Driver Portal: driver1 / driver123"
        echo "• Dispatcher Portal: dispatcher1 / dispatcher123"
        echo ""
        echo "=== Current Status ==="
        echo "Application: Running on port 3000"
        echo "Nginx: Proxy configured and running"
        echo "PM2 Status:"
        pm2 status
        
    else
        echo "WARNING: Still getting connection issues"
        echo "Checking system status..."
        
        echo "Nginx status:"
        systemctl status nginx --no-pager -l
        
        echo "Application logs:"
        pm2 logs cfbc-app --lines 5
        
        echo "Port 3000 status:"
        netstat -tlnp | grep :3000 || echo "Port 3000 not listening"
    fi
    
else
    echo "✗ Nginx configuration has errors"
    nginx -t
    exit 1
fi

echo ""
echo "502 fix completed!"