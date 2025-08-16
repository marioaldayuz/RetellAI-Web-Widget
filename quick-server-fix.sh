#!/bin/bash

# Quick fix script for "Failed to fetch" errors
# Run this on your Linux server to fix common issues

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          RetellAI Widget - Quick Server Fix                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Fix .env file
echo -e "${YELLOW}1. Fixing environment configuration...${NC}"

if [ ! -f "server/.env" ]; then
    echo -e "${RED}   Creating .env file...${NC}"
    cat > server/.env << 'EOF'
# IMPORTANT: Replace with your actual API key!
RETELL_API_KEY=retell_sk_your_actual_key_here
UNIVERSAL_ACCESS=true
ALLOWED_ORIGINS=*
NODE_ENV=production
PORT=3001
EOF
    echo -e "${YELLOW}   ⚠️  IMPORTANT: Edit server/.env and add your actual API key!${NC}"
else
    # Ensure UNIVERSAL_ACCESS is set
    if ! grep -q "UNIVERSAL_ACCESS=true" server/.env; then
        echo "UNIVERSAL_ACCESS=true" >> server/.env
        echo -e "${GREEN}   Added UNIVERSAL_ACCESS=true${NC}"
    fi
    
    # Ensure ALLOWED_ORIGINS is set
    if ! grep -q "ALLOWED_ORIGINS=" server/.env; then
        echo "ALLOWED_ORIGINS=*" >> server/.env
        echo -e "${GREEN}   Added ALLOWED_ORIGINS=*${NC}"
    fi
fi

# 2. Install dependencies
echo -e "${YELLOW}2. Installing dependencies...${NC}"
cd server && npm install && cd ..
echo -e "${GREEN}   ✅ Dependencies installed${NC}"

# 3. Build widget
echo -e "${YELLOW}3. Building widget...${NC}"
npm run build
echo -e "${GREEN}   ✅ Widget built${NC}"

# 4. Stop existing service
echo -e "${YELLOW}4. Stopping existing services...${NC}"
sudo systemctl stop retell-widget-backend 2>/dev/null || true
sudo lsof -ti:3001 | xargs sudo kill -9 2>/dev/null || true
echo -e "${GREEN}   ✅ Stopped existing services${NC}"

# 5. Fix systemd service
echo -e "${YELLOW}5. Fixing systemd service...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# 6. Reload and start service
echo -e "${YELLOW}6. Starting service...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable retell-widget-backend
sudo systemctl start retell-widget-backend

# Wait for service to start
sleep 3

# 7. Test the service
echo -e "${YELLOW}7. Testing service...${NC}"

if curl -s http://localhost:3001/health > /dev/null; then
    HEALTH=$(curl -s http://localhost:3001/health)
    echo -e "${GREEN}   ✅ Server is running!${NC}"
    echo "   Response: $HEALTH"
else
    echo -e "${RED}   ❌ Server not responding${NC}"
    echo "   Check logs: sudo journalctl -u retell-widget-backend -n 50"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Fix Complete!                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Widget Code (copy this to ANY website):${NC}"
echo ""
echo "<!-- RetellAI Widget -->"
echo "<link rel=\"stylesheet\" href=\"https://YOUR_DOMAIN/widget/retell-widget.css\">"
echo "<script src=\"https://YOUR_DOMAIN/widget/retell-widget.js\"></script>"
echo "<script>"
echo "  new RetellWidget({"
echo "    agentId: 'your_agent_id_here',"
echo "    proxyEndpoint: 'https://YOUR_DOMAIN/api/create-web-call'"
echo "  });"
echo "</script>"
echo ""
echo -e "${YELLOW}⚠️  Don't forget to:${NC}"
echo "1. Add your actual Retell API key to server/.env"
echo "2. Replace YOUR_DOMAIN with your actual domain"
echo "3. Replace your_agent_id_here with your actual agent ID"
echo ""
echo -e "${GREEN}Check logs:${NC} sudo journalctl -u retell-widget-backend -f"