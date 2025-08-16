# 🔧 Fix for "Failed to fetch" Error

## Quick Solution

Run this on your Linux server:

```bash
chmod +x quick-server-fix.sh
./quick-server-fix.sh
```

## Manual Fix Steps

### 1. Update your server/.env file:

```bash
RETELL_API_KEY=retell_sk_your_actual_key_here
UNIVERSAL_ACCESS=true
ALLOWED_ORIGINS=*
NODE_ENV=production
PORT=3001
```

### 2. Replace server/server.js with server-fixed.js:

```bash
cp server/server-fixed.js server/server.js
```

### 3. Restart the server:

```bash
# If using systemd:
sudo systemctl restart retell-widget-backend

# Or manually:
cd server
npm install
node server.js
```

### 4. Test the server:

```bash
# Health check
curl http://localhost:3001/health

# API test
curl -X POST http://localhost:3001/api/create-web-call \
  -H 'Content-Type: application/json' \
  -d '{"agentId": "test"}'
```

## Widget Code (Use on ANY website):

```html
<link rel="stylesheet" href="https://YOUR-DOMAIN/retell-widget.css">
<script src="https://YOUR-DOMAIN/retell-widget.js"></script>
<script>
  const widget = new RetellWidget({
    agentId: 'your_agent_id_here',  // From Retell Dashboard
    proxyEndpoint: 'https://YOUR-DOMAIN/api/create-web-call',
    position: 'bottom-right',  // or 'bottom-left', 'top-right', 'top-left'
    theme: 'purple'  // or 'blue', 'green'
  });
</script>
```

## Key Changes in Fixed Version:

1. **Accepts both `agent_id` and `agentId`** - Compatible with widget
2. **More permissive CORS** - Allows requests during setup
3. **Better error messages** - Helpful hints for debugging
4. **Detailed logging** - Shows what's happening
5. **Binds to 0.0.0.0** - Accepts external connections

## Common Issues:

### ❌ Still getting "Failed to fetch"
- Check firewall: `sudo ufw allow 3001`
- Check server is running: `sudo systemctl status retell-widget-backend`
- Check logs: `sudo journalctl -u retell-widget-backend -f`

### ❌ "Invalid API key"
- Get key from: https://www.retellai.com/dashboard
- Must start with `retell_sk_`

### ❌ "Invalid agent ID"
- Get agent ID from Retell dashboard
- Make sure agent is active

## Test Commands:

```bash
# From your Linux server:
./debug-server.sh

# Quick test:
curl http://localhost:3001/health

# Full test:
cd server && node test-api.js
```