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

# Get absolute path to ensure it works correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKING_DIR="$SCRIPT_DIR"
SERVER_DIR="$WORKING_DIR/server"

# Validate required files and directories exist
if [[ ! -d "$SERVER_DIR" ]]; then
    echo -e "${RED}Error: Server directory not found at $SERVER_DIR${NC}"
    echo "Please run this script from the RetellAI-Web-Widget root directory"
    exit 1
fi

if [[ ! -f "$SERVER_DIR/server.js" ]]; then
    echo -e "${RED}Error: server.js not found at $SERVER_DIR/server.js${NC}"
    echo "Please ensure the server.js file exists in the server directory"
    exit 1
fi

# Get Node.js path and validate
NODE_PATH=$(which node)
if [[ -z "$NODE_PATH" ]]; then
    echo -e "${RED}Error: Node.js not found. Please install Node.js first.${NC}"
    exit 1
fi

# Check if package.json exists and dependencies are installed
if [[ ! -f "$SERVER_DIR/package.json" ]]; then
    echo -e "${RED}Error: package.json not found in server directory${NC}"
    exit 1
fi

if [[ ! -d "$SERVER_DIR/node_modules" ]]; then
    echo -e "${YELLOW}Warning: node_modules not found. Installing dependencies...${NC}"
    cd "$SERVER_DIR"
    npm install
    cd "$WORKING_DIR"
fi

ENV_FILE="$WORKING_DIR/.env"

echo -e "${GREEN}Retell AI Widget - Systemd Service Setup${NC}"
echo "=========================================="
echo ""
echo "Configuration:"
echo "- Service Name: $SERVICE_NAME"
echo "- User: $USER"
echo "- Working Directory: $SERVER_DIR"
echo "- Node.js Path: $NODE_PATH"
echo "- Environment File: $ENV_FILE"
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
WorkingDirectory=$SERVER_DIR
ExecStart=$NODE_PATH server.js
Restart=always
RestartSec=10

# Environment
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

# Test the service file configuration
echo -e "${GREEN}Testing service configuration...${NC}"
systemctl daemon-reload
if ! systemctl cat $SERVICE_NAME.service > /dev/null 2>&1; then
    echo -e "${RED}Error: Service file configuration is invalid${NC}"
    exit 1
fi

# Check status
sleep 3
if systemctl is-active --quiet $SERVICE_NAME.service; then
    echo -e "${GREEN}✅ Service is running successfully!${NC}"
    echo ""
    echo -e "${GREEN}Service status:${NC}"
    systemctl status $SERVICE_NAME.service --no-pager -l
else
    echo -e "${RED}⚠️  Service failed to start. Checking configuration and logs...${NC}"
    echo ""
    echo -e "${YELLOW}Service file contents:${NC}"
    systemctl cat $SERVICE_NAME.service
    echo ""
    echo -e "${YELLOW}Recent logs:${NC}"
    journalctl -u $SERVICE_NAME -n 20 --no-pager
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Systemd service setup complete!${NC}"
echo ""
echo "Configuration Summary:"
echo "- Working Directory: $SERVER_DIR"
echo "- Node.js Path: $NODE_PATH"
echo "- User: $USER"
echo ""
echo "Useful commands:"
echo "- Check status: sudo systemctl status $SERVICE_NAME"
echo "- View logs: sudo journalctl -u $SERVICE_NAME -f"
echo "- Restart service: sudo systemctl restart $SERVICE_NAME"
echo "- Stop service: sudo systemctl stop $SERVICE_NAME"
echo "- Disable service: sudo systemctl disable $SERVICE_NAME"
