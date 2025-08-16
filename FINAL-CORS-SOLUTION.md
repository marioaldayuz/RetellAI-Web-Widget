# FINAL CORS Solution - Duplicate Headers Fix

## The Current Problem

You're getting this error:
```
The 'Access-Control-Allow-Origin' header contains multiple values '*, https://app.olliebot.ai', but only one is allowed.
```

This means **BOTH** nginx and Express are adding CORS headers:
- Express adds: `Access-Control-Allow-Origin: *`
- Nginx adds: `Access-Control-Allow-Origin: https://app.olliebot.ai`

## The Solution

**Only Express should handle CORS. Nginx should NOT add any CORS headers.**

## Files Ready for Deployment

### 1. `server/server.js` (updated)
- Sets ONLY `Access-Control-Allow-Origin: *`
- No mentions of app.olliebot.ai
- No duplicate headers

### 2. `fix-duplicate-cors.sh`
- Removes ALL CORS headers from nginx
- Updates Express server
- Restarts services

## Deploy the Fix NOW

SSH into your production server and run:

```bash
cd /root/RetellAI-Web-Widget
chmod +x fix-duplicate-cors.sh
./fix-duplicate-cors.sh
```

OR manually:

### Step 1: Clean nginx configuration
```bash
# Remove ALL add_header directives for Access-Control from nginx
sudo nano /etc/nginx/sites-available/retelldemo.olliebot.ai

# Remove these lines if present:
# add_header Access-Control-Allow-Origin ...
# add_header Access-Control-Allow-Methods ...
# add_header Access-Control-Allow-Headers ...

# The location blocks should just proxy, no headers:
location /api/ {
    proxy_pass http://localhost:3001/api/;
    # NO add_header lines here!
}

# Save and reload
sudo nginx -t && sudo systemctl reload nginx
```

### Step 2: Update Express server
```bash
cd /root/RetellAI-Web-Widget/server

# Get the latest server.js from repo
git pull

# OR create it manually:
cat > server.js << 'EOF'
const express = require('express');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// SINGLE CORS header - just *
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');
  
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
  next();
});

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/api/create-web-call', async (req, res) => {
  const fetch = require('node-fetch');
  // ... rest of your API logic
});

app.listen(PORT, () => {
  console.log(`Server on ${PORT} - CORS: * only`);
});
EOF

# Restart
sudo systemctl restart retell-widget-backend
```

## Verify the Fix

Test that only ONE header is sent:
```bash
curl -I https://retelldemo.olliebot.ai/health | grep -i access-control
```

Should show:
```
Access-Control-Allow-Origin: *
```

NOT:
```
Access-Control-Allow-Origin: *, https://app.olliebot.ai
```

## Why This Happened

1. Your nginx configuration had `add_header` directives adding CORS headers
2. Your Express server was also adding CORS headers
3. Both headers were being sent, causing the "multiple values" error

## The Key Points

1. **Express is the ONLY source of CORS headers**
2. **Nginx should NOT add any Access-Control headers**
3. **The header value is just `*` with no domain mentions**

## Test from Browser

```javascript
// This should work from ANY website now:
fetch('https://retelldemo.olliebot.ai/health')
  .then(r => r.json())
  .then(data => console.log('Success:', data))
  .catch(err => console.error('Error:', err))
```

## If Still Having Issues

Check these:
1. `sudo grep -r "add_header.*Access-Control" /etc/nginx/`
2. `sudo journalctl -u retell-widget-backend -n 50`
3. Clear browser cache and try again
4. Make sure CloudFlare/CDN isn't adding headers

The fix is simple: **Only Express handles CORS, nginx just proxies.**
