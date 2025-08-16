# Universal Widget Deployment - Embed on ANY Website

## 🌐 **Universal Access Configuration**

To make your RetellAI widget embeddable on **ANY website** without pre-configuration, use one of these methods:

### Method 1: Universal Access Mode (Recommended)

```bash
# .env configuration
RETELL_API_KEY=your_retell_api_key
UNIVERSAL_ACCESS=true
NODE_ENV=production
```

### Method 2: Wildcard Origins

```bash
# .env configuration  
RETELL_API_KEY=your_retell_api_key
ALLOWED_ORIGINS=*
NODE_ENV=production
```

## 🚀 **Quick Setup for Universal Access**

### 1. Configure Backend Server

```bash
# On your server
cd server
cp env-example.txt .env

# Edit .env file:
echo "RETELL_API_KEY=your_retell_api_key_here" >> .env
echo "UNIVERSAL_ACCESS=true" >> .env
echo "NODE_ENV=production" >> .env

# Start server
npm start
```

### 2. Build & Host Widget Files

```bash
# Build widget
npm run build

# Upload to CDN or static hosting
# Files to upload:
# - dist/retell-widget.js (424KB)
# - dist/retell-widget.css (15KB)
```

### 3. Universal Integration Code

Provide this code to ANYONE who wants to embed your widget:

```html
<!DOCTYPE html>
<html>
<head>
    <!-- Include widget CSS -->
    <link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
</head>
<body>
    <!-- Website content -->
    <h1>Any Website Can Use This!</h1>
    
    <!-- Include widget JS -->
    <script src="https://your-cdn.com/retell-widget.js"></script>
    
    <!-- Initialize widget -->
    <script>
        new RetellWidget({
            agentId: 'your_public_agent_id',
            proxyEndpoint: 'https://your-backend.com/api/create-web-call',
            position: 'bottom-right',
            theme: 'purple'
        });
    </script>
</body>
</html>
```

## 📋 **Universal Deployment Options**

### Option A: Single Public Agent (Simplest)

```html
<!-- Same agent for everyone -->
<script>
    new RetellWidget({
        agentId: 'public_agent_12345',
        proxyEndpoint: 'https://your-backend.com/api/create-web-call',
        position: 'bottom-right',
        theme: 'blue'
    });
</script>
```

### Option B: Dynamic Agent Assignment

```html
<!-- Different agents based on website -->
<script>
    // Automatically assign agent based on domain
    const domain = window.location.hostname;
    let agentId = 'default_agent_12345'; // Default agent
    
    // Custom agents for specific domains (optional)
    const domainAgents = {
        'premium-client.com': 'premium_agent_67890',
        'enterprise-client.org': 'enterprise_agent_abcde'
    };
    
    if (domainAgents[domain]) {
        agentId = domainAgents[domain];
    }
    
    new RetellWidget({
        agentId: agentId,
        proxyEndpoint: 'https://your-backend.com/api/create-web-call',
        position: 'bottom-right',
        theme: 'purple'
    });
</script>
```

### Option C: Configurable Widget

```html
<!-- Allow websites to customize the widget -->
<script>
    window.retellWidgetConfig = {
        agentId: 'public_agent_12345',
        proxyEndpoint: 'https://your-backend.com/api/create-web-call',
        position: 'bottom-left',    // Website can customize
        theme: 'green',             // Website can customize
        // Custom branding options
        title: 'My Custom Assistant',
        welcomeMessage: 'How can I help you today?'
    };
</script>
<script src="https://your-cdn.com/retell-widget.js"></script>
```

## 🔒 **Security Considerations for Universal Access**

### ⚠️ **Important Warnings**

1. **Public API Access**: Your backend endpoint will accept requests from ANY domain
2. **Rate Limiting**: Essential to prevent abuse (already configured in server.js)
3. **Agent Security**: Use agents that don't expose sensitive information
4. **Monitoring**: Monitor usage for abuse or unexpected traffic

### ✅ **Security Best Practices**

```javascript
// Enhanced rate limiting for universal access
const rateLimit = require('express-rate-limit');

// Stricter limits for public endpoints
const publicLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 50, // Reduced from 100 for public access
  message: 'Too many requests from this IP',
  standardHeaders: true,
  legacyHeaders: false,
  // Block suspicious patterns
  skip: (req, res) => {
    // Allow your own domains without limits
    const trustedDomains = ['your-domain.com', 'your-cdn.com'];
    const origin = req.get('origin');
    return trustedDomains.some(domain => origin && origin.includes(domain));
  }
});

app.use('/api/', publicLimiter);
```

### 🛡️ **Additional Security Measures**

```javascript
// Add to server.js for enhanced security
app.post('/api/create-web-call', async (req, res) => {
  const origin = req.get('origin');
  const userAgent = req.get('user-agent');
  
  // Log all requests for monitoring
  console.log(`Widget request: ${origin} | UA: ${userAgent}`);
  
  // Block known malicious patterns (optional)
  const suspiciousPatterns = [
    /bot/i,
    /crawler/i,
    /scraper/i
  ];
  
  if (suspiciousPatterns.some(pattern => pattern.test(userAgent))) {
    console.warn(`🚫 Blocked suspicious request from: ${origin}`);
    return res.status(403).json({ error: 'Request blocked' });
  }
  
  // Continue with normal flow...
});
```

## 📊 **Monitoring Universal Usage**

### Track Widget Usage

```javascript
// Add analytics to your backend
const usageStats = new Map();

app.post('/api/create-web-call', async (req, res) => {
  const origin = req.get('origin');
  
  // Track usage by domain
  const currentCount = usageStats.get(origin) || 0;
  usageStats.set(origin, currentCount + 1);
  
  // Log top domains daily
  if (Date.now() % (24 * 60 * 60 * 1000) < 1000) { // Roughly once per day
    const topDomains = Array.from(usageStats.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10);
    console.log('📊 Top 10 domains using widget:', topDomains);
  }
  
  // Continue with call creation...
});
```

## 🌍 **CDN Distribution for Global Access**

### Recommended CDN Setup

```bash
# Directory structure for global CDN
your-cdn.com/
├── widget/
│   ├── v1/
│   │   ├── retell-widget.js
│   │   └── retell-widget.css
│   ├── v2/
│   │   ├── retell-widget.js
│   │   └── retell-widget.css
│   └── latest/               # Always points to stable version
│       ├── retell-widget.js
│       └── retell-widget.css
└── docs/
    ├── integration.html      # Integration examples
    └── api.html             # API documentation
```

### Global Integration URLs

```html
<!-- Use these URLs for global access -->
<link rel="stylesheet" href="https://your-cdn.com/widget/latest/retell-widget.css">
<script src="https://your-cdn.com/widget/latest/retell-widget.js"></script>
```

## 🎯 **Use Cases for Universal Access**

### 1. **Public AI Assistant Widget**
- Anyone can embed on their website
- Single agent serves all users
- Great for brand awareness

### 2. **SaaS Widget Platform**
- Different pricing tiers
- Analytics and usage tracking
- Premium features for paid users

### 3. **Open Source AI Widget**
- Community-driven development
- Public GitHub repository
- Free for everyone to use

### 4. **Marketing/Lead Generation**
- Widget collects leads for you
- Embedded on partner websites
- Shared revenue model

## 🚀 **Going Live with Universal Access**

### Final Checklist:

- ✅ Set `UNIVERSAL_ACCESS=true` or `ALLOWED_ORIGINS=*`
- ✅ Upload widget files to reliable CDN
- ✅ Configure rate limiting appropriately
- ✅ Set up monitoring and analytics
- ✅ Create public documentation/examples
- ✅ Test from multiple different websites
- ✅ Monitor for abuse or unexpected usage

### Share Integration Code:

```html
<!-- Copy-paste integration for ANY website -->
<link rel="stylesheet" href="https://your-cdn.com/widget/latest/retell-widget.css">
<script src="https://your-cdn.com/widget/latest/retell-widget.js"></script>
<script>
  new RetellWidget({
    agentId: 'public_agent_12345',
    proxyEndpoint: 'https://your-backend.com/api/create-web-call'
  });
</script>
```

**That's it!** Your widget can now be embedded on ANY website in the world! 🌍✨

The widget will automatically handle CORS, the backend will accept requests from any domain, and you can track usage across all embedding sites.