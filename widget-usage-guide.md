# RetellAI Widget Usage Guide

## 🚨 "RetellWidget is not defined" - SOLUTION

If you're getting `RetellWidget is not defined`, follow these steps:

### ✅ **Step 1: Build the Widget**

```bash
# In the RetellAI-Web-Widget directory
npm install
npm run build
```

This creates:
- `dist/retell-widget.js` (414KB)
- `dist/retell-widget.css` (15KB)

### ✅ **Step 2: Include the Built Files**

```html
<!DOCTYPE html>
<html>
<head>
    <!-- Include the CSS -->
    <link rel="stylesheet" href="./dist/retell-widget.css">
</head>
<body>
    <!-- Your content -->
    
    <!-- Include the JS -->
    <script src="./dist/retell-widget.js"></script>
    
    <!-- Now RetellWidget is available -->
    <script>
        const widget = new RetellWidget({
            agentId: 'your_agent_id',
            proxyEndpoint: 'https://yourdomain.com/api/create-web-call',
            position: 'bottom-right',
            theme: 'purple'
        });
    </script>
</body>
</html>
```

### ✅ **Step 3: Backend Setup**

Your backend must implement the proxy endpoint:

```javascript
// Example Node.js/Express endpoint
app.post('/api/create-web-call', async (req, res) => {
  try {
    const { agent_id } = req.body;
    
    // Call Retell AI API to create web call
    const response = await fetch('https://api.retellai.com/create-web-call', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.RETELL_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ agent_id })
    });
    
    const data = await response.json();
    res.json({ access_token: data.access_token });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

## 🎯 **Integration Methods**

### Method 1: Manual Initialization

```html
<!-- Include files -->
<link rel="stylesheet" href="./dist/retell-widget.css">
<script src="./dist/retell-widget.js"></script>

<script>
  // Create widget when ready
  document.addEventListener('DOMContentLoaded', function() {
    const widget = new RetellWidget({
      agentId: 'your_agent_id',
      proxyEndpoint: 'https://yourdomain.com/api/create-web-call',
      position: 'bottom-right',
      theme: 'purple'
    });
  });
</script>
```

### Method 2: Auto-initialization

```html
<!-- Set config first -->
<script>
  window.retellWidgetConfig = {
    agentId: 'your_agent_id',
    proxyEndpoint: 'https://yourdomain.com/api/create-web-call',
    position: 'bottom-right',
    theme: 'purple'
  };
</script>

<!-- Widget auto-initializes when loaded -->
<link rel="stylesheet" href="./dist/retell-widget.css">
<script src="./dist/retell-widget.js"></script>
```

## 🎛️ **Configuration Options**

```javascript
const widget = new RetellWidget({
  // Required
  agentId: 'your_agent_id',
  
  // Optional
  proxyEndpoint: 'https://yourdomain.com/api/create-web-call', // Default: localhost:3001
  position: 'bottom-right',  // bottom-right, bottom-left, top-right, top-left
  theme: 'purple'            // purple, blue, green
});
```

## 🎮 **Widget Methods**

```javascript
// Show hidden widget
widget.show();

// Hide widget
widget.minimize();

// Completely remove widget
widget.destroy();
```

## 📁 **File Structure for Deployment**

```
your-website/
├── index.html
├── dist/
│   ├── retell-widget.js     ← Built widget (from npm run build)
│   └── retell-widget.css    ← Built styles (from npm run build)
└── api/
    └── create-web-call      ← Your backend endpoint
```

## 🔧 **Troubleshooting**

### "RetellWidget is not defined"
- ✅ Make sure you built the widget: `npm run build`
- ✅ Include `retell-widget.js` before using `new RetellWidget()`
- ✅ Check browser console for script loading errors

### "Failed to start call"
- ✅ Verify your backend endpoint is running
- ✅ Check CORS settings allow your domain
- ✅ Ensure your backend returns `{ access_token: "..." }`

### Widget not appearing
- ✅ Include `retell-widget.css`
- ✅ Check for CSS conflicts with your site styles
- ✅ Verify the widget isn't hidden behind other elements

## 🌐 **Production Deployment**

For production, host the built files on your server:

```html
<!-- Production URLs -->
<link rel="stylesheet" href="https://yourdomain.com/assets/retell-widget.css">
<script src="https://yourdomain.com/assets/retell-widget.js"></script>

<script>
  new RetellWidget({
    agentId: 'your_production_agent_id',
    proxyEndpoint: 'https://yourdomain.com/api/create-web-call',
    position: 'bottom-right',
    theme: 'purple'
  });
</script>
```

The widget files are completely self-contained and can be served from any CDN or static hosting service.