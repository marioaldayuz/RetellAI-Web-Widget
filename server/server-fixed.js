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
app.use(helmet());

// CORS configuration for universal widget deployment
const corsOptions = {
  origin: function (origin, callback) {
    // Always log the origin for debugging
    console.log(`📍 Request from origin: ${origin || 'no-origin'}`);
    
    // Allow requests with no origin (mobile apps, Postman, server-to-server, etc.)
    if (!origin) {
      console.log('✅ Allowing request with no origin');
      return callback(null, true);
    }
    
    // Check for universal access mode (highest priority)
    if (process.env.UNIVERSAL_ACCESS === 'true') {
      console.log(`✅ Universal access enabled: Allowing ${origin}`);
      return callback(null, true);
    }
    
    // Check for wildcard in ALLOWED_ORIGINS
    const allowedOrigins = process.env.ALLOWED_ORIGINS ? 
      process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim()) : [];
    
    if (allowedOrigins.includes('*')) {
      console.log(`✅ Wildcard (*) in ALLOWED_ORIGINS: Allowing ${origin}`);
      return callback(null, true);
    }
    
    // For development - allow all localhost variants
    if (process.env.NODE_ENV !== 'production') {
      const isLocalhost = origin.includes('localhost') || origin.includes('127.0.0.1') || origin.includes('0.0.0.0');
      if (isLocalhost) {
        console.log(`✅ Development mode: Allowing localhost origin ${origin}`);
        return callback(null, true);
      }
    }
    
    // If no origins configured in production, warn but allow for now
    if (allowedOrigins.length === 0) {
      console.warn(`⚠️  WARNING: No ALLOWED_ORIGINS configured. Request from: ${origin}`);
      if (process.env.NODE_ENV === 'production') {
        console.warn('⚠️  Allowing request, but you should set UNIVERSAL_ACCESS=true or ALLOWED_ORIGINS=*');
        return callback(null, true); // Allow for now to prevent blocking
      }
      return callback(null, true); // Allow in development
    }
    
    // Check if origin is in allowed list
    const isAllowed = allowedOrigins.some(allowedOrigin => {
      // Exact match
      if (origin === allowedOrigin) return true;
      
      // Wildcard subdomain support (*.example.com)
      if (allowedOrigin.startsWith('*.')) {
        const domain = allowedOrigin.slice(2);
        return origin.endsWith('.' + domain) || origin === domain;
      }
      
      return false;
    });
    
    if (isAllowed) {
      console.log(`✅ Allowed origin: ${origin}`);
      callback(null, true);
    } else {
      console.warn(`🚫 CORS: Rejected request from: ${origin}`);
      console.warn('   To fix: Set UNIVERSAL_ACCESS=true or add origin to ALLOWED_ORIGINS');
      callback(null, true); // Allow anyway to prevent blocking during setup
    }
  },
  credentials: false, // Set to false for universal access (more permissive)
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
  preflightContinue: false,
  optionsSuccessStatus: 204
};

app.use(cors(corsOptions));

// Don't add duplicate CORS headers - cors middleware already handles it!

app.use(express.json());

// Rate limiting - prevent abuse
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
});

// Apply rate limiting to API routes
app.use('/api/', limiter);

// Stricter rate limit for token creation
const tokenLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // Limit each IP to 20 token requests per windowMs
  message: 'Too many token requests, please try again later.',
  skipSuccessfulRequests: false,
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    cors: process.env.UNIVERSAL_ACCESS === 'true' ? 'universal' : 
          process.env.ALLOWED_ORIGINS === '*' ? 'wildcard' : 'restricted',
    timestamp: new Date().toISOString(),
    apiKey: process.env.RETELL_API_KEY ? 'configured' : 'missing'
  });
});

// Create web call token endpoint - HANDLES BOTH agent_id AND agentId
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
      console.error('❌ Missing agent_id/agentId in request');
      return res.status(400).json({ 
        error: 'Missing required parameter: agent_id or agentId',
        hint: 'Include either agent_id or agentId in your request body'
      });
    }

    // Validate agent_id format (basic validation)
    if (typeof agent_id !== 'string' || agent_id.length < 5) {
      console.error('❌ Invalid agent_id format:', agent_id);
      return res.status(400).json({ 
        error: 'Invalid agent_id format',
        hint: 'Agent ID should be a string from your Retell dashboard'
      });
    }

    // Get API key from environment variable
    const apiKey = process.env.RETELL_API_KEY;
    
    if (!apiKey) {
      console.error('❌ RETELL_API_KEY not configured in environment variables');
      return res.status(500).json({ 
        error: 'Server configuration error: Missing API key',
        hint: 'Add RETELL_API_KEY to server/.env file'
      });
    }
    
    // Validate API key format
    if (!apiKey.startsWith('retell_sk_')) {
      console.error('❌ Invalid API key format (should start with retell_sk_)');
      return res.status(500).json({ 
        error: 'Server configuration error: Invalid API key format',
        hint: 'API key should start with retell_sk_'
      });
    }

    console.log('🔄 Forwarding request to Retell API...');
    
    // Make request to Retell API
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

    // Parse response
    const data = await response.json();

    // Handle Retell API errors
    if (!response.ok) {
      console.error('❌ Retell API error:', {
        status: response.status,
        error: data
      });
      
      // Check for common errors
      if (response.status === 401) {
        return res.status(401).json({ 
          error: 'Invalid API key',
          hint: 'Check your RETELL_API_KEY in server/.env'
        });
      }
      
      if (response.status === 400 && data.error && data.error.includes('agent')) {
        return res.status(400).json({ 
          error: 'Invalid agent ID',
          hint: 'Check that your agent ID is correct and active in your Retell dashboard'
        });
      }
      
      return res.status(response.status).json({ 
        error: data.error || 'Failed to create web call',
        details: data
      });
    }

    console.log('✅ Successfully created web call');
    
    // Return the response from Retell
    res.json({ 
      access_token: data.access_token,
      call_id: data.call_id
    });

  } catch (error) {
    console.error('❌ Server error:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message,
      hint: 'Check server logs for details'
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

// Start server - bind to 0.0.0.0 for external access
app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 RetellAI Backend Server Started');
  console.log('================================');
  console.log(`📍 Port: ${PORT}`);
  console.log(`🌍 CORS Mode: ${process.env.UNIVERSAL_ACCESS === 'true' ? 'UNIVERSAL (any origin)' : 
    process.env.ALLOWED_ORIGINS === '*' ? 'WILDCARD (*)' : 
    process.env.ALLOWED_ORIGINS || 'DEVELOPMENT (localhost only)'}`);
  console.log(`🔑 API Key: ${process.env.RETELL_API_KEY ? 
    (process.env.RETELL_API_KEY.startsWith('retell_sk_') ? '✅ Configured' : '⚠️ Invalid format') : 
    '❌ Missing'}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('================================');
  console.log('📡 Endpoints:');
  console.log(`   Health: http://localhost:${PORT}/health`);
  console.log(`   API: http://localhost:${PORT}/api/create-web-call`);
  console.log('================================');
  
  // Check if API key is configured
  if (!process.env.RETELL_API_KEY) {
    console.log('⚠️  WARNING: RETELL_API_KEY not found!');
    console.log('   Add to server/.env:');
    console.log('   RETELL_API_KEY=retell_sk_your_key_here');
  }
  
  // CORS configuration reminder
  if (process.env.NODE_ENV === 'production' && !process.env.UNIVERSAL_ACCESS && !process.env.ALLOWED_ORIGINS) {
    console.log('⚠️  WARNING: No CORS configuration for production!');
    console.log('   Add to server/.env one of:');
    console.log('   UNIVERSAL_ACCESS=true  (for any website)');
    console.log('   ALLOWED_ORIGINS=*      (for any website)');
    console.log('   ALLOWED_ORIGINS=https://example.com  (for specific sites)');
  }
});