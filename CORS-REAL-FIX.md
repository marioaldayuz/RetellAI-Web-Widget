# The REAL CORS Issue and Fix

## The Problem You're Experiencing

Your server is NOT sending `Access-Control-Allow-Origin: *`. Instead, it's sending `Access-Control-Allow-Origin: [specific-origin]` which can cause issues.

## Why This Happens

The `cors` npm package has quirky behavior:

1. **`cors({ origin: '*' })`** - Does NOT always send a literal `*` header
   - Often reflects the requesting origin back instead
   - This is NOT the same as sending `*`

2. **`cors({ origin: true })`** - Always reflects the origin back
   - Sends `Access-Control-Allow-Origin: https://app.olliebot.ai` when that's the origin

3. **`cors()`** with no options - Actually sends `*` correctly

## The REAL Solutions

### Solution 1: Manual Headers (MOST RELIABLE)

Replace your current server.js with `server-truly-open-cors.js`:

```javascript
// Don't use the cors package at all
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);
  }
  next();
});
```

This GUARANTEES that `Access-Control-Allow-Origin: *` is sent.

### Solution 2: Use cors() with NO options

```javascript
const cors = require('cors');
app.use(cors()); // No options = sends * correctly
```

### Solution 3: Return '*' in the callback

```javascript
app.use(cors({
  origin: (origin, callback) => callback(null, '*'),
  credentials: false
}));
```

## Deploy the Fix NOW

On your production server:

```bash
cd /root/RetellAI-Web-Widget/server

# Use the manual headers version (most reliable)
cp ../server-truly-open-cors.js server.js

# OR if that file doesn't exist, create it:
cat > server.js << 'EOF'
const express = require('express');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// MANUAL CORS - Guaranteed to send *
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', '*');
  
  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);
  }
  next();
});

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', cors: 'manual-asterisk' });
});

app.post('/api/create-web-call', async (req, res) => {
  try {
    const fetch = require('node-fetch');
    
    if (!process.env.RETELL_API_KEY) {
      return res.status(500).json({ error: 'Missing API key' });
    }
    
    const agentId = req.body.agent_id || process.env.RETELL_AGENT_ID;
    if (!agentId) {
      return res.status(400).json({ error: 'agent_id required' });
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
    
    const data = await response.json();
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on ${PORT} with MANUAL CORS headers (guaranteed *)`);
});
EOF

# Restart the service
sudo systemctl restart retell-widget-backend
```

## Test the Fix

```bash
# This should return: Access-Control-Allow-Origin: *
curl -I -X OPTIONS https://retelldemo.olliebot.ai/api/create-web-call \
  -H "Origin: https://test.com"
```

## Why Your Current Setup Fails

Your current `cors({ origin: '*' })` is likely:
1. Reflecting the origin back instead of sending `*`
2. Being affected by the `credentials` setting
3. Having version-specific quirks in the cors package

## The Bottom Line

**Don't trust the cors package with `origin: '*'`**. Either:
- Set headers manually (most reliable)
- Use `cors()` with no options
- Debug what's actually being sent, not what you think is being sent
