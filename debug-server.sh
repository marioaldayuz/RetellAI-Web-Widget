#!/bin/bash

# Server Debug Script
# This helps diagnose "Failed to fetch" errors

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           RetellAI Widget - Server Diagnostics                ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Check if Node.js is installed
echo -e "${YELLOW}1. Checking Node.js...${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js installed: $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ Node.js not installed${NC}"
    echo "   Install with: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs"
    exit 1
fi
echo ""

# 2. Check if server directory exists
echo -e "${YELLOW}2. Checking server directory...${NC}"
if [ -d "server" ]; then
    echo -e "${GREEN}✅ Server directory exists${NC}"
else
    echo -e "${RED}❌ Server directory not found${NC}"
    exit 1
fi
echo ""

# 3. Check if dependencies are installed
echo -e "${YELLOW}3. Checking dependencies...${NC}"
if [ -d "server/node_modules" ]; then
    echo -e "${GREEN}✅ Dependencies installed${NC}"
else
    echo -e "${RED}❌ Dependencies not installed${NC}"
    echo "   Installing now..."
    cd server && npm install && cd ..
fi
echo ""

# 4. Check .env file
echo -e "${YELLOW}4. Checking .env configuration...${NC}"
if [ -f "server/.env" ]; then
    echo -e "${GREEN}✅ .env file exists${NC}"
    
    # Check for API key
    if grep -q "RETELL_API_KEY=" server/.env; then
        echo -e "${GREEN}✅ API key configured${NC}"
    else
        echo -e "${RED}❌ API key not set${NC}"
        echo "   Add to server/.env: RETELL_API_KEY=your_key_here"
    fi
    
    # Check for UNIVERSAL_ACCESS
    if grep -q "UNIVERSAL_ACCESS=true" server/.env; then
        echo -e "${GREEN}✅ Universal access enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  Universal access not enabled${NC}"
        echo "   Add to server/.env: UNIVERSAL_ACCESS=true"
    fi
else
    echo -e "${RED}❌ .env file not found${NC}"
    echo "   Creating .env file..."
    cat > server/.env << EOF
RETELL_API_KEY=your_retell_api_key_here
UNIVERSAL_ACCESS=true
NODE_ENV=production
PORT=3001
EOF
    echo -e "${GREEN}✅ Created server/.env - Please add your API key${NC}"
fi
echo ""

# 5. Check if server is running
echo -e "${YELLOW}5. Checking if server is running...${NC}"

# Check systemd service
if systemctl is-active --quiet retell-widget-backend; then
    echo -e "${GREEN}✅ Systemd service is running${NC}"
    SERVER_RUNNING=true
else
    echo -e "${YELLOW}⚠️  Systemd service not running${NC}"
    
    # Check if running on port 3001
    if lsof -Pi :3001 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Server is running on port 3001${NC}"
        SERVER_RUNNING=true
    else
        echo -e "${RED}❌ Server not running${NC}"
        SERVER_RUNNING=false
    fi
fi
echo ""

# 6. Test server health endpoint
echo -e "${YELLOW}6. Testing server health endpoint...${NC}"
if [ "$SERVER_RUNNING" = true ]; then
    if curl -s http://localhost:3001/health > /dev/null; then
        echo -e "${GREEN}✅ Health endpoint responding${NC}"
        HEALTH_RESPONSE=$(curl -s http://localhost:3001/health)
        echo "   Response: $HEALTH_RESPONSE"
    else
        echo -e "${RED}❌ Health endpoint not responding${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping - server not running${NC}"
fi
echo ""

# 7. Test CORS headers
echo -e "${YELLOW}7. Testing CORS configuration...${NC}"
if [ "$SERVER_RUNNING" = true ]; then
    CORS_TEST=$(curl -s -I -X OPTIONS http://localhost:3001/api/create-web-call \
        -H "Origin: https://example.com" \
        -H "Access-Control-Request-Method: POST" 2>/dev/null | grep -i "access-control-allow-origin" || echo "No CORS headers")
    
    if [[ "$CORS_TEST" == *"*"* ]] || [[ "$CORS_TEST" == *"example.com"* ]]; then
        echo -e "${GREEN}✅ CORS is properly configured${NC}"
        echo "   Headers: $CORS_TEST"
    else
        echo -e "${RED}❌ CORS not configured${NC}"
        echo "   No Access-Control-Allow-Origin header found"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping - server not running${NC}"
fi
echo ""

# 8. Check Nginx configuration
echo -e "${YELLOW}8. Checking Nginx configuration...${NC}"
if command -v nginx &> /dev/null; then
    echo -e "${GREEN}✅ Nginx installed${NC}"
    
    # Check if site is enabled
    if [ -L /etc/nginx/sites-enabled/* ] 2>/dev/null; then
        echo -e "${GREEN}✅ Nginx sites configured${NC}"
    else
        echo -e "${YELLOW}⚠️  No Nginx sites enabled${NC}"
    fi
    
    # Test Nginx config
    if sudo nginx -t 2>/dev/null; then
        echo -e "${GREEN}✅ Nginx configuration valid${NC}"
    else
        echo -e "${RED}❌ Nginx configuration has errors${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Nginx not installed${NC}"
fi
echo ""

# 9. Show how to start server
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                     Quick Fix Commands                         ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$SERVER_RUNNING" = false ]; then
    echo -e "${YELLOW}Start server manually:${NC}"
    echo "  cd server && npm start"
    echo ""
    echo -e "${YELLOW}Or using systemd:${NC}"
    echo "  sudo systemctl start retell-widget-backend"
    echo ""
fi

echo -e "${YELLOW}View server logs:${NC}"
echo "  sudo journalctl -u retell-widget-backend -f"
echo ""

echo -e "${YELLOW}Test the API directly:${NC}"
echo "  curl -X POST http://localhost:3001/api/create-web-call \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"agentId\": \"test\"}'"
echo ""

echo -e "${YELLOW}Check what's running on port 3001:${NC}"
echo "  sudo lsof -i :3001"
echo ""

# 10. Common issues
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    Common Issues & Fixes                       ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}1. 'Failed to fetch' error:${NC}"
echo "   • Server not running → Start with: cd server && npm start"
echo "   • Wrong proxy endpoint → Check your widget uses correct URL"
echo "   • CORS not enabled → Set UNIVERSAL_ACCESS=true in server/.env"
echo ""

echo -e "${YELLOW}2. 'Invalid API key' error:${NC}"
echo "   • Add your Retell API key to server/.env"
echo "   • Key should start with 'retell_sk_'"
echo ""

echo -e "${YELLOW}3. 'Port already in use' error:${NC}"
echo "   • Kill existing process: sudo lsof -ti:3001 | xargs kill -9"
echo "   • Then restart server"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    Diagnostic Complete!                        ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"