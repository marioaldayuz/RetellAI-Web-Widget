# ✅ WORKING Widget Integration Code

This is the EXACT code that works for embedding the RetellAI widget on ANY website:

## Complete Working Example

```html
<!-- RetellAI Widget CSS -->
<link rel="stylesheet" href="https://YOUR-DOMAIN/retell-widget.css">

<!-- RetellAI Widget JavaScript -->
<script src="https://YOUR-DOMAIN/retell-widget.js"></script>

<!-- Initialize the widget -->
<script>
  const widget = new RetellWidget({
    agentId: 'your_agent_id_here',  // Replace with your actual agent ID from Retell Dashboard
    proxyEndpoint: 'https://YOUR-DOMAIN/api/create-web-call',  // MUST be full URL for 3rd party sites
    position: 'bottom-right',  // or 'bottom-left', 'top-right', 'top-left'
    theme: 'purple'  // or 'blue', 'green'
  });
</script>
```

## Important Notes

1. **NO /widget/ path** - Files are served from root: `/retell-widget.js` not `/widget/retell-widget.js`
2. **Use const widget =** - Store the widget instance in a variable
3. **Full URL required** - For the `proxyEndpoint`, always use the complete URL including https://
4. **Load order matters** - CSS first, then JS, then initialize

## Real Working Example

Based on your working deployment at `retelldemo.olliebot.ai`:

```html
<link rel="stylesheet" href="https://retelldemo.olliebot.ai/retell-widget.css">
<script src="https://retelldemo.olliebot.ai/retell-widget.js"></script>

<script>
  const widget = new RetellWidget({
    agentId: 'agent_1dc973641c277176a5b941595d',
    proxyEndpoint: 'https://retelldemo.olliebot.ai/api/create-web-call',
    position: 'bottom-right',
    theme: 'purple'
  });
</script>
```

## Configuration Options

```javascript
const widget = new RetellWidget({
  // Required
  agentId: 'your_agent_id',           // From Retell Dashboard
  proxyEndpoint: 'https://...',       // Your backend API endpoint
  
  // Optional
  position: 'bottom-right',           // Widget position
  theme: 'purple',                    // Color theme
  
  // Advanced (if needed)
  retellConfig: {
    // Additional Retell SDK options
  }
});
```

## Testing Your Integration

1. **Check Console** - Open browser console (F12) and look for errors
2. **Check Network** - Verify the CSS and JS files load (200 status)
3. **Check Widget** - Should see a floating button in the specified position

## Troubleshooting

### Widget not appearing?
- Check browser console for errors
- Verify files are loading (Network tab)
- Ensure `agentId` is valid

### "Failed to fetch" error?
- Check `proxyEndpoint` URL is correct
- Verify backend server is running
- Check CORS configuration

### "RetellWidget is not defined"?
- Make sure script loads before initialization
- Check that JS file loaded successfully

## Nginx Configuration for Serving Files

If you need to manually configure Nginx to serve the files from root:

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    # Serve widget files from root
    location ~ ^/(retell-widget\.(js|css))$ {
        root /var/www/your-domain.com;
        add_header Access-Control-Allow-Origin "*";
        add_header Cache-Control "public, max-age=3600";
    }
    
    # API proxy
    location /api/ {
        proxy_pass http://localhost:3001/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Summary

✅ Files served from root domain (no /widget/ path)  
✅ Use `const widget = new RetellWidget(...)`  
✅ Always use full HTTPS URLs for 3rd party sites  
✅ Include position and theme options  

This configuration is tested and working in production!