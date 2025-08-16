#!/bin/bash

# RetellAI Widget - One-Touch Deployment Script
# Usage: ./one-touch-deploy.sh YOUR_RETELL_API_KEY YOUR_DOMAIN

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        RetellAI Widget - One-Touch Deployment 🚀           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get parameters
RETELL_API_KEY=${1:-""}
YOUR_DOMAIN=${2:-""}
YOUR_EMAIL=${3:-"admin@example.com"}

# Check if API key provided
if [ -z "$RETELL_API_KEY" ]; then
    echo -e "${RED}Error: API key required!${NC}"
    echo ""
    echo "Usage: ./one-touch-deploy.sh YOUR_RETELL_API_KEY YOUR_DOMAIN [YOUR_EMAIL]"
    echo ""
    echo "Example:"
    echo "  ./one-touch-deploy.sh retell_sk_1234567890 api.mycompany.com your@email.com"
    echo ""
    exit 1
fi

# Check if domain provided
if [ -z "$YOUR_DOMAIN" ]; then
    echo -e "${RED}Error: Domain required!${NC}"
    echo ""
    echo "Usage: ./one-touch-deploy.sh YOUR_RETELL_API_KEY YOUR_DOMAIN [YOUR_EMAIL]"
    echo ""
    echo "Example:"
    echo "  ./one-touch-deploy.sh retell_sk_1234567890 api.mycompany.com your@email.com"
    echo ""
    exit 1
fi

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 1: Installing dependencies...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Install Node.js if not present
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install npm packages
npm install
cd server && npm install && cd ..
echo -e "${GREEN}✅ Dependencies installed${NC}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 2: Configuring environment...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Create .env file with proper configuration
cat > server/.env << EOF
RETELL_API_KEY=$RETELL_API_KEY
UNIVERSAL_ACCESS=true
NODE_ENV=production
PORT=3001
ALLOWED_ORIGINS=*
EOF
echo -e "${GREEN}✅ Environment configured for universal access${NC}"

# Ensure server has proper permissions
chmod 644 server/.env
chown $USER:$USER server/.env

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 3: Building widget...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

npm run build
echo -e "${GREEN}✅ Widget built successfully${NC}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 4: Setting up Nginx...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Install Nginx if not present
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx certbot python3-certbot-nginx
fi

# Copy widget files to Nginx directory
sudo mkdir -p /var/www/$YOUR_DOMAIN
sudo cp dist/retell-widget.js /var/www/$YOUR_DOMAIN/
sudo cp dist/retell-widget.css /var/www/$YOUR_DOMAIN/
sudo chown -R www-data:www-data /var/www/$YOUR_DOMAIN

# Configure Nginx
sudo tee /etc/nginx/sites-available/$YOUR_DOMAIN > /dev/null << EOF
server {
    listen 80;
    server_name $YOUR_DOMAIN;

    # Widget files served from root
    location ~ \.(js|css)$ {
        root /var/www/$YOUR_DOMAIN;
        add_header Access-Control-Allow-Origin "*";
        add_header Cache-Control "public, max-age=3600";
    }

    # Proxy to backend
    location /api/ {
        proxy_pass http://localhost:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3001/health;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/$YOUR_DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
echo -e "${GREEN}✅ Nginx configured${NC}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 5: Setting up systemd service...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Get absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy clean server file
echo -e "${GREEN}Ensuring clean server without duplicate CORS headers...${NC}"
if [ -f "server/server-clean.js" ]; then
    cp server/server-clean.js server/server.js
elif [ -f "server/server-fixed.js" ]; then
    cp server/server-fixed.js server/server.js
fi

# Create systemd service
sudo tee /etc/systemd/system/retell-widget-backend.service > /dev/null << EOF
[Unit]
Description=Retell AI Widget Backend Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$SCRIPT_DIR/server
ExecStart=$(which node) server.js
Restart=always
RestartSec=10
StandardOutput=append:/var/log/retell-widget-backend.log
StandardError=append:/var/log/retell-widget-backend.log
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable retell-widget-backend
sudo systemctl restart retell-widget-backend
echo -e "${GREEN}✅ Backend service started${NC}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 6: Setting up SSL certificate...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${YELLOW}Obtaining SSL certificate from Let's Encrypt...${NC}"
sudo certbot --nginx -d $YOUR_DOMAIN --non-interactive --agree-tos --email $YOUR_EMAIL --redirect

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           🎉 DEPLOYMENT COMPLETE! 🎉                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Your widget is now live at:${NC}"
echo "  • https://$YOUR_DOMAIN/retell-widget.js"
echo "  • https://$YOUR_DOMAIN/retell-widget.css"
echo ""
echo -e "${BLUE}Your API endpoint:${NC}"
echo "  • https://$YOUR_DOMAIN/api/create-web-call"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}COPY THIS WIDGET CODE TO ANY WEBSITE:${NC}"
echo ""
cat << EOF
<!-- RetellAI Widget Integration Code -->
<link rel="stylesheet" href="https://$YOUR_DOMAIN/retell-widget.css">
<script src="https://$YOUR_DOMAIN/retell-widget.js"></script>
<script>
  const widget = new RetellWidget({
    agentId: 'your_agent_id_here',  // Replace with your Retell agent ID
    proxyEndpoint: 'https://$YOUR_DOMAIN/api/create-web-call',
    
    // Optional customization (all fields below are optional)
    position: 'bottom-right',           // Widget position
    primaryColor: '#9333ea',            // Primary color
    secondaryColor: '#a855f7',          // Secondary color  
    bubbleIcon: 'fa-headset',           // Font Awesome icon
    welcomeMessage: 'How can I help you today?',  // Welcome text
    buttonLabel: 'Start Conversation'   // Button text
  });
</script>
EOF
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Service Management:${NC}"
echo "  • Check status: sudo systemctl status retell-widget-backend"
echo "  • View logs: sudo journalctl -u retell-widget-backend -f"
echo "  • Restart: sudo systemctl restart retell-widget-backend"
echo ""
echo -e "${GREEN}Test your deployment:${NC}"
echo "  • curl https://$YOUR_DOMAIN/health"
echo ""