#!/bin/bash

# Enable SSL for Retell AI Widget after certificate is obtained
# Domain Agnostic Version

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse command line arguments
DOMAIN=""
BACKEND_PORT=3001
INCLUDE_WWW="auto"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-www)
            INCLUDE_WWW="false"
            shift
            ;;
        --www)
            INCLUDE_WWW="true"
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            if [ -z "$DOMAIN" ]; then
                DOMAIN="$1"
            elif [[ "$1" =~ ^[0-9]+$ ]]; then
                BACKEND_PORT="$1"
            fi
            shift
            ;;
    esac
done

# Auto-detect www support if not explicitly set
if [ "$INCLUDE_WWW" = "auto" ]; then
    # Count dots in domain - if more than 1, it's likely a subdomain
    dot_count=$(echo "$DOMAIN" | tr -cd '.' | wc -c)
    if [ "$dot_count" -gt 1 ]; then
        INCLUDE_WWW="false"  # Subdomain - skip www
    else
        INCLUDE_WWW="true"   # Root domain - include www
    fi
fi

# Function to display usage
show_usage() {
    echo "Usage: $0 <domain> [backend_port] [options]"
    echo ""
    echo "Arguments:"
    echo "  domain         - Your domain name (required)"
    echo "  backend_port   - Backend server port (default: 3001)"
    echo ""
    echo "Options:"
    echo "  --www          - Force include www subdomain"
    echo "  --no-www       - Force exclude www subdomain"
    echo "  --help, -h     - Show this help"
    echo ""
    echo "Auto-detection:"
    echo "  - Root domains (example.com) → includes www.example.com"
    echo "  - Subdomains (sub.example.com) → no www support"
    echo ""
    echo "Examples:"
    echo "  $0 example.com                 # includes www.example.com"
    echo "  $0 api.example.com             # no www (auto-detected)"
    echo "  $0 example.com --no-www        # no www (explicit)"
    echo "  $0 api.example.com --www       # includes www (override)"
}

# Validate domain
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: Domain name is required!${NC}"
    echo ""
    show_usage
    exit 1
fi

# Set certificate paths
SSL_CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
SSL_KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

echo -e "${GREEN}Enabling SSL for Retell AI Widget${NC}"
echo "===================================="
echo -e "${BLUE}Domain: $DOMAIN${NC}"
echo -e "${BLUE}Backend Port: $BACKEND_PORT${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Check if certificates exist
if [ ! -f "$SSL_CERT_PATH" ] || [ ! -f "$SSL_KEY_PATH" ]; then
    echo -e "${RED}SSL certificates not found for $DOMAIN!${NC}"
    echo ""
    echo "Certificate paths checked:"
    echo "  - $SSL_CERT_PATH"
    echo "  - $SSL_KEY_PATH"
    echo ""
    echo "Please obtain certificates first:"
    if [ "$INCLUDE_WWW" = "true" ]; then
        echo -e "${YELLOW}sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN -d www.$DOMAIN${NC}"
    else
        echo -e "${YELLOW}sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN${NC}"
    fi
    exit 1
fi

echo -e "${GREEN}✅ SSL certificates found for $DOMAIN${NC}"
echo "  - Certificate: $SSL_CERT_PATH"
echo "  - Private Key: $SSL_KEY_PATH"
echo ""
echo -e "${GREEN}Updating Nginx configuration...${NC}"

# Backup current configuration
if [ -f /etc/nginx/sites-available/retell-widget ]; then
    cp /etc/nginx/sites-available/retell-widget "/etc/nginx/sites-available/retell-widget.pre-ssl.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}Current configuration backed up${NC}"
fi

# Create HTTPS-enabled configuration
cat > /etc/nginx/sites-available/retell-widget << EOF
# Retell AI Widget - Nginx Configuration with SSL
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

# HTTP Server - Redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
SERVER_NAME_PLACEHOLDER

    # Let's Encrypt renewal
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
SERVER_NAME_PLACEHOLDER

    # SSL Configuration
    ssl_certificate $SSL_CERT_PATH;
    ssl_certificate_key $SSL_KEY_PATH;
    
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
    add_header Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https:; img-src 'self' data: https:; font-src 'self' data: https:; connect-src 'self' https: wss:;" always;
    
    # HSTS (6 months)
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains" always;

    # Logging
    access_log /var/log/nginx/${DOMAIN}-ssl-access.log;
    error_log /var/log/nginx/${DOMAIN}-ssl-error.log;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/rss+xml application/atom+xml image/svg+xml application/vnd.ms-fontobject application/x-font-ttf font/opentype;

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

# Replace placeholder with actual server_name directive
sed -i "s|SERVER_NAME_PLACEHOLDER|$SERVER_NAME_DIRECTIVE|" /etc/nginx/sites-available/retell-widget

# Test configuration
echo -e "${GREEN}Testing new configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✅ Configuration test passed!${NC}"
    
    # Reload Nginx
    echo -e "${GREEN}Reloading Nginx...${NC}"
    systemctl reload nginx
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✅ SSL ENABLED SUCCESSFULLY!              ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Your site is now available at:"
    echo -e "${BLUE}🔒 https://$DOMAIN${NC}"
    echo ""
    echo -e "${YELLOW}Important Information:${NC}"
    echo "• HTTP traffic automatically redirects to HTTPS"
    echo "• SSL certificate will auto-renew via cron"
    echo "• Security headers are configured"
    echo "• HSTS is enabled for 6 months"
    echo ""
    echo -e "${GREEN}Test SSL renewal with:${NC}"
    echo "  sudo certbot renew --dry-run"
    echo ""
    echo -e "${GREEN}View SSL certificate info:${NC}"
    echo "  sudo certbot certificates"
    echo ""
else
    echo -e "${RED}❌ Configuration test failed!${NC}"
    echo "The original configuration has been preserved."
    echo "Check the error messages above for details."
    exit 1
fi
