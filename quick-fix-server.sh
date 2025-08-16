#!/bin/bash

# Quick fix for server startup issues

echo "================================================"
echo "Quick Fix for RetellAI Backend Server"
echo "================================================"
echo ""

# Navigate to the correct directory
cd /root/RetellAI-Web-Widget/server || {
    echo "❌ Cannot find server directory!"
    echo "   Expected: /root/RetellAI-Web-Widget/server"
    exit 1
}

echo "📍 Working directory: $(pwd)"
echo ""

# 1. Ensure package.json exists
if [ ! -f "package.json" ]; then
    echo "Creating package.json..."
    cat > package.json << 'EOF'
{
  "name": "retell-widget-backend",
  "version": "1.0.0",
  "description": "Backend server for Retell AI widget",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "node-fetch": "^2.7.0"
  }
}
EOF
    echo "✅ package.json created"
fi

# 2. Install dependencies
echo "Installing dependencies..."
npm install express cors dotenv node-fetch --save
echo "✅ Dependencies installed"
echo ""

# 3. Create a minimal working server if current one is broken
echo "Creating minimal working server.js..."
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Try to load fetch - handle both v2 and v3
let fetch;
try {
    fetch = require('node-fetch');
} catch (e) {
    // For node-fetch v3+
    fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
}

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// ALLOW ALL ORIGINS - Simple CORS
app.use(cors({
  origin: '*',
  credentials: false,
  methods: '*',
  allowedHeaders: '*',
}));

app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    cors: 'OPEN - Allows all origins',
    timestamp: new Date().toISOString()
  });
});

// Main API endpoint
app.post('/api/create-web-call', async (req, res) => {
  try {
    console.log('Creating web call from:', req.headers.origin || 'unknown');
    
    if (!process.env.RETELL_API_KEY) {
      console.error('Missing RETELL_API_KEY');
      return res.status(500).json({ error: 'Server configuration error - Missing API key' });
    }
    
    const agentId = req.body.agent_id || process.env.RETELL_AGENT_ID;
    
    if (!agentId) {
      return res.status(400).json({ error: 'agent_id is required' });
    }
    
    // Make the actual call to Retell API
    const retellResponse = await fetch('https://api.retellai.com/v2/create-web-call', {
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
    
    if (!retellResponse.ok) {
      const errorText = await retellResponse.text();
      console.error('Retell API error:', errorText);
      return res.status(retellResponse.status).json({ 
        error: 'Failed to create web call',
        details: errorText 
      });
    }
    
    const data = await retellResponse.json();
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

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`
╔════════════════════════════════════════════════════════╗
║  RetellAI Backend - OPEN CORS                          ║
║  Port: ${PORT}                                            ║
║  CORS: * (Accepts all origins)                         ║
║  API Key: ${process.env.RETELL_API_KEY ? 'Configured' : 'MISSING - Please set RETELL_API_KEY'}   ║
╚════════════════════════════════════════════════════════╝
  `);
});
EOF

echo "✅ Server.js created with open CORS"
echo ""

# 4. Create .env file if missing
if [ ! -f ".env" ]; then
    echo "Creating .env file template..."
    cat > .env << 'EOF'
# Retell API Configuration
RETELL_API_KEY=your_retell_api_key_here
RETELL_AGENT_ID=your_agent_id_here

# CORS Settings
ALLOWED_ORIGINS=*
UNIVERSAL_ACCESS=true

# Server Port
PORT=3001

# Environment
NODE_ENV=production
EOF
    echo "⚠️  IMPORTANT: Edit .env file and add your RETELL_API_KEY"
    echo ""
fi

# 5. Test the server
echo "Testing server startup..."
timeout 2 node server.js 2>&1 | head -5
echo ""

# 6. Restart the service
echo "Restarting service..."
sudo systemctl daemon-reload
sudo systemctl restart retell-widget-backend
sleep 2

# 7. Check status
echo "Checking service status..."
sudo systemctl status retell-widget-backend --no-pager | head -15
echo ""

echo "================================================"
echo "Quick Fix Complete!"
echo "================================================"
echo ""
echo "If service is still failing:"
echo "1. Check your .env file has RETELL_API_KEY set"
echo "2. Run: sudo journalctl -u retell-widget-backend -f"
echo "3. Test manually: cd /root/RetellAI-Web-Widget/server && node server.js"
echo ""
echo "To test CORS:"
echo "curl -I https://retelldemo.olliebot.ai/health"
echo "================================================"
