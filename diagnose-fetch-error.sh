#!/bin/bash

# Diagnostic script for "Failed to fetch" errors
# Run this on your Linux server to find the exact issue

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Diagnosing 'Failed to fetch' Error                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

DOMAIN=${1:-"localhost"}

# 1. Check if backend server is running
echo -e "${YELLOW}1. Checking if backend server is running...${NC}"

# Check port 3001
if sudo lsof -i :3001 | grep LISTEN > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Server is listening on port 3001${NC}"
    PID=$(sudo lsof -t -i:3001 | head -1)
    echo "   Process ID: $PID"
else
    echo -e "${RED}❌ Server NOT running on port 3001${NC}"
    echo ""
    echo -e "${YELLOW}Starting server now...${NC}"
    
    # Check if systemd service exists
    if systemctl list-unit-files | grep retell-widget-backend > /dev/null 2>&1; then
        sudo systemctl start retell-widget-backend
        sleep 3
        if systemctl is-active retell-widget-backend > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Server started via systemd${NC}"
        else
            echo -e "${RED}❌ Failed to start via systemd${NC}"
            echo "   Check logs: sudo journalctl -u retell-widget-backend -n 50"
        fi
    else
        # Start manually
        echo "Starting server manually..."
        cd server 2>/dev/null || { echo "❌ server directory not found"; exit 1; }
        nohup node server.js > server.log 2>&1 &
        sleep 3
        echo -e "${GREEN}✅ Server started manually${NC}"
        cd ..
    fi
fi
echo ""

# 2. Test health endpoint locally
echo -e "${YELLOW}2. Testing health endpoint locally...${NC}"
HEALTH=$(curl -s http://localhost:3001/health 2>/dev/null || echo "failed")
if [[ "$HEALTH" == *"healthy"* ]] || [[ "$HEALTH" == *"ok"* ]]; then
    echo -e "${GREEN}✅ Health endpoint responding${NC}"
    echo "   Response: $HEALTH"
else
    echo -e "${RED}❌ Health endpoint not responding${NC}"
    echo "   Response: $HEALTH"
fi
echo ""

# 3. Test API endpoint locally
echo -e "${YELLOW}3. Testing API endpoint locally...${NC}"
API_RESPONSE=$(curl -s -X POST http://localhost:3001/api/create-web-call \
    -H "Content-Type: application/json" \
    -d '{"agentId":"test"}' 2>/dev/null || echo "failed")
echo "   Response: $API_RESPONSE"

if [[ "$API_RESPONSE" == *"error"* ]]; then
    if [[ "$API_RESPONSE" == *"API key"* ]] || [[ "$API_RESPONSE" == *"Missing API key"* ]]; then
        echo -e "${YELLOW}⚠️  API key issue detected${NC}"
    elif [[ "$API_RESPONSE" == *"agent"* ]]; then
        echo -e "${GREEN}✅ API endpoint working (agent validation)${NC}"
    else
        echo -e "${YELLOW}⚠️  API returned error but is reachable${NC}"
    fi
elif [[ "$API_RESPONSE" == "failed" ]]; then
    echo -e "${RED}❌ API endpoint not responding${NC}"
else
    echo -e "${GREEN}✅ API endpoint working${NC}"
fi
echo ""

# 4. Check CORS headers
echo -e "${YELLOW}4. Testing CORS configuration...${NC}"
CORS_RESPONSE=$(curl -s -I -X OPTIONS http://localhost:3001/api/create-web-call \
    -H "Origin: https://example.com" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" 2>/dev/null)

if echo "$CORS_RESPONSE" | grep -i "access-control-allow-origin" > /dev/null; then
    CORS_ORIGIN=$(echo "$CORS_RESPONSE" | grep -i "access-control-allow-origin" | head -1)
    echo -e "${GREEN}✅ CORS headers present${NC}"
    echo "   $CORS_ORIGIN"
else
    echo -e "${RED}❌ No CORS headers found${NC}"
fi
echo ""

# 5. Check .env configuration
echo -e "${YELLOW}5. Checking .env configuration...${NC}"
if [ -f "server/.env" ]; then
    echo -e "${GREEN}✅ .env file exists${NC}"
    
    # Check for required variables
    if grep -q "RETELL_API_KEY=" server/.env; then
        if grep -q "RETELL_API_KEY=retell_sk_" server/.env; then
            echo -e "${GREEN}✅ API key configured (format looks correct)${NC}"
        else
            echo -e "${YELLOW}⚠️  API key present but may be invalid${NC}"
        fi
    else
        echo -e "${RED}❌ API key not configured${NC}"
    fi
    
    if grep -q "UNIVERSAL_ACCESS=true" server/.env; then
        echo -e "${GREEN}✅ Universal access enabled${NC}"
    elif grep -q "ALLOWED_ORIGINS=\*" server/.env; then
        echo -e "${GREEN}✅ Wildcard origins enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  CORS may be restrictive${NC}"
    fi
else
    echo -e "${RED}❌ .env file missing${NC}"
    echo "   Creating default .env..."
    cat > server/.env << 'EOF'
RETELL_API_KEY=your_retell_api_key_here
UNIVERSAL_ACCESS=true
ALLOWED_ORIGINS=*
NODE_ENV=production
PORT=3001
EOF
    echo -e "${GREEN}✅ Created server/.env - ADD YOUR API KEY!${NC}"
fi
echo ""

# 6. Check firewall
echo -e "${YELLOW}6. Checking firewall rules...${NC}"
if command -v ufw > /dev/null 2>&1; then
    if sudo ufw status | grep -q "3001" || sudo ufw status | grep -q "inactive"; then
        echo -e "${GREEN}✅ Port 3001 accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  Port 3001 may be blocked by firewall${NC}"
        echo "   To open: sudo ufw allow 3001"
    fi
else
    echo "   Firewall not detected (iptables may be in use)"
fi
echo ""

# 7. Check Nginx proxy configuration
echo -e "${YELLOW}7. Checking Nginx configuration...${NC}"
if [ -f "/etc/nginx/sites-enabled/$DOMAIN" ] || [ -f "/etc/nginx/sites-enabled/default" ]; then
    if grep -r "proxy_pass.*3001" /etc/nginx/sites-enabled/ > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Nginx proxy to port 3001 configured${NC}"
    else
        echo -e "${RED}❌ Nginx not configured to proxy to backend${NC}"
        echo "   Need to add proxy_pass http://localhost:3001/api/;"
    fi
else
    echo -e "${YELLOW}⚠️  Nginx site configuration not found${NC}"
fi
echo ""

# 8. Test from external (if domain provided)
if [ "$DOMAIN" != "localhost" ]; then
    echo -e "${YELLOW}8. Testing from external domain...${NC}"
    
    # Test health via domain
    EXTERNAL_HEALTH=$(curl -s https://$DOMAIN/health 2>/dev/null || curl -s http://$DOMAIN/health 2>/dev/null || echo "failed")
    if [[ "$EXTERNAL_HEALTH" == *"healthy"* ]] || [[ "$EXTERNAL_HEALTH" == *"ok"* ]]; then
        echo -e "${GREEN}✅ Health endpoint accessible via domain${NC}"
    else
        echo -e "${RED}❌ Health endpoint not accessible via domain${NC}"
    fi
    
    # Test API via domain
    EXTERNAL_API=$(curl -s -X POST https://$DOMAIN/api/create-web-call \
        -H "Content-Type: application/json" \
        -H "Origin: https://example.com" \
        -d '{"agentId":"test"}' 2>/dev/null || echo "failed")
    
    if [[ "$EXTERNAL_API" != "failed" ]]; then
        echo -e "${GREEN}✅ API accessible via domain${NC}"
        echo "   Response: ${EXTERNAL_API:0:100}..."
    else
        echo -e "${RED}❌ API not accessible via domain${NC}"
        echo "   This is likely the issue!"
    fi
fi
echo ""

# 9. Show server logs
echo -e "${YELLOW}9. Recent server logs...${NC}"
if systemctl is-active retell-widget-backend > /dev/null 2>&1; then
    sudo journalctl -u retell-widget-backend -n 10 --no-pager
elif [ -f "server/server.log" ]; then
    tail -10 server/server.log
else
    echo "   No logs available"
fi
echo ""

# DIAGNOSIS RESULTS
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    DIAGNOSIS COMPLETE                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Provide specific fix based on findings
echo -e "${GREEN}RECOMMENDED FIXES:${NC}"
echo ""

# If server not running
if ! sudo lsof -i :3001 | grep LISTEN > /dev/null 2>&1; then
    echo "1. Start the server:"
    echo "   sudo systemctl start retell-widget-backend"
    echo "   OR"
    echo "   cd server && node server.js"
    echo ""
fi

# If API key missing
if ! grep -q "RETELL_API_KEY=retell_sk_" server/.env 2>/dev/null; then
    echo "2. Add your Retell API key to server/.env:"
    echo "   RETELL_API_KEY=retell_sk_your_actual_key_here"
    echo ""
fi

# If CORS not configured
if ! grep -q "UNIVERSAL_ACCESS=true\|ALLOWED_ORIGINS=\*" server/.env 2>/dev/null; then
    echo "3. Enable universal access in server/.env:"
    echo "   UNIVERSAL_ACCESS=true"
    echo "   ALLOWED_ORIGINS=*"
    echo ""
fi

# If Nginx not configured
if ! grep -r "proxy_pass.*3001" /etc/nginx/sites-enabled/ > /dev/null 2>&1; then
    echo "4. Configure Nginx proxy - add to your site config:"
    echo "   location /api/ {"
    echo "       proxy_pass http://localhost:3001/api/;"
    echo "       proxy_http_version 1.1;"
    echo "       proxy_set_header Host \$host;"
    echo "   }"
    echo ""
fi

echo -e "${YELLOW}TEST YOUR WIDGET:${NC}"
echo "1. Open browser console (F12)"
echo "2. Try to make a call with the widget"
echo "3. Check Network tab for the failed request"
echo "4. Check Console for error details"
echo ""
echo "Share the output of this script if you need more help!"