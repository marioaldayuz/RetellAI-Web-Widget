# RetellAI Widget Deployment Package

## Quick Start

### 1. Deploy Backend Server
```bash
cd server
npm install
cp env-example.txt .env
# Edit .env with your RETELL_API_KEY and settings
npm start
```

### 2. Host Widget Files
Upload these files to your CDN or static hosting:
- `widget/retell-widget.js`
- `widget/retell-widget.css`

### 3. Integration Code
Share this code for universal embedding:

```html
<link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
<script src="https://your-cdn.com/retell-widget.js"></script>
<script>
  new RetellWidget({
    agentId: 'your_agent_id',
    proxyEndpoint: 'https://your-backend.com/api/create-web-call'
  });
</script>
```

## Server Configuration

### Universal Access (Anyone can embed)
```bash
RETELL_API_KEY=your_api_key
UNIVERSAL_ACCESS=true
NODE_ENV=production
```

### Specific Domains Only
```bash
RETELL_API_KEY=your_api_key
ALLOWED_ORIGINS=https://client1.com,https://client2.com
NODE_ENV=production
```

## Files in this package:
- `server/` - Backend proxy server
- `widget/` - Frontend widget files
- `README.md` - This file

Deploy the server on your domain and host the widget files on a CDN for best performance.
