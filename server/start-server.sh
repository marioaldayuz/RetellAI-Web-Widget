#!/bin/bash

# Server startup script with error handling

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting RetellAI Backend Server...${NC}"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Creating default .env file..."
    cat > .env << EOF
RETELL_API_KEY=your_retell_api_key_here
UNIVERSAL_ACCESS=true
NODE_ENV=production
PORT=3001
ALLOWED_ORIGINS=*
EOF
    echo -e "${YELLOW}Please edit .env and add your Retell API key${NC}"
    exit 1
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    npm install
fi

# Kill any existing process on port 3001
lsof -ti:3001 | xargs kill -9 2>/dev/null || true

# Start the server
echo -e "${GREEN}Starting server on port 3001...${NC}"
node server.js