#!/bin/bash

# Retell AI Widget - Nginx Proxy Setup Script
# This script configures Nginx as a reverse proxy for the Retell AI Widget

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
DOMAIN=${1:-"example.com"}
BACKEND_PORT=${2:-3001}
FRONTEND_PORT=${3:-5173}
SSL_CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
SSL_KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

echo -e "${GREEN}Retell AI Widget - Nginx Proxy Setup${NC}"
echo "======================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}Nginx not found. Installing...${NC}"
    apt-get update
    apt-get install -y nginx
fi

# Check if Certbot is installed (for SSL)
if ! command -v certbot &> /dev/null; then
    echo -e "${YELLOW}Certbot not found. Installing for SSL certificates...${NC}"
    apt-get install -y certbot python3-certbot-nginx
fi

# Create Nginx configuration
echo -e "${GREEN}Creating Nginx configuration for $DOMAIN...${NC}"

cat > /etc/nginx/sites-available/retell-widget << EOF
# Retell AI Widget - Nginx Configuration
# Generated on $(date)

# Rate limiting zones
limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_zone \$binary_remote_addr zone=general_limit:10m rate=30r/s;

# Upstream servers
upstream backend_server {
    server 127.0.0.1:$BACKEND_PORT;
    keepalive 64;
}

upstream frontend_server {
    server 127.0.0.1:$FRONTEND_PORT;
}

# HTTP Server - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    # Redirect all HTTP traffic to HTTPS
    return 301 https://\$server_name\$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL Configuration (will be managed by Certbot)
    # ssl_certificate $SSL_CERT_PATH;
    # ssl_certificate_key $SSL_KEY_PATH;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https:;" always;
    
    # HSTS (6 months)
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains" always;

    # Logging
    access_log /var/log/nginx/retell-widget-access.log;
    error_log /var/log/nginx/retell-widget-error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml application/atom+xml image/svg+xml text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype;

    # API Routes (Backend)
    location /api/ {
        # Rate limiting for API endpoints
        limit_req zone=api_limit burst=20 nodelay;
        
        # Proxy settings
        proxy_pass http://backend_server/api/;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Connection settings
        proxy_set_header Connection "keep-alive";
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering off;
        
        # CORS headers (if needed)
        add_header Access-Control-Allow-Origin "\$http_origin" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        
        # Handle preflight requests
        if (\$request_method = 'OPTIONS') {
            return 204;
        }
    }

    # WebSocket support for Retell AI
    location /ws {
        proxy_pass http://backend_server/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket timeouts
        proxy_connect_timeout 7d;
        proxy_send_timeout 7d;
        proxy_read_timeout 7d;
    }

    # Static files and frontend (Production)
    location / {
        # For development, proxy to Vite dev server
        # proxy_pass http://frontend_server;
        # proxy_http_version 1.1;
        # proxy_set_header Upgrade \$http_upgrade;
        # proxy_set_header Connection "upgrade";
        # proxy_set_header Host \$host;
        
        # For production, serve static files
        root /var/www/retell-widget/dist;
        try_files \$uri \$uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 30d;
            add_header Cache-Control "public, immutable";
        }
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Block access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

echo -e "${GREEN}Nginx configuration created successfully!${NC}"

# Enable the site
echo -e "${GREEN}Enabling the site...${NC}"
ln -sf /etc/nginx/sites-available/retell-widget /etc/nginx/sites-enabled/

# Test Nginx configuration
echo -e "${GREEN}Testing Nginx configuration...${NC}"
nginx -t

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Configuration test passed!${NC}"
else
    echo -e "${RED}Configuration test failed! Please check the configuration.${NC}"
    exit 1
fi

# Create web root directory for production
echo -e "${GREEN}Creating web root directory...${NC}"
mkdir -p /var/www/retell-widget/dist
chown -R www-data:www-data /var/www/retell-widget

# Reload Nginx
echo -e "${GREEN}Reloading Nginx...${NC}"
systemctl reload nginx

echo ""
echo -e "${GREEN}✅ Nginx proxy setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Update the DOMAIN variable in this script or pass it as an argument"
echo "2. Run: sudo ./nginx-setup.sh yourdomain.com"
echo "3. Set up SSL certificate: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo "4. Build your frontend: npm run build"
echo "5. Copy dist files to: /var/www/retell-widget/dist/"
echo "6. Start your backend server with PM2 or systemd"
echo ""
echo "For development mode:"
echo "- Uncomment the proxy_pass lines in the '/' location block"
echo "- Comment out the 'root' and 'try_files' lines"
echo "- Reload Nginx: sudo systemctl reload nginx"
