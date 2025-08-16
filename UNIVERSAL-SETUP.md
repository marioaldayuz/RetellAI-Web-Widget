# 🌍 ONE-COMMAND UNIVERSAL SETUP

## Make Your Widget Embeddable on ANY Website

### Step 1: Enable Universal Access
```bash
cd server
echo "RETELL_API_KEY=your_retell_api_key_here" > .env
echo "UNIVERSAL_ACCESS=true" >> .env
echo "NODE_ENV=production" >> .env
npm start
```

### Step 2: Build & Host Widget
```bash
npm run build
# Upload dist/retell-widget.js and dist/retell-widget.css to your CDN
```

### Step 3: Share Integration Code
Give this code to ANYONE who wants to embed your widget:

```html
<!-- Works on ANY website -->
<link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
<script src="https://your-cdn.com/retell-widget.js"></script>
<script>
  new RetellWidget({
    agentId: 'your_agent_id',
    proxyEndpoint: 'https://your-backend.com/api/create-web-call'
  });
</script>
```

**That's it!** Your widget can now be embedded on ANY website in the world! 🌍

---

## Alternative: Wildcard Method
```bash
# Alternative approach using wildcard
echo "RETELL_API_KEY=your_retell_api_key_here" > .env
echo "ALLOWED_ORIGINS=*" >> .env
echo "NODE_ENV=production" >> .env
```

## Console Output (Universal Access)
When you start your server, you'll see:
```
🚀 Proxy server running on http://localhost:3001
✅ API key configured
🌐 UNIVERSAL ACCESS MODE: Widget can be embedded on ANY website
⚠️  WARNING: This allows ALL domains. Only use if you want a public widget.
```

## Console Output (Per Request)
For each widget request from any website:
```
✅ Universal access: Allowing request from: https://any-website.com
```

Your widget is now a **public service** that anyone can embed! 🎉