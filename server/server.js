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

// CORS configuration - adjust origins for production
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or Postman)
    if (!origin) return callback(null, true);
    
    // In production, replace with your actual domains
    const allowedOrigins = [
      'http://localhost:5173',
      'http://localhost:3000',
      'http://localhost:3001',
      // Add your production domains here
      // 'https://yourdomain.com',
      // 'https://app.yourdomain.com'
    ];
    
    if (allowedOrigins.indexOf(origin) !== -1 || process.env.NODE_ENV === 'development') {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));
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
});
