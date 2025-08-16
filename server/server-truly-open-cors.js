const express = require('express');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// MANUAL CORS - Set headers explicitly to ensure '*' is actually sent
app.use((req, res, next) => {
  // Always set these headers for EVERY response
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  
  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.header('Access-Control-Max-Age', '86400'); // 24 hours
    return res.sendStatus(204);
  }
  
  next();
});

// Parse JSON
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    cors: 'MANUALLY SET - Sends literal * header',
    timestamp: new Date().toISOString()
  });
});

// Main API endpoint
app.post('/api/create-web-call', async (req, res) => {
  try {
    console.log('📞 Creating web call from:', req.headers.origin || 'unknown');
    
    // Dynamic import for node-fetch (handles both v2 and v3)
    let fetch;
    try {
      fetch = require('node-fetch');
    } catch (e) {
      const { default: fetchModule } = await import('node-fetch');
      fetch = fetchModule;
    }
    
    if (!process.env.RETELL_API_KEY) {
      console.error('❌ Missing RETELL_API_KEY');
      return res.status(500).json({ error: 'Server configuration error' });
    }
    
    const agentId = req.body.agent_id || process.env.RETELL_AGENT_ID;
    
    if (!agentId) {
      console.error('❌ Missing agent_id');
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
      console.error('❌ Retell API error:', errorText);
      return res.status(response.status).json({ 
        error: 'Failed to create web call',
        details: errorText 
      });
    }
    
    const data = await response.json();
    console.log('✅ Web call created successfully');
    res.json(data);
    
  } catch (error) {
    console.error('❌ Server error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Catch all - ensure CORS headers are on 404s too
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`
╔════════════════════════════════════════════════════════╗
║     RetellAI Widget Backend - TRULY OPEN CORS          ║
╠════════════════════════════════════════════════════════╣
║  Status: ✅ Running                                    ║
║  Port: ${PORT}                                            ║
║  CORS: MANUALLY SET TO * (literal asterisk)            ║
║                                                        ║
║  This server:                                          ║
║  - Sets Access-Control-Allow-Origin: * explicitly      ║
║  - Does NOT use cors package (avoiding issues)         ║
║  - Will work from ANY origin, guaranteed               ║
╚════════════════════════════════════════════════════════╝
  `);
  
  console.log('📋 Configuration:');
  console.log(`   - API Key: ${process.env.RETELL_API_KEY ? '✅ Set' : '❌ Missing'}`);
  console.log(`   - Agent ID: ${process.env.RETELL_AGENT_ID || 'Will use from request'}`);
  console.log('   - CORS: Manually setting * header on EVERY response');
  console.log('');
  console.log('⚠️  Headers being sent:');
  console.log('   Access-Control-Allow-Origin: *');
  console.log('   Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH');
  console.log('   Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization');
});
