#!/bin/bash

# Systemd Service Setup for Retell AI Widget Backend
# This script creates a systemd service for the Node.js backend

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
SERVICE_NAME="retell-widget-backend"
USER=$(whoami)
WORKING_DIR=$(pwd)
NODE_PATH=$(which node)
ENV_FILE="$WORKING_DIR/.env"

echo -e "${GREEN}Retell AI Widget - Systemd Service Setup${NC}"
echo "=========================================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# Create systemd service file
echo -e "${GREEN}Creating systemd service file...${NC}"

cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Retell AI Widget Backend Server
Documentation=https://github.com/yourusername/retell-widget
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WORKING_DIR/server
ExecStart=$NODE_PATH server.js
Restart=always
RestartSec=10

# Environment
EnvironmentFile=$ENV_FILE
Environment="NODE_ENV=production"

# Logging
StandardOutput=append:/var/log/$SERVICE_NAME.log
StandardError=append:/var/log/$SERVICE_NAME-error.log

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}Service file created successfully!${NC}"

# Create log files
echo -e "${GREEN}Creating log files...${NC}"
touch /var/log/$SERVICE_NAME.log
touch /var/log/$SERVICE_NAME-error.log
chown $USER:$USER /var/log/$SERVICE_NAME*.log

# Reload systemd
echo -e "${GREEN}Reloading systemd daemon...${NC}"
systemctl daemon-reload

# Enable the service
echo -e "${GREEN}Enabling service to start on boot...${NC}"
systemctl enable $SERVICE_NAME.service

# Start the service
echo -e "${GREEN}Starting the service...${NC}"
systemctl start $SERVICE_NAME.service

# Check status
sleep 2
if systemctl is-active --quiet $SERVICE_NAME.service; then
    echo -e "${GREEN}✅ Service is running successfully!${NC}"
else
    echo -e "${RED}⚠️  Service failed to start. Check logs with: journalctl -u $SERVICE_NAME -n 50${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Systemd service setup complete!${NC}"
echo ""
echo "Useful commands:"
echo "- Check status: sudo systemctl status $SERVICE_NAME"
echo "- View logs: sudo journalctl -u $SERVICE_NAME -f"
echo "- Restart service: sudo systemctl restart $SERVICE_NAME"
echo "- Stop service: sudo systemctl stop $SERVICE_NAME"
echo "- Disable service: sudo systemctl disable $SERVICE_NAME"
