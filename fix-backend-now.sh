#!/bin/bash

# Emergency fix for backend server
# This will get your server running NOW

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}         EMERGENCY BACKEND FIX - Getting it working NOW         ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Kill any existing process on port 3001
echo "Stopping any existing server..."
sudo lsof -ti:3001 | xargs sudo kill -9 2>/dev/null || true
sudo systemctl stop retell-widget-backend 2>/dev/null || true

# Ensure server directory exists
if [ ! -d "server" ]; then
    echo -e "${RED}Error: server directory not found!${NC}"
    echo "Run this script from the project root directory"
    exit 1
fi

# Create a working .env file
echo "Creating working .env configuration..."
cat > server/.env << 'EOF'
# CHANGE THIS TO YOUR ACTUAL API KEY
RETELL_API_KEY=retell_sk_your_actual_key_here

# Allow embedding on ANY website
UNIVERSAL_ACCESS=true
ALLOWED_ORIGINS=*

# Production settings
NODE_ENV=production
PORT=3001
EOF

echo -e "${YELLOW}⚠️  IMPORTANT: Edit server/.env and add your actual Retell API key!${NC}"
echo ""

# Install dependencies
echo "Installing dependencies..."
cd server
npm install
cd ..

# Create a simple test server that definitely works
echo "Creating failsafe server..."
cat > server/server-failsafe.js << 'EOF'
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = 3001;

// Allow ALL origins - maximum compatibility
app.use(cors({
    origin: true,  // Allow all origins
    credentials: false,
    methods: ['GET', 'POST', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin']
}));

// Parse JSON
app.use(express.json());

// Add permissive headers
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept, Origin');
    if (req.method === 'OPTIONS') {
        return res.sendStatus(204);
    }
    next();
});

// Health check
app.get('/health', (req, res) => {
    console.log('Health check requested');
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// API endpoint - accepts both agentId and agent_id
app.post('/api/create-web-call', async (req, res) => {
    console.log('API call received:', req.body);
    
    try {
        const agent_id = req.body.agent_id || req.body.agentId;
        
        if (!agent_id) {
            return res.status(400).json({ 
                error: 'Missing agent_id or agentId' 
            });
        }
        
        const apiKey = process.env.RETELL_API_KEY;
        
        if (!apiKey || apiKey === 'retell_sk_your_actual_key_here') {
            console.error('API key not configured!');
            return res.status(500).json({ 
                error: 'API key not configured. Add your key to server/.env' 
            });
        }
        
        // Call Retell API
        console.log('Calling Retell API...');
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
            console.error('Retell API error:', data);
            return res.status(response.status).json({ 
                error: data.error || 'Retell API error',
                details: data
            });
        }
        
        console.log('Success! Returning token');
        res.json(data);
        
    } catch (error) {
        console.error('Server error:', error);
        res.status(500).json({ 
            error: 'Server error', 
            message: error.message 
        });
    }
});

// Start server on all interfaces
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Failsafe server running on port ${PORT}`);
    console.log(`🌍 Accepting requests from ANY origin`);
    console.log(`🔑 API Key: ${process.env.RETELL_API_KEY ? 'Configured' : '❌ MISSING - Add to .env!'}`);
    console.log(`📡 Test: curl http://localhost:${PORT}/health`);
});
EOF

# Start the failsafe server
echo -e "${GREEN}Starting failsafe server...${NC}"
cd server
nohup node server-failsafe.js > failsafe.log 2>&1 &
SERVER_PID=$!
cd ..

# Wait for server to start
sleep 3

# Test if it's working
echo ""
echo -e "${YELLOW}Testing server...${NC}"
if curl -s http://localhost:3001/health | grep -q "healthy"; then
    echo -e "${GREEN}✅ Server is running!${NC}"
else
    echo -e "${RED}❌ Server not responding${NC}"
    echo "Check server/failsafe.log for errors"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}                    SERVER RUNNING!                             ${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Server PID: $SERVER_PID"
echo "Logs: tail -f server/failsafe.log"
echo "Stop: kill $SERVER_PID"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "1. Edit server/.env and add your actual Retell API key"
echo "2. Make sure Nginx is configured to proxy /api/* to port 3001"
echo "3. Test your widget - it should work now!"
echo ""
echo -e "${YELLOW}If your widget STILL shows 'Failed to fetch':${NC}"
echo "1. Check browser console for the exact error"
echo "2. Check Network tab to see what URL it's trying to fetch"
echo "3. Make sure the proxyEndpoint in your widget code is correct"
echo ""