#!/bin/bash

# Fix for duplicate Access-Control-Allow-Origin headers
# Problem: Both nginx AND Express are adding headers
# Solution: Only Express should add headers, nginx should just proxy

echo "================================================"
echo "FIX FOR DUPLICATE CORS HEADERS"
echo "================================================"
echo "Issue: Server sending both * and https://app.olliebot.ai"
echo "Fix: Remove ALL CORS from nginx, use Express only"
echo "================================================"
echo ""

# Step 1: Remove CORS from nginx
echo "Step 1: Removing ALL CORS headers from nginx..."
echo "------------------------------------------------"

# Create clean nginx config
sudo tee /etc/nginx/sites-available/retelldemo.olliebot.ai > /dev/null << 'NGINX_CONFIG'
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

    client_max_body_size 10M;

    # NO CORS headers here - Express handles everything
    
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
NGINX_CONFIG

echo "✅ Nginx config updated (no CORS headers)"

# Step 2: Update Express server
echo ""
echo "Step 2: Updating Express server..."
echo "------------------------------------------------"

cd /root/RetellAI-Web-Widget/server || exit 1

cat > server.js << 'EXPRESS_SERVER'
const express = require('express');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// ONLY set CORS headers ONCE
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');
  
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
  next();
});

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    cors: 'single-asterisk-only'
  });
});

app.post('/api/create-web-call', async (req, res) => {
  try {
    const fetch = require('node-fetch');
    
    if (!process.env.RETELL_API_KEY) {
      return res.status(500).json({ error: 'Missing API key' });
    }
    
    const agentId = req.body.agent_id || process.env.RETELL_AGENT_ID;
    if (!agentId) {
      return res.status(400).json({ error: 'agent_id required' });
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
    
    const data = await response.json();
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Server on ${PORT} - CORS: * only (no duplicates)`);
});
EXPRESS_SERVER

echo "✅ Express server updated"

# Step 3: Reload services
echo ""
echo "Step 3: Reloading services..."
echo "------------------------------------------------"

sudo nginx -t && sudo systemctl reload nginx
echo "✅ Nginx reloaded"

sudo systemctl restart retell-widget-backend
echo "✅ Backend restarted"

# Step 4: Test
echo ""
echo "Step 4: Testing headers..."
echo "------------------------------------------------"

sleep 3

HEADERS=$(curl -s -I https://retelldemo.olliebot.ai/health 2>&1)
echo "$HEADERS" | grep -i "access-control-allow-origin"

COUNT=$(echo "$HEADERS" | grep -i "access-control-allow-origin" | wc -l)

echo ""
if [ "$COUNT" -eq 1 ]; then
    echo "✅ SUCCESS! Only ONE Access-Control-Allow-Origin header"
    if echo "$HEADERS" | grep -q "Access-Control-Allow-Origin: \*"; then
        echo "✅ Header value is * (correct)"
    fi
else
    echo "⚠️ Found $COUNT Access-Control-Allow-Origin headers"
    echo "Check nginx config: grep -i 'add_header.*origin' /etc/nginx/sites-available/retelldemo.olliebot.ai"
fi

echo ""
echo "================================================"
echo "DONE! Test from browser:"
echo "fetch('https://retelldemo.olliebot.ai/health')"
echo "  .then(r => r.json())"
echo "  .then(console.log)"
echo "================================================"
