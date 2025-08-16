# 🔧 Troubleshooting Guide

## ❌ Error: "Failed to start call: Failed to fetch"

This error means the widget loaded but can't reach your backend server.

### Quick Diagnosis

Run the debug script:
```bash
chmod +x debug-server.sh
./debug-server.sh
```

### Manual Checks

#### 1️⃣ Is the server running?

```bash
# Check if running
curl http://localhost:3001/health

# If not, start it:
cd server && npm start

# Or with systemd:
sudo systemctl start retell-widget-backend
```

#### 2️⃣ Check server logs

```bash
# If using systemd:
sudo journalctl -u retell-widget-backend -n 50

# If running manually:
# Check the terminal where you ran npm start
```

#### 3️⃣ Test the API directly

```bash
# Run from server directory:
cd server
node test-api.js
```

### Common Causes & Fixes

#### 🔴 Server Not Running
```bash
# Start server
cd server
npm start

# You should see:
# Server running on port 3001
```

#### 🔴 Wrong API Endpoint

Check your widget code:
```javascript
// ❌ WRONG - Missing domain
proxyEndpoint: '/api/create-web-call'

// ✅ CORRECT - Full URL for external sites
proxyEndpoint: 'https://your-backend.com/api/create-web-call'
```

#### 🔴 CORS Not Configured

Check `server/.env`:
```bash
# Must have one of these:
UNIVERSAL_ACCESS=true
# OR
ALLOWED_ORIGINS=*
# OR
ALLOWED_ORIGINS=https://your-website.com
```

#### 🔴 Missing API Key

Check `server/.env`:
```bash
RETELL_API_KEY=retell_sk_your_actual_key_here
```

#### 🔴 Firewall Blocking

```bash
# Check if port 3001 is open
sudo ufw status

# Open port if needed
sudo ufw allow 3001
```

## ❌ Error: "RetellWidget is not defined"

Widget JavaScript not loaded properly.

### Fix:
```html
<!-- Load script FIRST -->
<script src="https://your-domain.com/widget/retell-widget.js"></script>

<!-- THEN use RetellWidget -->
<script>
  new RetellWidget({ ... });
</script>
```

## ❌ Error: "Invalid agent ID"

### Fix:
Replace `'your_agent_id_here'` with your actual Retell agent ID from your Retell dashboard.

## ❌ Error: "Unauthorized" or "Invalid API key"

### Fix:
1. Get your API key from [Retell Dashboard](https://www.retellai.com/dashboard)
2. Add to `server/.env`:
   ```bash
   RETELL_API_KEY=retell_sk_your_key_here
   ```
3. Restart server:
   ```bash
   sudo systemctl restart retell-widget-backend
   ```

## ❌ Widget Not Appearing

### Check:
1. **CSS loaded?** Check Network tab for `retell-widget.css`
2. **JS loaded?** Check Network tab for `retell-widget.js`
3. **Console errors?** Press F12 and check Console tab
4. **Z-index issue?** Widget might be behind other elements

## 🧪 Testing Tools

### 1. Debug Script
```bash
./debug-server.sh
```
Checks everything automatically.

### 2. API Test
```bash
cd server
node test-api.js
```
Tests the backend directly.

### 3. Manual CORS Test
```bash
curl -X OPTIONS http://localhost:3001/api/create-web-call \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: POST" \
  -v
```

### 4. Browser Console Test
```javascript
// Paste in browser console
fetch('https://your-backend.com/api/create-web-call', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({agentId: 'test'})
}).then(r => r.json()).then(console.log).catch(console.error);
```

## 🆘 Still Need Help?

1. Run `./debug-server.sh` and share the output
2. Check browser Console (F12) for errors
3. Check Network tab for failed requests
4. Share your widget integration code

## 📝 Checklist

Before widget will work, ensure:

- [ ] Server is running (`curl http://localhost:3001/health`)
- [ ] API key in `server/.env`
- [ ] CORS configured (`UNIVERSAL_ACCESS=true`)
- [ ] Widget files built (`npm run build`)
- [ ] Correct `proxyEndpoint` URL in widget code
- [ ] Valid `agentId` from Retell dashboard
- [ ] Script loaded before using `RetellWidget`