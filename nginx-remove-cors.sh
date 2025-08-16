#!/bin/bash

# Remove ALL CORS headers from nginx configuration
# The Express server should be the ONLY source of CORS headers

echo "================================================"
echo "REMOVING ALL CORS HEADERS FROM NGINX"
echo "================================================"
echo ""

# Backup current nginx config
echo "Backing up current nginx configuration..."
sudo cp /etc/nginx/sites-available/retelldemo.olliebot.ai \
        /etc/nginx/sites-available/retelldemo.olliebot.ai.backup-$(date +%Y%m%d-%H%M%S)

# Create clean nginx config with NO CORS headers
echo "Creating clean nginx configuration..."
sudo tee /etc/nginx/sites-available/retelldemo.olliebot.ai > /dev/null << 'EOF'
server {
    listen 80;
    server_name retelldemo.olliebot.ai;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name retelldemo.olliebot.ai;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/retelldemo.olliebot.ai/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/retelldemo.olliebot.ai/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Logging
    access_log /var/log/nginx/retelldemo.access.log;
    error_log /var/log/nginx/retelldemo.error.log;

    # Client body size
    client_max_body_size 10M;

    # Proxy settings
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;

    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;

    # IMPORTANT: NO Access-Control headers here!
    # Express handles ALL CORS headers

    location / {
        proxy_pass http://localhost:3001;
        
        # CRITICAL: Tell nginx to NOT add its own headers
        proxy_hide_header Access-Control-Allow-Origin;
        proxy_hide_header Access-Control-Allow-Methods;
        proxy_hide_header Access-Control-Allow-Headers;
        
        # Pass through the headers from Express unchanged
        proxy_pass_header Access-Control-Allow-Origin;
        proxy_pass_header Access-Control-Allow-Methods;
        proxy_pass_header Access-Control-Allow-Headers;
    }

    location /health {
        proxy_pass http://localhost:3001/health;
        proxy_hide_header Access-Control-Allow-Origin;
        proxy_pass_header Access-Control-Allow-Origin;
    }

    location /api/ {
        proxy_pass http://localhost:3001/api/;
        
        # NO add_header directives for CORS!
        # Express is the ONLY source of CORS headers
        
        proxy_hide_header Access-Control-Allow-Origin;
        proxy_hide_header Access-Control-Allow-Methods;
        proxy_hide_header Access-Control-Allow-Headers;
        
        proxy_pass_header Access-Control-Allow-Origin;
        proxy_pass_header Access-Control-Allow-Methods;
        proxy_pass_header Access-Control-Allow-Headers;
    }
}
EOF

echo "✅ Clean nginx config created"
echo ""

# Test nginx configuration
echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid"
    
    # Reload nginx
    echo "Reloading nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx reloaded"
else
    echo "❌ Nginx configuration error! Restoring backup..."
    sudo cp /etc/nginx/sites-available/retelldemo.olliebot.ai.backup-$(date +%Y%m%d) \
            /etc/nginx/sites-available/retelldemo.olliebot.ai
    exit 1
fi

echo ""
echo "================================================"
echo "Checking for duplicate headers..."
echo "================================================"

# Check current nginx config for any CORS headers
echo "Searching nginx config for Access-Control headers:"
sudo grep -i "access-control\|add_header.*origin" /etc/nginx/sites-available/retelldemo.olliebot.ai || echo "✅ No CORS headers found in nginx (good!)"

echo ""
echo "================================================"
echo "NGINX CORS HEADERS REMOVED"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Update Express server to use server-single-cors.js"
echo "2. Restart the Node.js service"
echo "3. Test with: curl -I https://retelldemo.olliebot.ai/health"
echo ""
echo "The response should have ONLY ONE Access-Control-Allow-Origin header"
echo "with the value: *"
echo "================================================"
