# Cross-Domain Widget Deployment Guide

## 🌐 **Architecture Overview**

```
┌─────────────────────────────────────────────┐
│           3rd Party Websites                │
│  ┌─────────────┐  ┌─────────────────────┐   │
│  │ Client A    │  │ Client B            │   │
│  │ domain-a.com│  │ company-b.org       │   │
│  │             │  │                     │   │
│  │ [Widget] ──────────┐    [Widget] ────────┼──┐
│  └─────────────┘  │   │    └─────────────────┘   │ │
└─────────────────────┼──┼─────────────────────────┘ │
                     │  │                           │
                     │  │    CORS Requests          │
                     │  │                           │
                     │  ▼                           │
┌─────────────────────┼──┼─────────────────────────┐ │
│  Your Backend Server│  │                         │ │
│  your-server.com    │  │                         │ │
│  ┌─────────────────▼──▼─────────────────┐       │ │
│  │ /api/create-web-call                │       │ │
│  │ • CORS enabled                      │       │ │
│  │ • Multiple origins allowed          │       │ │
│  │ • Returns access_token              │       │ │
│  └─────────────────┬───────────────────┘       │ │
│                    │                           │ │
└────────────────────┼───────────────────────────┘ │
                     │                             │
                     ▼                             │
  ┌─────────────────────────────────────────────┐  │
  │            Retell AI API                    │  │
  │         api.retellai.com                    │  │
  └─────────────────────────────────────────────┘  │
                                                   │
┌─────────────────────────────────────────────────┘
│  Optional: CDN for Widget Files
│  cdn.your-domain.com
│  ├── retell-widget.js
│  └── retell-widget.css
└─────────────────────────────────────────────────
```

## 🚀 **Deployment Steps**

### 1. **Prepare Widget Files**

```bash
# Build the widget
npm install
npm run build

# Generated files:
# dist/retell-widget.js    (424KB)
# dist/retell-widget.css   (15KB)
```

### 2. **Host Widget Files**

Choose one of these hosting options:

#### Option A: CDN/Static Hosting (Recommended)
```bash
# Upload to your CDN
aws s3 cp dist/retell-widget.js s3://your-cdn/v1/retell-widget.js
aws s3 cp dist/retell-widget.css s3://your-cdn/v1/retell-widget.css

# Or upload to any static hosting:
# - Cloudflare
# - AWS CloudFront
# - Google Cloud CDN
# - Your own server
```

#### Option B: Direct File Sharing
Provide the built files directly to clients to host on their servers.

### 3. **Configure Backend Server**

#### Express.js Example with CORS:

```javascript
const express = require('express');
const cors = require('cors');
const app = express();

// Configure CORS for multiple 3rd party domains
const allowedOrigins = [
  'https://client-website-1.com',
  'https://client-website-2.com',
  'https://another-client.org',
  // Add more as needed, or use pattern matching
];

app.use('/api', cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (mobile apps, etc)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    // For development, you might want to allow localhost
    if (origin && origin.includes('localhost')) {
      return callback(null, true);
    }
    
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

// The proxy endpoint
app.post('/api/create-web-call', async (req, res) => {
  try {
    const { agent_id } = req.body;
    
    // Validate agent_id (add your validation logic)
    if (!agent_id) {
      return res.status(400).json({ error: 'agent_id is required' });
    }
    
    // Call Retell AI API
    const response = await fetch('https://api.retellai.com/create-web-call', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.RETELL_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ agent_id })
    });
    
    if (!response.ok) {
      throw new Error(`Retell AI API error: ${response.status}`);
    }
    
    const data = await response.json();
    res.json({ access_token: data.access_token });
    
  } catch (error) {
    console.error('Create web call error:', error);
    res.status(500).json({ 
      error: 'Failed to create web call',
      details: error.message 
    });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`Retell proxy server running on port ${PORT}`);
});
```

### 4. **Client Integration**

Provide this integration code to your clients:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Client Website</title>
    <!-- Include widget CSS from your CDN -->
    <link rel="stylesheet" href="https://cdn.your-domain.com/v1/retell-widget.css">
</head>
<body>
    <!-- Client's website content -->
    <h1>Welcome to Client Website</h1>
    <p>This site now has an AI assistant widget!</p>
    
    <!-- Include widget JS from your CDN -->
    <script src="https://cdn.your-domain.com/v1/retell-widget.js"></script>
    
    <!-- Initialize the widget -->
    <script>
        new RetellWidget({
            agentId: 'client_specific_agent_id', // Each client gets their own agent ID
            proxyEndpoint: 'https://your-backend-server.com/api/create-web-call',
            position: 'bottom-right',
            theme: 'purple'
        });
    </script>
</body>
</html>
```

## 🔒 **Security Considerations**

### 1. **CORS Configuration**
```javascript
// Dynamic CORS based on database of allowed domains
app.use('/api', cors({
  origin: async function(origin, callback) {
    // Check if origin is in your database of allowed clients
    const isAllowed = await checkClientDatabase(origin);
    if (isAllowed) {
      callback(null, true);
    } else {
      callback(new Error('Domain not authorized'));
    }
  }
}));
```

### 2. **Rate Limiting**
```javascript
const rateLimit = require('express-rate-limit');

const createWebCallLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many call creation requests, please try again later'
});

app.use('/api/create-web-call', createWebCallLimiter);
```

### 3. **Agent ID Validation**
```javascript
// Validate agent IDs against your database
app.post('/api/create-web-call', async (req, res) => {
  const { agent_id } = req.body;
  const origin = req.get('origin');
  
  // Check if this domain is allowed to use this agent
  const isAuthorized = await validateAgentForDomain(agent_id, origin);
  if (!isAuthorized) {
    return res.status(403).json({ error: 'Unauthorized agent access' });
  }
  
  // Continue with call creation...
});
```

## 📊 **Monitoring & Analytics**

### Track Widget Usage:
```javascript
app.post('/api/create-web-call', async (req, res) => {
  // Log usage for analytics
  await logWidgetUsage({
    domain: req.get('origin'),
    agent_id: req.body.agent_id,
    timestamp: new Date(),
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  
  // Continue with call creation...
});
```

## 🔄 **Updates & Versioning**

### CDN Versioning Strategy:
```
cdn.your-domain.com/
├── v1/
│   ├── retell-widget.js     ← Current stable
│   └── retell-widget.css
├── v2/
│   ├── retell-widget.js     ← New version
│   └── retell-widget.css
└── latest/                  ← Always points to current stable
    ├── retell-widget.js
    └── retell-widget.css
```

### Update Notification:
```javascript
// Notify clients of new versions
app.get('/api/widget-version', (req, res) => {
  res.json({
    current: 'v1.0.0',
    latest: 'v1.2.0',
    updateAvailable: true,
    changelog: 'https://docs.your-domain.com/changelog'
  });
});
```

## 🚀 **Scaling Considerations**

1. **CDN Distribution**: Use global CDN for fast widget loading
2. **Multiple Backend Regions**: Deploy API servers in multiple regions
3. **Load Balancing**: Use load balancers for high traffic
4. **Caching**: Implement intelligent caching for API responses
5. **Monitoring**: Set up monitoring for uptime and performance

This architecture allows unlimited 3rd party sites to embed your widget while maintaining security and performance! 🎉