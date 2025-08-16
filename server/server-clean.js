const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: false,
}));

// CORS configuration - SINGLE source of truth for CORS headers
const corsOptions = {
  origin: function (origin, callback) {
    // Always log for debugging
    console.log(`📍 Request from origin: ${origin || 'no-origin'}`);
    
    // Universal access mode - allow ALL origins
    if (process.env.UNIVERSAL_ACCESS === 'true' || process.env.ALLOWED_ORIGINS === '*') {
      console.log('✅ Universal/Wildcard access enabled');
      return callback(null, true);
    }
    
    // Allow requests with no origin (Postman, server-to-server)
    if (!origin) {
      console.log('✅ Allowing request with no origin');
      return callback(null, true);
    }
    
    // Development mode - allow localhost
    if (process.env.NODE_ENV !== 'production') {
      const isLocalhost = origin.includes('localhost') || origin.includes('127.0.0.1');
      if (isLocalhost) {
        console.log('✅ Development mode: allowing localhost');
        return callback(null, true);
      }
    }
    
    // Check allowed origins list
    const allowedOrigins = process.env.ALLOWED_ORIGINS ? 
      process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim()) : [];
    
    if (allowedOrigins.length === 0) {
      // No origins configured - be permissive in development, warn in production
      console.warn('⚠️  No ALLOWED_ORIGINS configured');
      return callback(null, true);
    }
    
    // Check if origin is allowed
    const isAllowed = allowedOrigins.some(allowed => {
      if (allowed === origin) return true;
      if (allowed.startsWith('*.')) {
        const domain = allowed.slice(2);
        return origin.endsWith('.' + domain);
      }
      return false;
    });
    
    if (isAllowed) {
      console.log(`✅ Origin allowed: ${origin}`);
      callback(null, true);
    } else {
      console.warn(`⚠️  Origin not in allowed list: ${origin}`);
      // Be permissive to avoid blocking during setup
      callback(null, true);
    }
  },
  credentials: false,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin'],
  preflightContinue: false,
  optionsSuccessStatus: 204
};

// Apply CORS middleware ONCE - no duplicate headers!
app.use(cors(corsOptions));

// Parse JSON bodies
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter);

// Stricter rate limit for token creation
const tokenLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: 'Too many token requests, please try again later.',
  skipSuccessfulRequests: false,
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    cors: process.env.UNIVERSAL_ACCESS === 'true' ? 'universal' : 
          process.env.ALLOWED_ORIGINS === '*' ? 'wildcard' : 'configured',
    timestamp: new Date().toISOString()
  });
});

// Create web call endpoint - handles both agent_id and agentId
app.post('/api/create-web-call', tokenLimiter, async (req, res) => {
  console.log('📞 Received call request:', {
    origin: req.headers.origin,
    body: req.body,
    timestamp: new Date().toISOString()
  });
  
  try {
    // Accept both agent_id and agentId for compatibility
    const agent_id = req.body.agent_id || req.body.agentId;
    
    if (!agent_id) {
      console.error('❌ Missing agent_id/agentId');
      return res.status(400).json({ 
        error: 'Missing required parameter: agent_id or agentId' 
      });
    }

    // Validate agent_id format
    if (typeof agent_id !== 'string' || agent_id.length < 5) {
      console.error('❌ Invalid agent_id format');
      return res.status(400).json({ 
        error: 'Invalid agent_id format' 
      });
    }

    // Get API key
    const apiKey = process.env.RETELL_API_KEY;
    
    if (!apiKey) {
      console.error('❌ RETELL_API_KEY not configured');
      return res.status(500).json({ 
        error: 'Server configuration error: Missing API key',
        hint: 'Add RETELL_API_KEY to server/.env file'
      });
    }
    
    // Validate API key format
    if (!apiKey.startsWith('retell_sk_')) {
      console.error('❌ Invalid API key format');
      return res.status(500).json({ 
        error: 'Server configuration error: Invalid API key format',
        hint: 'API key should start with retell_sk_'
      });
    }

    console.log('🔄 Calling Retell API...');
    
    // Call Retell API
    const response = await fetch('https://api.retellai.com/v2/create-web-call', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        agent_id: agent_id
      })
    });

    const data = await response.json();

    if (!response.ok) {
      console.error('❌ Retell API error:', data);
      
      if (response.status === 401) {
        return res.status(401).json({ 
          error: 'Invalid API key. Check your RETELL_API_KEY in server/.env'
        });
      }
      
      return res.status(response.status).json({ 
        error: data.error || 'Failed to create web call',
        details: data
      });
    }

    console.log('✅ Successfully created web call');
    
    // Return the token
    res.json({ 
      access_token: data.access_token,
      call_id: data.call_id
    });

  } catch (error) {
    console.error('❌ Server error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Endpoint not found',
    available: ['/health', '/api/create-web-call']
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({ 
    error: err.message || 'Internal server error' 
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 RetellAI Backend Server Started');
  console.log('================================');
  console.log(`📍 Port: ${PORT}`);
  console.log(`🌍 CORS Mode: ${process.env.UNIVERSAL_ACCESS === 'true' ? 'UNIVERSAL' : 
    process.env.ALLOWED_ORIGINS === '*' ? 'WILDCARD' : 
    process.env.ALLOWED_ORIGINS || 'DEVELOPMENT'}`);
  console.log(`🔑 API Key: ${process.env.RETELL_API_KEY ? 
    (process.env.RETELL_API_KEY.startsWith('retell_sk_') ? '✅ Configured' : '⚠️ Invalid format') : 
    '❌ Missing'}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('================================');
  console.log('📡 Endpoints:');
  console.log(`   Health: http://localhost:${PORT}/health`);
  console.log(`   API: http://localhost:${PORT}/api/create-web-call`);
  console.log('================================');
  
  if (!process.env.RETELL_API_KEY) {
    console.log('⚠️  WARNING: Add your API key to server/.env');
    console.log('   RETELL_API_KEY=retell_sk_your_key_here');
  }
});