# 3rd Party Widget Deployment Checklist

## 🚀 **Pre-Deployment Setup**

### ✅ **Backend Server Configuration**

1. **Environment Variables**
   ```bash
   # Required
   RETELL_API_KEY=your_retell_api_key_here
   
   # Required for production
   ALLOWED_ORIGINS=https://client1.com,https://client2.com,*.clients.example.com
   
   # Optional
   PORT=3001
   NODE_ENV=production
   ```

2. **CORS Configuration**
   - ✅ Add all client domains to `ALLOWED_ORIGINS`
   - ✅ Support wildcard subdomains with `*.domain.com`
   - ✅ Test CORS with browser dev tools

3. **Security Setup**
   - ✅ Rate limiting configured (20 requests/15min per IP)
   - ✅ Helmet.js security headers enabled
   - ✅ API key validation in place

### ✅ **Widget Build & Distribution**

1. **Build the Widget**
   ```bash
   npm install
   npm run build
   ```

2. **Upload to CDN/Hosting**
   ```bash
   # Upload dist files to your CDN
   dist/retell-widget.js    (424KB)
   dist/retell-widget.css   (15KB)
   ```

3. **Version Management**
   ```
   your-cdn.com/
   ├── v1/
   │   ├── retell-widget.js
   │   └── retell-widget.css
   ├── v2/
   │   ├── retell-widget.js
   │   └── retell-widget.css
   └── latest/  ← Symlink to current stable
       ├── retell-widget.js
       └── retell-widget.css
   ```

## 📋 **Client Integration Guide**

### For Each Client Website:

1. **Provide Integration Code**
   ```html
   <!-- Include widget files -->
   <link rel="stylesheet" href="https://your-cdn.com/latest/retell-widget.css">
   <script src="https://your-cdn.com/latest/retell-widget.js"></script>
   
   <!-- Initialize widget -->
   <script>
     new RetellWidget({
       agentId: 'client_specific_agent_id',
       proxyEndpoint: 'https://your-backend.com/api/create-web-call',
       position: 'bottom-right',
       theme: 'purple'
     });
   </script>
   ```

2. **Client-Specific Configuration**
   - ✅ Unique `agentId` for each client
   - ✅ Custom positioning/theme per client needs
   - ✅ Add client domain to `ALLOWED_ORIGINS`

3. **Test Integration**
   - ✅ Widget loads without console errors
   - ✅ Widget appears in correct position
   - ✅ Can initiate calls successfully
   - ✅ No CORS errors in network tab

## 🔍 **Testing Checklist**

### ✅ **Local Testing**
```bash
# 1. Start backend server
cd server
npm start

# 2. Test CORS with curl
curl -H "Origin: https://client-website.com" \
     -H "Content-Type: application/json" \
     -d '{"agent_id":"test_agent"}' \
     https://your-backend.com/api/create-web-call

# 3. Open example.html in browser
# 4. Check browser console for errors
```

### ✅ **Production Testing**

1. **Health Check**
   ```bash
   curl https://your-backend.com/health
   # Should return: {"status":"ok","timestamp":"..."}
   ```

2. **CORS Test**
   ```javascript
   // In browser console on client website:
   fetch('https://your-backend.com/api/create-web-call', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' },
     body: JSON.stringify({ agent_id: 'test_agent' })
   }).then(r => r.json()).then(console.log);
   ```

3. **Widget Functionality**
   - ✅ Widget loads and displays
   - ✅ Can start/end calls
   - ✅ Mute/unmute works
   - ✅ Timer displays correctly
   - ✅ Error handling works

## 🚨 **Troubleshooting Common Issues**

### "Failed to start call" / CORS Errors
1. Check `ALLOWED_ORIGINS` includes client domain
2. Verify client uses `https://` (not `http://`)
3. Check browser network tab for exact error
4. Test with wildcard: `*.client-domain.com`

### "RetellWidget is not defined"
1. Ensure widget JS file loads before initialization
2. Check CDN/hosting serves files with correct MIME types
3. Verify no ad blockers blocking widget files

### Widget doesn't appear
1. Check for CSS conflicts with client site
2. Verify `z-index` isn't overridden
3. Check widget isn't hidden behind other elements

### Call quality issues
1. Verify client has good internet connection
2. Check for browser microphone permissions
3. Test on different browsers/devices

## 📊 **Monitoring & Maintenance**

### ✅ **Server Monitoring**
- Monitor `/health` endpoint uptime
- Track API response times
- Monitor rate limit hits
- Log CORS rejections

### ✅ **Usage Analytics**
```javascript
// Add to server logging
app.post('/api/create-web-call', async (req, res) => {
  // Log usage
  console.log(`Widget usage: ${req.get('origin')} - Agent: ${req.body.agent_id}`);
  
  // Continue with call creation...
});
```

### ✅ **Client Support**
- Provide clear integration documentation
- Set up monitoring for widget errors
- Create troubleshooting guides for clients
- Offer integration support/testing

## 🔄 **Update Process**

### Widget Updates:
1. Build new version: `npm run build`
2. Upload to new version folder: `/v2/`
3. Test with staging clients
4. Update `/latest/` symlink
5. Notify clients of updates

### Backend Updates:
1. Test in staging environment
2. Update CORS if needed
3. Deploy during low traffic
4. Monitor for issues
5. Rollback plan ready

This checklist ensures smooth deployment and ongoing maintenance of your cross-domain widget! 🎉