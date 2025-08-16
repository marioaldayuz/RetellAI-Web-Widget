#!/bin/bash

# Deploy completely OPEN CORS configuration
# This allows the widget to be embedded ANYWHERE without restrictions

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Deploying OPEN CORS Configuration                      ║${NC}"
echo -e "${BLUE}║     This allows embedding from ANY origin                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Backup current server
echo -e "${YELLOW}Step 1: Creating backup...${NC}"
cp server/server.js server/server.backup-$(date +%Y%m%d-%H%M%S).js
echo -e "${GREEN}✅ Backup created${NC}"

# Step 2: Deploy the simple CORS server
echo -e "${YELLOW}Step 2: Deploying open CORS server...${NC}"

if [ -f "server/server-simple-cors.js" ]; then
    cp server/server-simple-cors.js server/server.js
    echo -e "${GREEN}✅ Simple CORS server deployed${NC}"
else
    echo "Creating simple CORS server..."
    cat > server/server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const fetch = require('node-fetch');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// ALLOW ALL ORIGINS - Completely open CORS
app.use(cors({
  origin: '*',
  credentials: false,
  methods: '*',
  allowedHeaders: '*',
}));

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    cors: 'OPEN - Allows all origins',
    timestamp: new Date().toISOString()
  });
});

app.post('/api/create-web-call', async (req, res) => {
  try {
    console.log('Request from:', req.headers.origin || 'unknown');
    
    if (!process.env.RETELL_API_KEY) {
      return res.status(500).json({ error: 'Server configuration error' });
    }
    
    const agentId = req.body.agent_id || process.env.RETELL_AGENT_ID;
    
    if (!agentId) {
      return res.status(400).json({ error: 'agent_id is required' });
    }
    
    const response = await fetch('https://api.retellai.com/v2/create-web-call', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.RETELL_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        agent_id: agentId,
        metadata: req.body.metadata || {}
      })
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      return res.status(response.status).json({ 
        error: 'Failed to create web call',
        details: errorText 
      });
    }
    
    const data = await response.json();
    res.json(data);
    
  } catch (error) {
    console.error('Server error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════╗
║  RetellAI Backend - OPEN CORS (Allows ALL origins)     ║
║  Port: ${PORT}                                            ║
║  CORS: * (Any website can use this widget)             ║
╚════════════════════════════════════════════════════════╝
  `);
});
EOF
fi

# Step 3: Create or update .env to enable universal access
echo -e "${YELLOW}Step 3: Setting environment for universal access...${NC}"
if [ -f "server/.env" ]; then
    # Add or update UNIVERSAL_ACCESS
    if grep -q "UNIVERSAL_ACCESS" server/.env; then
        sed -i 's/UNIVERSAL_ACCESS=.*/UNIVERSAL_ACCESS=true/' server/.env
    else
        echo "UNIVERSAL_ACCESS=true" >> server/.env
    fi
    
    # Add or update ALLOWED_ORIGINS
    if grep -q "ALLOWED_ORIGINS" server/.env; then
        sed -i 's/ALLOWED_ORIGINS=.*/ALLOWED_ORIGINS=*/' server/.env
    else
        echo "ALLOWED_ORIGINS=*" >> server/.env
    fi
else
    echo "UNIVERSAL_ACCESS=true" > server/.env
    echo "ALLOWED_ORIGINS=*" >> server/.env
fi
echo -e "${GREEN}✅ Environment configured for universal access${NC}"

# Step 4: Ensure nginx doesn't add CORS headers
echo -e "${YELLOW}Step 4: Checking nginx configuration...${NC}"

# Create a clean nginx config
cat > /tmp/nginx-clean-config << 'EOF'
server {
    listen 80;
    server_name retelldemo.olliebot.ai;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name retelldemo.olliebot.ai;

    ssl_certificate /etc/letsencrypt/live/retelldemo.olliebot.ai/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/retelldemo.olliebot.ai/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # NO CORS headers here - Express handles everything
    
    client_max_body_size 10M;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

echo -e "${YELLOW}To update nginx (on production server):${NC}"
echo "  sudo cp /tmp/nginx-clean-config /etc/nginx/sites-available/retelldemo.olliebot.ai"
echo "  sudo nginx -t && sudo systemctl reload nginx"

# Step 5: Restart instructions
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                 Deployment Complete!                       ║${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  Next steps on production server:                          ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║  1. Update nginx (if needed):                             ║${NC}"
echo -e "${BLUE}║     sudo cp /tmp/nginx-clean-config \\                     ║${NC}"
echo -e "${BLUE}║       /etc/nginx/sites-available/retelldemo.olliebot.ai   ║${NC}"
echo -e "${BLUE}║     sudo nginx -t && sudo systemctl reload nginx          ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║  2. Restart Node.js server:                               ║${NC}"
echo -e "${BLUE}║     sudo systemctl restart retell-widget-backend          ║${NC}"
echo -e "${BLUE}║     OR: pm2 restart all                                   ║${NC}"
echo -e "${BLUE}║     OR: Kill and restart manually                         ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║  The widget will now work from ANY origin!                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${YELLOW}Test with:${NC}"
echo "  curl -I -X OPTIONS https://retelldemo.olliebot.ai/api/create-web-call \\"
echo "    -H 'Origin: https://any-website.com'"
echo ""
echo "Should return: Access-Control-Allow-Origin: *" 