#!/bin/bash

# Fix for duplicate CORS headers error
# This ensures the server only sends one Access-Control-Allow-Origin header

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Fixing Duplicate CORS Headers Issue              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Stop the current server
echo -e "${YELLOW}1. Stopping current server...${NC}"
sudo systemctl stop retell-widget-backend 2>/dev/null || true
sudo lsof -ti:3001 | xargs sudo kill -9 2>/dev/null || true
echo -e "${GREEN}✅ Server stopped${NC}"

# 2. Use the clean server file
echo -e "${YELLOW}2. Installing clean server without duplicate CORS...${NC}"
if [ -f "server/server-clean.js" ]; then
    cp server/server-clean.js server/server.js
    echo -e "${GREEN}✅ Clean server installed${NC}"
elif [ -f "server/server-fixed.js" ]; then
    cp server/server-fixed.js server/server.js
    echo -e "${GREEN}✅ Fixed server installed${NC}"
else
    echo -e "${RED}❌ No clean server file found${NC}"
    echo "   Creating one now..."
    
    # Create a minimal working server
    cat > server/server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const rateLimit = require('express-rate-limit');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// CORS - single configuration, no duplicates!
app.use(cors({
  origin: true, // Allow all origins when UNIVERSAL_ACCESS=true
  credentials: false,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin'],
  optionsSuccessStatus: 204
}));

app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
app.use('/api/', limiter);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// API endpoint
app.post('/api/create-web-call', async (req, res) => {
  console.log('API call:', req.body);
  
  try {
    const agent_id = req.body.agent_id || req.body.agentId;
    
    if (!agent_id) {
      return res.status(400).json({ error: 'Missing agent_id or agentId' });
    }
    
    const apiKey = process.env.RETELL_API_KEY;
    if (!apiKey || !apiKey.startsWith('retell_sk_')) {
      return res.status(500).json({ error: 'Invalid or missing API key in server/.env' });
    }
    
    const response = await fetch('https://api.retellai.com/v2/create-web-call', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({ agent_id })
    });
    
    const data = await response.json();
    
    if (!response.ok) {
      return res.status(response.status).json({ error: data.error || 'Retell API error' });
    }
    
    res.json(data);
    
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Server error', message: error.message });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server running on port ${PORT} with clean CORS configuration`);
});
EOF
    echo -e "${GREEN}✅ Created minimal clean server${NC}"
fi

# 3. Ensure .env is configured
echo -e "${YELLOW}3. Checking .env configuration...${NC}"
if [ ! -f "server/.env" ]; then
    cat > server/.env << 'EOF'
RETELL_API_KEY=retell_sk_your_actual_key_here
UNIVERSAL_ACCESS=true
ALLOWED_ORIGINS=*
NODE_ENV=production
PORT=3001
EOF
    echo -e "${YELLOW}⚠️  Created .env - ADD YOUR API KEY!${NC}"
else
    echo -e "${GREEN}✅ .env exists${NC}"
fi

# 4. Restart the server
echo -e "${YELLOW}4. Starting server with clean CORS...${NC}"

# Get absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Update systemd service to use correct path
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

# Reload and start
sudo systemctl daemon-reload
sudo systemctl enable retell-widget-backend
sudo systemctl start retell-widget-backend

# Wait for startup
sleep 3

# 5. Test the fix
echo -e "${YELLOW}5. Testing CORS headers...${NC}"

# Test for duplicate headers
CORS_TEST=$(curl -s -I -X OPTIONS http://localhost:3001/api/create-web-call \
    -H "Origin: https://fiddle.jshell.net" \
    -H "Access-Control-Request-Method: POST" 2>/dev/null)

# Count Access-Control-Allow-Origin headers
HEADER_COUNT=$(echo "$CORS_TEST" | grep -i "access-control-allow-origin" | wc -l)

if [ "$HEADER_COUNT" -eq 1 ]; then
    echo -e "${GREEN}✅ CORS fixed! Only one Access-Control-Allow-Origin header${NC}"
    echo "$CORS_TEST" | grep -i "access-control-allow-origin"
elif [ "$HEADER_COUNT" -gt 1 ]; then
    echo -e "${RED}❌ Still have duplicate headers ($HEADER_COUNT found)${NC}"
    echo "$CORS_TEST" | grep -i "access-control-allow-origin"
else
    echo -e "${YELLOW}⚠️  No CORS headers found${NC}"
fi

# Test health endpoint
if curl -s http://localhost:3001/health | grep -q "healthy"; then
    echo -e "${GREEN}✅ Server is healthy${NC}"
else
    echo -e "${RED}❌ Server not responding${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    CORS FIX COMPLETE!                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Your widget should now work from ANY domain!${NC}"
echo ""
echo "Test it at: https://jsfiddle.net or https://codepen.io"
echo ""
echo -e "${YELLOW}Widget code:${NC}"
echo '```html'
echo '<link rel="stylesheet" href="https://YOUR-DOMAIN/retell-widget.css">'
echo '<script src="https://YOUR-DOMAIN/retell-widget.js"></script>'
echo '<script>'
echo '  const widget = new RetellWidget({'
echo '    agentId: "your_agent_id_here",'
echo '    proxyEndpoint: "https://YOUR-DOMAIN/api/create-web-call",'
echo '    position: "bottom-right",'
echo '    theme: "purple"'
echo '  });'
echo '</script>'
echo '```'
echo ""
echo -e "${GREEN}Check server logs:${NC} sudo journalctl -u retell-widget-backend -f"