# Open CORS Solution - Allow Widget from ANY Origin

## What We've Done

Since you don't care about origin restrictions and want the widget to work from anywhere, we've simplified the CORS configuration to be completely open.

### Current Configuration

**`server/server.js`** now uses:
```javascript
app.use(cors({
  origin: '*',  // Allow ALL origins
  credentials: false,  // No cookies (simpler)
  methods: '*',  // Allow all methods
  allowedHeaders: '*',  // Allow all headers
}));
```

This means:
- ✅ Widget works from **ANY** website
- ✅ No origin restrictions at all
- ✅ No more CORS errors
- ✅ Simple and straightforward

## Deploy to Production

### Quick Deploy (Recommended)

1. **SSH into your production server**:
```bash
ssh your-server
cd /path/to/retellai-widget
```

2. **Run the deployment script**:
```bash
chmod +x deploy-open-cors.sh
./deploy-open-cors.sh
```

### Manual Deploy

1. **Update server.js on production**:
```bash
# Copy the new server.js from this repo
# OR use the server-simple-cors.js file
cp server/server-simple-cors.js server/server.js
```

2. **Ensure nginx doesn't add CORS headers**:

Check `/etc/nginx/sites-available/retelldemo.olliebot.ai` and **remove** any lines like:
- `add_header Access-Control-Allow-Origin`
- `add_header Access-Control-Allow-Methods`
- `add_header Access-Control-Allow-Headers`

The nginx config should just proxy to the backend WITHOUT adding headers:
```nginx
location /api/ {
    proxy_pass http://localhost:3001/api/;
    # NO add_header directives for CORS
}
```

3. **Restart services**:
```bash
sudo systemctl restart retell-widget-backend
# OR
pm2 restart all
# OR manually restart your Node.js process

sudo nginx -t && sudo systemctl reload nginx
```

## Testing

After deployment, test with:
```bash
curl -I -X OPTIONS https://retelldemo.olliebot.ai/api/create-web-call \
  -H "Origin: https://any-random-website.com"
```

You should see:
```
Access-Control-Allow-Origin: *
```

NOT:
```
Access-Control-Allow-Origin: https://app.olliebot.ai
```

## Why This Works

1. **Single source of CORS headers** - Only Express.js sets them
2. **Wildcard origin (`*`)** - Accepts requests from ANY origin
3. **No credentials** - Simpler, no cookie complications
4. **No nginx interference** - Nginx just proxies, doesn't add headers

## Files Created

- `server/server-simple-cors.js` - The simplified server (now copied to server.js)
- `deploy-open-cors.sh` - Automated deployment script
- `test-cors-headers.sh` - Diagnostic tool
- `nginx-no-cors.conf` - Reference nginx configuration

## Security Note

⚠️ This configuration allows your widget to be embedded on **ANY** website. This is perfect for public widgets but may not be suitable if you need to restrict access to specific domains.

If you later need to restrict origins, you can update the CORS configuration to specify allowed domains instead of using `*`. 