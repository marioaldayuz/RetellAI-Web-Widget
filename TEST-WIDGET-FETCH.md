# 🔍 Testing "Failed to Fetch" Error

## Quick Test Commands

Run these on your server to identify the issue:

### 1. Is the backend running?
```bash
sudo lsof -i :3001
# Should show node process listening
```

### 2. Can you reach it locally?
```bash
curl http://localhost:3001/health
# Should return: {"status":"healthy"}
```

### 3. Can you reach the API?
```bash
curl -X POST http://localhost:3001/api/create-web-call \
  -H "Content-Type: application/json" \
  -d '{"agentId":"test"}'
# Should return error about API key or agent
```

### 4. Can you reach it externally?
```bash
curl https://YOUR-DOMAIN/health
curl https://YOUR-DOMAIN/api/create-web-call -X POST \
  -H "Content-Type: application/json" \
  -d '{"agentId":"test"}'
```

## Common Issues & Fixes

### ❌ Backend not running
```bash
# Quick start
cd server && node server.js

# Or with systemd
sudo systemctl start retell-widget-backend
```

### ❌ Port 3001 blocked
```bash
# Open firewall
sudo ufw allow 3001

# Check if listening
netstat -tln | grep 3001
```

### ❌ Nginx not proxying
Add to your Nginx config:
```nginx
location /api/ {
    proxy_pass http://localhost:3001/api/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
}

location /health {
    proxy_pass http://localhost:3001/health;
}
```

Then reload:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### ❌ CORS blocking
Check `server/.env`:
```bash
UNIVERSAL_ACCESS=true
ALLOWED_ORIGINS=*
```

### ❌ Wrong API endpoint in widget
Your widget code should use:
```javascript
proxyEndpoint: 'https://YOUR-ACTUAL-DOMAIN/api/create-web-call'
```

## Browser Debugging

1. **Open Console (F12)**
   - Look for the exact error message
   - Check if it says CORS, network, or connection error

2. **Check Network Tab**
   - Find the failed `create-web-call` request
   - Check the URL it's trying to reach
   - Look at response headers

3. **Test with curl from your computer**
```bash
curl -v https://YOUR-DOMAIN/api/create-web-call \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Origin: https://example.com" \
  -d '{"agentId":"test"}'
```

## Emergency Fix

Run this to get it working immediately:
```bash
chmod +x fix-backend-now.sh
./fix-backend-now.sh
```

This will:
- Kill existing servers
- Create proper .env
- Start a failsafe server
- Test everything

## Still Not Working?

Run the diagnostic script and share output:
```bash
chmod +x diagnose-fetch-error.sh
./diagnose-fetch-error.sh YOUR-DOMAIN
```

The issue is usually one of:
1. **Backend not running** - Start it
2. **Nginx not configured** - Add proxy_pass
3. **Wrong URL in widget** - Fix proxyEndpoint
4. **API key missing** - Add to .env