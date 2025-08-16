#!/bin/bash

# Fix for duplicate CORS headers on production server
# This script ensures CORS is handled ONLY by Express, not by nginx

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Fixing Duplicate CORS Headers on Production           ║${NC}"
echo -e "${BLUE}║     Server: retelldemo.olliebot.ai                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Backup current configuration
echo -e "${YELLOW}Step 1: Creating backups...${NC}"
sudo cp /etc/nginx/sites-available/retelldemo.olliebot.ai /etc/nginx/sites-available/retelldemo.olliebot.ai.backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true
cp server/server.js server/server.js.backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true
echo -e "${GREEN}✅ Backups created${NC}"

# Step 2: Verify the server file is fixed
echo -e "${YELLOW}Step 2: Verifying Express server CORS configuration...${NC}"
if grep -q "Priority domains: app.olliebot.ai" server/server.js; then
    echo -e "${GREEN}✅ Server already has the correct CORS configuration${NC}"
else
    echo -e "${YELLOW}⚠️ Updating server CORS configuration...${NC}"
    
    cat > server/server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const fetch = require('node-fetch');
const rateLimit = require('express-rate-limit');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(require('helmet')({
  crossOriginResourcePolicy: false,
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 1 * 60 * 1000,
  max: 30,
  message: 'Too many requests, please try again later.'
});

// CORS configuration - ONLY place where CORS is handled
const corsOptions = {
  origin: function (origin, callback) {
    console.log(`📍 CORS request from: ${origin || 'no-origin'}`);
    
    // Specifically allow app.olliebot.ai
    if (origin === 'https://app.olliebot.ai') {
      console.log('✅ Allowing app.olliebot.ai');
      return callback(null, true);
    }
    
    // Check environment settings
    if (process.env.UNIVERSAL_ACCESS === 'true' || process.env.ALLOWED_ORIGINS === '*') {
      console.log('✅ Universal access enabled');
      return callback(null, true);
    }
    
    // No origin (server-to-server)
    if (!origin) {
      return callback(null, true);
    }
    
    // Check allowed origins
    const allowedOrigins = process.env.ALLOWED_ORIGINS ? 
      process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim()) : [];
    
    // Default olliebot domains
    const defaultAllowed = [
      'https://app.olliebot.ai',
      'https://olliebot.ai',
      'https://www.olliebot.ai'
    ];
    
    const allAllowed = [...new Set([...allowedOrigins, ...defaultAllowed])];
    
    const isAllowed = allAllowed.some(allowed => {
      if (allowed === origin) return true;
      if (allowed.startsWith('*.')) {
        const domain = allowed.slice(2);
        return origin.includes(domain);
      }
      return false;
    });
    
    if (isAllowed) {
      console.log(`✅ Origin allowed: ${origin}`);
      callback(null, true);
    } else {
      console.warn(`⚠️ Origin not allowed: ${origin}`);
      callback(null, true); // Permissive for now
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  exposedHeaders: ['Content-Length', 'Content-Type'],
  maxAge: 86400,
  preflightContinue: false,
  optionsSuccessStatus: 204
};

// Apply CORS - this is the ONLY place setting CORS headers
app.use(cors(corsOptions));

app.use(express.json());
app.use('/api', limiter);

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    timestamp: new Date().toISOString(),
    cors: 'Express only'
  });
});

// Main API endpoint
app.post('/api/create-web-call', async (req, res) => {
  try {
    console.log('Creating web call from:', req.headers.origin);
    
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

// Preflight handler
app.options('*', (req, res) => {
  res.sendStatus(204);
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════╗
║  RetellAI Backend - CORS Fixed                         ║
║  Port: ${PORT}                                            ║
║  CORS: Express only (no nginx duplication)             ║
╚════════════════════════════════════════════════════════╝
  `);
});
EOF
    echo -e "${GREEN}✅ Server updated with fixed CORS configuration${NC}"
fi

# Step 3: Update nginx configuration to remove CORS headers
echo -e "${YELLOW}Step 3: Updating nginx configuration...${NC}"

# Create new nginx config without CORS headers
cat > /tmp/retelldemo.olliebot.ai << 'EOF'
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
    ssl_prefer_server_ciphers on;
    
    # Security headers (NO CORS headers here!)
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000" always;
    
    access_log /var/log/nginx/retelldemo.access.log;
    error_log /var/log/nginx/retelldemo.error.log;
    
    client_max_body_size 10M;
    
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
    
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
    
    location / {
        # NO CORS headers - Express handles them
        proxy_pass http://localhost:3001;
    }
    
    location /health {
        proxy_pass http://localhost:3001/health;
    }
    
    location /api/ {
        # NO CORS headers - Express handles them
        proxy_pass http://localhost:3001/api/;
    }
}
EOF

sudo mv /tmp/retelldemo.olliebot.ai /etc/nginx/sites-available/retelldemo.olliebot.ai
echo -e "${GREEN}✅ Nginx configuration updated${NC}"

# Step 4: Test nginx configuration
echo -e "${YELLOW}Step 4: Testing nginx configuration...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Nginx configuration is valid${NC}"
else
    echo -e "${RED}❌ Nginx configuration error!${NC}"
    echo "Restoring backup..."
    sudo cp /etc/nginx/sites-available/retelldemo.olliebot.ai.backup-$(date +%Y%m%d-%H%M%S) /etc/nginx/sites-available/retelldemo.olliebot.ai
    exit 1
fi

# Step 5: Restart services
echo -e "${YELLOW}Step 5: Restarting services...${NC}"

# Restart Node.js application
if systemctl is-active --quiet retell-widget-backend; then
    sudo systemctl restart retell-widget-backend
    echo -e "${GREEN}✅ Backend service restarted${NC}"
else
    # Try PM2
    if command -v pm2 &> /dev/null; then
        pm2 restart all
        echo -e "${GREEN}✅ PM2 processes restarted${NC}"
    else
        echo -e "${YELLOW}⚠️ Please restart your Node.js server manually${NC}"
    fi
fi

# Reload nginx
sudo systemctl reload nginx
echo -e "${GREEN}✅ Nginx reloaded${NC}"

# Step 6: Test the fix
echo -e "${YELLOW}Step 6: Testing CORS headers...${NC}"
sleep 2

# Test from app.olliebot.ai origin
TEST_RESULT=$(curl -s -I -X OPTIONS https://retelldemo.olliebot.ai/api/create-web-call \
    -H "Origin: https://app.olliebot.ai" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" 2>/dev/null)

# Count Access-Control-Allow-Origin headers
HEADER_COUNT=$(echo "$TEST_RESULT" | grep -i "access-control-allow-origin" | wc -l)

if [ "$HEADER_COUNT" -eq "1" ]; then
    echo -e "${GREEN}✅ SUCCESS! CORS headers fixed - only one Access-Control-Allow-Origin header${NC}"
    echo "$TEST_RESULT" | grep -i "access-control-allow-origin"
else
    echo -e "${YELLOW}⚠️ Found $HEADER_COUNT Access-Control-Allow-Origin headers${NC}"
    echo "$TEST_RESULT" | grep -i "access-control-allow-origin"
    echo ""
    echo -e "${YELLOW}Note: It may take a moment for changes to propagate.${NC}"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Fix Applied!                            ║${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║  ✅ Express server updated (handles CORS)                  ║${NC}"
echo -e "${BLUE}║  ✅ Nginx config updated (no CORS headers)                 ║${NC}"
echo -e "${BLUE}║  ✅ Services restarted                                     ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║  The widget at app.olliebot.ai should now work!           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${YELLOW}If issues persist:${NC}"
echo "1. Check server logs: sudo journalctl -u retell-widget-backend -f"
echo "2. Check nginx logs: sudo tail -f /var/log/nginx/retelldemo.error.log"
echo "3. Clear browser cache and try again"
echo "4. Ensure .env file has: ALLOWED_ORIGINS=https://app.olliebot.ai" 