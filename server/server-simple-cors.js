const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const fetch = require('node-fetch');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// SIMPLEST CORS CONFIGURATION - Allow EVERYTHING
app.use(cors({
  origin: '*',  // Allow ALL origins
  credentials: false,  // Don't send cookies (simpler)
  methods: '*',  // Allow all methods
  allowedHeaders: '*',  // Allow all headers
}));

// Parse JSON
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok',
    cors: 'WIDE OPEN - Allows all origins',
    timestamp: new Date().toISOString()
  });
});

// Main API endpoint
app.post('/api/create-web-call', async (req, res) => {
  try {
    console.log('📞 Creating web call from:', req.headers.origin || 'unknown');
    
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

// Start server
app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════╗
║        RetellAI Widget Backend - SIMPLE CORS           ║
╠════════════════════════════════════════════════════════╣
║  Status: ✅ Running                                    ║
║  Port: ${PORT}                                            ║
║  CORS: * (Allows ALL origins - completely open)        ║
║                                                        ║
║  ⚠️  This server accepts requests from ANY origin!     ║
║  Perfect for widgets that need to work everywhere.     ║
╚════════════════════════════════════════════════════════╝
  `);
  
  console.log('📋 Configuration:');
  console.log(`   - API Key: ${process.env.RETELL_API_KEY ? '✅ Set' : '❌ Missing'}`);
  console.log(`   - Agent ID: ${process.env.RETELL_AGENT_ID || 'Will use from request'}`);
  console.log('   - CORS: Accepting ALL origins (*)');
}); 