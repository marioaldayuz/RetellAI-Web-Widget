# CORS Duplicate Headers Fix

## Problem
The error you encountered:
```
Access to fetch at 'https://retelldemo.olliebot.ai/api/create-web-call' from origin 'https://app.olliebot.ai' 
has been blocked by CORS policy: The 'Access-Control-Allow-Origin' header contains multiple values 
'https://app.olliebot.ai, https://app.olliebot.ai', but only one is allowed.
```

## Root Cause
Both **nginx** and **Express.js** were adding CORS headers, resulting in duplicate `Access-Control-Allow-Origin` headers being sent to the client.

### What was happening:
1. **Nginx** proxy adds: `Access-Control-Allow-Origin: https://app.olliebot.ai`
2. **Express** cors middleware adds: `Access-Control-Allow-Origin: https://app.olliebot.ai`
3. Browser receives: `Access-Control-Allow-Origin: https://app.olliebot.ai, https://app.olliebot.ai`
4. Browser rejects the response due to duplicate values

## Solution
Handle CORS in **only ONE place** - preferably in the Express application, not in nginx.

### Files Updated/Created:
1. **`server/server.js`** - Updated Express server that properly handles CORS with olliebot.ai priority
2. **`nginx-no-cors.conf`** - Nginx configuration without CORS headers
3. **`fix-cors-production.sh`** - Deployment script to apply the fix

## Quick Fix Instructions

### Option 1: Run the Fix Script (Recommended)
```bash
# SSH into your production server
ssh your-server

# Navigate to project directory
cd /path/to/retellai-widget

# Run the fix script
chmod +x fix-cors-production.sh
./fix-cors-production.sh
```

### Option 2: Manual Fix

1. **The Express server** (`server/server.js`) has already been updated to handle CORS properly with olliebot.ai domains as priority

2. **Remove CORS headers from nginx**:
Edit `/etc/nginx/sites-available/retelldemo.olliebot.ai` and remove any lines containing:
- `add_header Access-Control-Allow-Origin`
- `add_header Access-Control-Allow-Methods`
- `add_header Access-Control-Allow-Headers`

3. **Restart services**:
```bash
sudo systemctl restart retell-widget-backend
sudo systemctl reload nginx
```

## Testing the Fix

Test if CORS is working correctly:
```bash
curl -I -X OPTIONS https://retelldemo.olliebot.ai/api/create-web-call \
  -H "Origin: https://app.olliebot.ai" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type"
```

You should see **only ONE** `Access-Control-Allow-Origin` header in the response.

## Best Practices

1. **Handle CORS in one place only** - Either nginx OR Express, never both
2. **Prefer application-level CORS** - Express cors middleware gives more flexibility
3. **Log CORS requests** - Helps debug origin issues
4. **Be specific with origins** - Avoid using `*` in production

## Environment Configuration

Ensure your `.env` file includes:
```env
# Specific origins
ALLOWED_ORIGINS=https://app.olliebot.ai,https://olliebot.ai

# OR for universal access (less secure)
UNIVERSAL_ACCESS=true

# OR wildcard (least secure)
ALLOWED_ORIGINS=*
```

## Troubleshooting

If the issue persists after applying the fix:

1. **Clear browser cache** - Old CORS headers might be cached
2. **Check server logs**:
   ```bash
   sudo journalctl -u retell-widget-backend -f
   sudo tail -f /var/log/nginx/error.log
   ```
3. **Verify nginx config**:
   ```bash
   sudo nginx -t
   cat /etc/nginx/sites-enabled/retelldemo.olliebot.ai | grep -i "access-control"
   ```
4. **Check if multiple processes are running**:
   ```bash
   sudo lsof -i :3001
   ps aux | grep node
   ```

## Prevention

To prevent this issue in the future:
1. Document where CORS is handled in your infrastructure
2. Use configuration management tools
3. Test CORS headers after any nginx or server updates
4. Monitor for duplicate headers in production 