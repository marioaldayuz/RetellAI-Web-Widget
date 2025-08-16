#!/bin/bash

# Quick fix for retell-widget-backend systemd service
# This script fixes the working directory issue

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Retell AI Widget - Systemd Service Fix${NC}"
echo "======================================"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}" 
   exit 1
fi

# Stop the failing service
echo -e "${YELLOW}Stopping the failing service...${NC}"
systemctl stop retell-widget-backend || true

# Find the current working directory
CURRENT_DIR=$(pwd)
echo -e "${YELLOW}Current directory: $CURRENT_DIR${NC}"

# Check if we're in the right place
if [[ ! -d "$CURRENT_DIR/server" ]]; then
    echo -e "${RED}Error: server directory not found in $CURRENT_DIR${NC}"
    echo "Please run this script from the RetellAI-Web-Widget directory"
    exit 1
fi

if [[ ! -f "$CURRENT_DIR/server/server.js" ]]; then
    echo -e "${RED}Error: server.js not found in $CURRENT_DIR/server${NC}"
    echo "Please ensure the server.js file exists"
    exit 1
fi

# Get the correct Node.js path
NODE_PATH=$(which node)
if [[ -z "$NODE_PATH" ]]; then
    echo -e "${RED}Error: Node.js not found. Please install Node.js first.${NC}"
    exit 1
fi

echo -e "${YELLOW}Using Node.js at: $NODE_PATH${NC}"
echo -e "${YELLOW}Using working directory: $CURRENT_DIR/server${NC}"

# Create the corrected systemd service file
echo -e "${GREEN}Creating corrected systemd service file...${NC}"

cat > /etc/systemd/system/retell-widget-backend.service << EOF
[Unit]
Description=Retell AI Widget Backend Server
Documentation=https://github.com/yourusername/retell-widget
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$CURRENT_DIR/server
ExecStart=$NODE_PATH server.js
Restart=always
RestartSec=10

# Environment
Environment="NODE_ENV=production"

# Logging
StandardOutput=append:/var/log/retell-widget-backend.log
StandardError=append:/var/log/retell-widget-backend-error.log

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}Service file updated successfully!${NC}"

# Create log files if they don't exist
echo -e "${GREEN}Ensuring log files exist...${NC}"
touch /var/log/retell-widget-backend.log
touch /var/log/retell-widget-backend-error.log
chown root:root /var/log/retell-widget-backend*.log

# Reload systemd
echo -e "${GREEN}Reloading systemd daemon...${NC}"
systemctl daemon-reload

# Start the service
echo -e "${GREEN}Starting the service...${NC}"
systemctl start retell-widget-backend.service

# Check status
sleep 3
if systemctl is-active --quiet retell-widget-backend.service; then
    echo -e "${GREEN}✅ Service is now running successfully!${NC}"
    echo ""
    echo -e "${GREEN}Service status:${NC}"
    systemctl status retell-widget-backend.service --no-pager -l
else
    echo -e "${RED}⚠️  Service still failed to start. Checking logs...${NC}"
    echo ""
    journalctl -u retell-widget-backend -n 10 --no-pager
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Systemd service fix complete!${NC}"
echo ""
echo "Useful commands:"
echo "- Check status: sudo systemctl status retell-widget-backend"
echo "- View logs: sudo journalctl -u retell-widget-backend -f"
echo "- Restart service: sudo systemctl restart retell-widget-backend"