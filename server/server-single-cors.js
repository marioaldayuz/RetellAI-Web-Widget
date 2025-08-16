const express = require('express');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// CRITICAL: Set CORS headers ONCE and ONLY ONCE
// Do NOT use cors package, do NOT mention specific domains
app.use((req, res, next) => {
  // Set headers only if not already set
  if (!res.headersSent) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    res.setHeader('Access-Control-Expose-Headers', 'Content-Length, Content-Type');
  }
  
  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Max-Age', '86400');
    return res.status(204).end();
  }
  
  next();
});

// Parse JSON
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    cors: 'SINGLE * header only',
    timestamp: new Date().toISOString()
  });
});

// Main API endpoint
app.post('/api/create-web-call', async (req, res) => {
  try {
    console.log('Creating web call from:', req.headers.origin || 'unknown');
    
    // Dynamic import for node-fetch
    let fetch;
    try {
      fetch = require('node-fetch');
    } catch (e) {
      const { default: fetchModule } = await import('node-fetch');
      fetch = fetchModule;
    }
    
    if (!process.env.RETELL_API_KEY) {
      console.error('Missing RETELL_API_KEY');
      return res.status(500).json({ error: 'Server configuration error' });
    }
    
    const agentId = req.body.agent_id || process.env.RETELL_AGENT_ID;
    
    if (!agentId) {
      console.error('Missing agent_id');
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

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`
╔════════════════════════════════════════════════════════╗
║     RetellAI Backend - SINGLE CORS HEADER              ║
╠════════════════════════════════════════════════════════╣
║  Port: ${PORT}                                            ║
║  CORS: * (single header, no duplicates)                ║
║                                                        ║
║  NO app.olliebot.ai specific handling                  ║
║  NO duplicate headers                                  ║
║  Just a single Access-Control-Allow-Origin: *          ║
╚════════════════════════════════════════════════════════╝
  `);
  
  console.log('Configuration:');
  console.log(`  API Key: ${process.env.RETELL_API_KEY ? '✓' : '✗ Missing'}`);
  console.log(`  Headers: Access-Control-Allow-Origin: * (ONLY)`);
});
