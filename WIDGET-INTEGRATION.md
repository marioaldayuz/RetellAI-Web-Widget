# 🎯 Widget Integration Guide

## ⚠️ Common Error: "RetellWidget is not defined"

This error occurs when the widget JavaScript file is not loaded properly. Here's how to fix it:

## ✅ Correct Integration Order

The widget files **MUST** be loaded in this exact order:

```html
<!DOCTYPE html>
<html>
<head>
    <!-- 1. Load the CSS file in the head -->
    <link rel="stylesheet" href="https://your-domain.com/widget/retell-widget.css">
</head>
<body>
    <!-- Your website content -->
    
    <!-- 2. Load the JavaScript file BEFORE using RetellWidget -->
    <script src="https://your-domain.com/widget/retell-widget.js"></script>
    
    <!-- 3. THEN create the widget -->
    <script>
        // Now RetellWidget is available
        new RetellWidget({
            agentId: 'your_agent_id_here',
            proxyEndpoint: 'https://your-backend.com/api/create-web-call'
        });
    </script>
</body>
</html>
```

## ❌ Common Mistakes

### Mistake 1: Using RetellWidget before loading the script
```html
<!-- WRONG: Trying to use RetellWidget before loading the script -->
<script>
    new RetellWidget({ ... });  // Error: RetellWidget is not defined
</script>
<script src="https://your-domain.com/widget/retell-widget.js"></script>
```

### Mistake 2: Wrong file paths
```html
<!-- WRONG: Missing or incorrect paths -->
<script src="retell-widget.js"></script>  <!-- Missing full path -->
<script src="/retell-widget.js"></script>  <!-- Missing /widget/ directory -->
```

## 🔧 Debugging Steps

1. **Check if the file is loading:**
   ```javascript
   // Open browser console and check:
   console.log(typeof RetellWidget);  // Should output "function"
   ```

2. **Check Network tab:**
   - Open browser Developer Tools → Network tab
   - Refresh the page
   - Look for `retell-widget.js` - it should load with status 200

3. **Check Console for errors:**
   - Look for 404 errors (file not found)
   - Look for CORS errors (cross-origin issues)

## 📦 After One-Touch Deployment

If you used the `one-touch-deploy.sh` script, your widget files are at:
- CSS: `https://your-domain.com/widget/retell-widget.css`
- JS: `https://your-domain.com/widget/retell-widget.js`

## 💡 Working Example

Save this as `test.html` and open in your browser:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RetellAI Widget Test</title>
    
    <!-- Replace with your actual domain -->
    <link rel="stylesheet" href="https://your-domain.com/widget/retell-widget.css">
</head>
<body>
    <h1>My Website</h1>
    <p>The voice call widget will appear in the corner.</p>
    
    <!-- Replace with your actual domain -->
    <script src="https://your-domain.com/widget/retell-widget.js"></script>
    
    <script>
        // Create widget after script loads
        new RetellWidget({
            agentId: 'your_agent_id_here',  // Replace with your agent ID
            proxyEndpoint: 'https://your-domain.com/api/create-web-call'
        });
    </script>
</body>
</html>
```

## 🚀 Using with Dynamic Loading

If you need to load the widget dynamically:

```javascript
function loadRetellWidget() {
    // Load CSS
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = 'https://your-domain.com/widget/retell-widget.css';
    document.head.appendChild(link);
    
    // Load JS
    const script = document.createElement('script');
    script.src = 'https://your-domain.com/widget/retell-widget.js';
    script.onload = function() {
        // Script loaded, now create widget
        new RetellWidget({
            agentId: 'your_agent_id_here',
            proxyEndpoint: 'https://your-domain.com/api/create-web-call'
        });
    };
    document.body.appendChild(script);
}

// Call when ready
loadRetellWidget();
```

## ✅ Verification

After integration, you should see:
1. A floating button in the corner of your page
2. No console errors
3. The ability to click the button and start a call

## 🆘 Still Having Issues?

1. **Ensure the widget is built:**
   ```bash
   npm run build
   ```

2. **Check file exists:**
   ```bash
   ls -la dist/retell-widget.js
   ```

3. **Test locally first:**
   Open `test-widget.html` in your browser

4. **Check server logs:**
   ```bash
   sudo journalctl -u retell-widget-backend -f
   ```