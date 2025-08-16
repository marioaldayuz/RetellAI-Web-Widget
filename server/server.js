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
    
    // If no origins configured, decide based on environment
    if (allowedOrigins.length === 0) {
      console.warn(`⚠️  WARNING: No ALLOWED_ORIGINS configured. Request from: ${origin}`);
      if (process.env.NODE_ENV === 'production') {
        return callback(new Error('CORS: No allowed origins configured. Set ALLOWED_ORIGINS=* for universal access.'));
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
      callback(new Error(`CORS: Origin ${origin} not allowed. Add to ALLOWED_ORIGINS or set ALLOWED_ORIGINS=* for universal access.`));
    }
  },
  credentials: false, // Set to false for universal access (more permissive)
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  preflightContinue: false,
  optionsSuccessStatus: 204
};

// Apply CORS middleware - this handles ALL CORS headers
app.use(cors(corsOptions));

// IMPORTANT: Don't set duplicate CORS headers elsewhere!
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
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Create web call token endpoint
app.post('/api/create-web-call', tokenLimiter, async (req, res) => {
  try {
    // Validate request body
    const { agent_id } = req.body;
    
    if (!agent_id) {
      return res.status(400).json({ 
        error: 'Missing required parameter: agent_id' 
      });
    }

    // Validate agent_id format (basic validation)
    if (typeof agent_id !== 'string' || agent_id.length < 10) {
      return res.status(400).json({ 
        error: 'Invalid agent_id format' 
      });
    }

    // Get API key from environment variable
    const apiKey = process.env.RETELL_API_KEY;
    
    if (!apiKey) {
      console.error('RETELL_API_KEY not configured in environment variables');
      return res.status(500).json({ 
        error: 'Server configuration error' 
      });
    }

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
      console.error('Retell API error:', data);
      return res.status(response.status).json({ 
        error: data.error || 'Failed to create web call' 
      });
    }

    // Return only the access token to the client
    res.json({ 
      access_token: data.access_token,
      // Don't include any sensitive information
    });

  } catch (error) {
    console.error('Server error:', error);
    res.status(500).json({ 
      error: 'Internal server error' 
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({ 
    error: err.message || 'Internal server error' 
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Proxy server running on http://localhost:${PORT}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
  
  // Check if API key is configured
  if (!process.env.RETELL_API_KEY) {
    console.warn('⚠️  WARNING: RETELL_API_KEY not found in environment variables!');
    console.warn('⚠️  Please create a .env file with your API key');
  } else {
    console.log('✅ API key configured');
  }
  
  // Check CORS configuration
  if (process.env.UNIVERSAL_ACCESS === 'true') {
    console.log('🌐 UNIVERSAL ACCESS MODE: Widget can be embedded on ANY website');
    console.log('⚠️  WARNING: This allows ALL domains. Only use if you want a public widget.');
  } else if (process.env.NODE_ENV === 'production') {
    if (!process.env.ALLOWED_ORIGINS) {
      console.warn('⚠️  WARNING: ALLOWED_ORIGINS not configured for production!');
      console.warn('⚠️  Options:');
      console.warn('   - Set ALLOWED_ORIGINS=* for universal access');
      console.warn('   - Set ALLOWED_ORIGINS=https://client1.com,https://client2.com for specific domains');
      console.warn('   - Set UNIVERSAL_ACCESS=true for completely open access');
    } else {
      const origins = process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim());
      if (origins.includes('*')) {
        console.log('🌐 WILDCARD ACCESS: Widget can be embedded on ANY website');
      } else {
        console.log(`✅ CORS configured for specific origins: ${origins.join(', ')}`);
      }
    }
  } else {
    console.log('🔧 Development mode: CORS allows localhost origins');
  }
});
