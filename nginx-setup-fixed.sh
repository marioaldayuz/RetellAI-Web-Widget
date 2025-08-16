#!/bin/bash

# Retell AI Widget - Nginx Proxy Setup Script (Domain Agnostic)
# This script configures Nginx as a reverse proxy for any domain

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get configuration from command line or use defaults
DOMAIN=${1:-""}
BACKEND_PORT=${2:-3001}
FRONTEND_PORT=${3:-5173}
EMAIL=${4:-""}

# Function to display usage
show_usage() {
    echo "Usage: $0 <domain> [backend_port] [frontend_port] [email]"
    echo ""
    echo "Arguments:"
    echo "  domain         - Your domain name (required)"
    echo "  backend_port   - Backend server port (default: 3001)"
    echo "  frontend_port  - Frontend dev server port (default: 5173)"
    echo "  email         - Email for SSL certificate (optional)"
    echo ""
    echo "Example:"
    echo "  $0 example.com"
    echo "  $0 example.com 3001 5173 admin@example.com"
}

# Validate domain
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: Domain name is required!${NC}"
    echo ""
    show_usage
    exit 1
fi

# Set paths based on domain
SSL_CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
SSL_KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

echo -e "${GREEN}Retell AI Widget - Nginx Proxy Setup${NC}"
echo "======================================"
echo -e "${BLUE}Domain: $DOMAIN${NC}"
echo -e "${BLUE}Backend Port: $BACKEND_PORT${NC}"
echo -e "${BLUE}Frontend Port: $FRONTEND_PORT${NC}"
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

# Create initial HTTP-only Nginx configuration for Let's Encrypt
echo -e "${GREEN}Creating initial HTTP-only Nginx configuration for $DOMAIN...${NC}"

cat > /etc/nginx/sites-available/retell-widget << EOF
# Retell AI Widget - Nginx Configuration (HTTP for Let's Encrypt)
# Domain: $DOMAIN
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

# HTTP Server - Initial configuration for Let's Encrypt
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    # Logging
    access_log /var/log/nginx/${DOMAIN}-access.log;
    error_log /var/log/nginx/${DOMAIN}-error.log;

    # Let's Encrypt challenge location
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

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
        
        # CORS headers
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

    # Static files and frontend
    location / {
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

    # Block access to hidden files (except .well-known)
    location ~ /\.(?!well-known) {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

echo -e "${GREEN}Initial HTTP configuration created successfully!${NC}"

# Create directory for Let's Encrypt challenges
mkdir -p /var/www/certbot
chown www-data:www-data /var/www/certbot

# Enable the site
echo -e "${GREEN}Enabling the site...${NC}"
ln -sf /etc/nginx/sites-available/retell-widget /etc/nginx/sites-enabled/

# Remove default site if it exists
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
    echo -e "${YELLOW}Removed default Nginx site${NC}"
fi

# Test Nginx configuration
echo -e "${GREEN}Testing Nginx configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✅ Configuration test passed!${NC}"
else
    echo -e "${RED}❌ Configuration test failed! Please check the configuration.${NC}"
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
echo -e "${GREEN}✅ Initial Nginx setup complete for $DOMAIN!${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo ""
echo "1. ${YELLOW}Obtain SSL certificate:${NC}"
if [ -n "$EMAIL" ]; then
    echo "   sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email $EMAIL"
else
    echo "   sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN -d www.$DOMAIN"
fi
echo ""
echo "2. ${YELLOW}Enable SSL after certificate is obtained:${NC}"
echo "   sudo ./enable-ssl.sh $DOMAIN $BACKEND_PORT"
echo ""
echo "3. ${YELLOW}Build and deploy your application:${NC}"
echo "   npm run build"
echo "   sudo cp -r dist/* /var/www/retell-widget/dist/"
echo ""
echo "4. ${YELLOW}Start your backend server:${NC}"
echo "   cd server && npm start"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
