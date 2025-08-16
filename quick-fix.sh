#!/bin/bash

# Quick fix for current Nginx SSL issue - Domain Agnostic Version

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get domain from command line or prompt
if [ -z "$1" ]; then
    echo -e "${YELLOW}No domain provided as argument.${NC}"
    echo -n "Enter your domain name (e.g., example.com): "
    read DOMAIN
else
    DOMAIN="$1"
fi

# Validate domain
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: Domain name is required!${NC}"
    echo "Usage: $0 yourdomain.com"
    exit 1
fi

echo -e "${GREEN}Quick Fix for Nginx SSL Configuration${NC}"
echo -e "${BLUE}Domain: $DOMAIN${NC}"
echo "======================================"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Backup current config if it exists
if [ -f /etc/nginx/sites-available/retell-widget ]; then
    echo -e "${YELLOW}Backing up current configuration...${NC}"
    cp /etc/nginx/sites-available/retell-widget "/etc/nginx/sites-available/retell-widget.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create temporary HTTP-only config
echo -e "${GREEN}Creating temporary HTTP-only configuration...${NC}"

cat > /etc/nginx/sites-available/retell-widget-temp << EOF
# Temporary HTTP-only configuration for Let's Encrypt
# Domain: $DOMAIN
# Generated: $(date)

server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;

    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Temporary message while configuring
    location / {
        return 200 "Site is being configured for $DOMAIN. Please wait...";
        add_header Content-Type text/plain;
    }
}
EOF

# Create certbot directory
mkdir -p /var/www/certbot
chown www-data:www-data /var/www/certbot

# Switch to temporary config
echo -e "${GREEN}Switching to temporary configuration...${NC}"
ln -sf /etc/nginx/sites-available/retell-widget-temp /etc/nginx/sites-enabled/retell-widget

# Remove any other conflicting sites
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
    echo -e "${YELLOW}Removed default site${NC}"
fi

# Test and reload
echo -e "${GREEN}Testing configuration...${NC}"
if nginx -t; then
    systemctl reload nginx
    echo -e "${GREEN}✅ Nginx reloaded successfully!${NC}"
else
    echo -e "${RED}❌ Nginx configuration test failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Temporary configuration active for $DOMAIN!${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Get SSL certificate (replace email):"
echo -e "${YELLOW}sudo certbot certonly --webroot -w /var/www/certbot -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email your-email@example.com${NC}"
echo ""
echo "2. After certificate is obtained, enable SSL:"
echo -e "${YELLOW}sudo ./enable-ssl.sh $DOMAIN${NC}"
echo ""
echo "3. Deploy your application:"
echo -e "${YELLOW}npm run build && sudo cp -r dist/* /var/www/retell-widget/dist/${NC}"
