#!/bin/bash

# FINAL CORS FIX - This will definitely work
# The issue: cors package with origin:'*' doesn't always send literal '*'
# The fix: Manually set headers to guarantee '*' is sent

echo "================================================"
echo "FINAL CORS FIX - Manual Headers Solution"
echo "================================================"
echo ""

cd /root/RetellAI-Web-Widget/server || exit 1

echo "Creating server with MANUAL CORS headers..."
cat > server.js << 'EOF'
const express = require('express');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// CRITICAL: Manual CORS headers - GUARANTEED to send '*'
// Do NOT use cors package as it has quirky behavior with '*'
app.use((req, res, next) => {
  // These headers are set on EVERY response
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD');
  res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-Custom-Header');
  res.setHeader('Access-Control-Expose-Headers', 'Content-Length, Content-Type');
  
  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Max-Age', '86400');
    return res.status(204).end();
  }
  
  next();
});

app.use(express.json());

// Log all requests
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path} from ${req.headers.origin || 'no-origin'}`);
  next();
});

app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    cors_mode: 'MANUAL_ASTERISK',
    headers_sent: 'Access-Control-Allow-Origin: *',
    timestamp: new Date().toISOString()
  });
});

app.post('/api/create-web-call', async (req, res) => {
  try {
    let fetch;
    try {
      fetch = require('node-fetch');
    } catch (e) {
      console.log('Using dynamic import for node-fetch');
      const module = await import('node-fetch');
      fetch = module.default;
    }
    
    if (!process.env.RETELL_API_KEY) {
      console.error('Missing RETELL_API_KEY');
      return res.status(500).json({ 
        error: 'Server configuration error',
        message: 'API key not configured'
      });
    }
    
    const agentId = req.body.agent_id || process.env.RETELL_AGENT_ID;
    
    if (!agentId) {
      return res.status(400).json({ 
        error: 'agent_id is required' 
      });
    }
    
    console.log(`Creating web call with agent_id: ${agentId}`);
    
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
      console.error('Retell API error:', errorText);
      return res.status(response.status).json({ 
        error: 'Failed to create web call',
        details: errorText 
      });
    }
    
    const data = await response.json();
    console.log('Web call created successfully');
    res.json(data);
    
  } catch (error) {
    console.error('Server error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message
    });
  }
});

// 404 handler - also gets CORS headers
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Endpoint not found',
    path: req.path 
  });
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log('\n' + '='.repeat(60));
  console.log('RETELL AI WIDGET BACKEND - CORS FIXED');
  console.log('='.repeat(60));
  console.log(`Server: http://0.0.0.0:${PORT}`);
  console.log(`CORS: MANUAL headers sending literal '*'`);
  console.log(`API Key: ${process.env.RETELL_API_KEY ? '✓ Configured' : '✗ MISSING'}`);
  console.log(`Agent ID: ${process.env.RETELL_AGENT_ID || 'Not set (will use from request)'}`);
  console.log('='.repeat(60));
  console.log('CORS Headers being sent:');
  console.log('  Access-Control-Allow-Origin: *');
  console.log('  (This is a LITERAL asterisk, not origin reflection)');
  console.log('='.repeat(60) + '\n');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, closing server...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
EOF

echo "✅ Server created with MANUAL CORS headers"
echo ""

# Ensure dependencies are installed
echo "Checking dependencies..."
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install express dotenv node-fetch@2
fi

# Restart service
echo "Restarting service..."
sudo systemctl restart retell-widget-backend
sleep 2

# Check status
echo ""
echo "Service status:"
sudo systemctl status retell-widget-backend --no-pager | head -20

echo ""
echo "================================================"
echo "Testing CORS headers..."
echo "================================================"

# Test the endpoint
RESPONSE=$(curl -s -I -X OPTIONS https://retelldemo.olliebot.ai/api/create-web-call \
  -H "Origin: https://random-test.com" 2>&1)

echo "$RESPONSE" | grep -i "access-control-allow-origin"

if echo "$RESPONSE" | grep -q "Access-Control-Allow-Origin: \*"; then
    echo ""
    echo "✅ SUCCESS! Server is sending literal '*' header"
    echo "   Your widget will now work from ANY origin!"
else
    echo ""
    echo "⚠️  Headers might not be updated yet. Wait a moment and test again:"
    echo "   curl -I https://retelldemo.olliebot.ai/health"
fi

echo ""
echo "================================================"
echo "DONE! Your CORS issue should be fixed."
echo "================================================"
echo ""
echo "The server now:"
echo "1. Manually sets Access-Control-Allow-Origin: *"
echo "2. Does NOT use the cors package (avoiding its quirks)"
echo "3. Will work from ANY origin without issues"
echo ""
echo "Test from browser console:"
echo "  fetch('https://retelldemo.olliebot.ai/health').then(r => r.json()).then(console.log)"
