# Retell AI Widget - Secure Implementation

A beautiful, embeddable voice call widget for Retell AI with enterprise-grade security.

## 🔒 Security Features

- **No API keys in client code** - All sensitive credentials stored server-side
- **Proxy server architecture** - Backend handles all API authentication
- **Rate limiting** - Prevents abuse and protects against attacks
- **CORS protection** - Configurable allowed origins
- **Environment variables** - Secure credential management
- **Helmet.js** - Additional security headers

## 🚀 Quick Start

### 1. Install Dependencies

```bash
# Install frontend dependencies
npm install

# Install backend dependencies
cd server
npm install
cd ..
```

### 2. Configure Environment

The `.env` file is already created with your API key. For production:

1. Never commit `.env` to version control
2. Use environment variables on your hosting platform
3. Update allowed origins in `server/server.js`

### 3. Start Development Servers

```bash
# Terminal 1: Start the proxy server
cd server
npm run dev

# Terminal 2: Start the frontend
npm run dev
```

### 4. Test the Widget

1. Open http://localhost:5173 in your browser
2. The widget appears in the bottom-right corner
3. Click "Start Call" to initiate a voice conversation
4. No API keys are exposed in the browser!

## 📦 Production Deployment

### Frontend Widget

```bash
# Build the widget
npm run build

# Files will be in dist/
# - retell-widget.js (embed this)
# - retell-widget.css (include this)
```

### Backend Server

Deploy the proxy server to your preferred hosting:

**Option 1: Node.js Hosting (Heroku, Railway, Render)**
```bash
cd server
# Deploy using platform-specific CLI
```

**Option 2: Serverless (Vercel, Netlify Functions)**
- Convert server.js to serverless function format
- Deploy with platform tools

**Option 3: Container (Docker)**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY server/package*.json ./
RUN npm ci --only=production
COPY server/ .
EXPOSE 3001
CMD ["node", "server.js"]
```

## 🔧 Configuration

### Widget Configuration

```javascript
new RetellWidget({
  agentId: 'your_agent_id',
  proxyEndpoint: 'https://your-server.com/api/create-web-call',
  position: 'bottom-right', // or 'bottom-left', 'top-right', 'top-left'
  theme: 'purple' // or 'blue', 'green'
});
```

### Server Configuration

Update `server/server.js`:

```javascript
// Add your production domains
const allowedOrigins = [
  'https://yourdomain.com',
  'https://app.yourdomain.com'
];
```

### Environment Variables

```env
RETELL_API_KEY=your_api_key_here
PORT=3001
NODE_ENV=production
```

## 🛡️ Security Best Practices

1. **API Key Storage**
   - Store in environment variables only
   - Never expose in client code
   - Rotate keys regularly

2. **CORS Configuration**
   - Whitelist specific domains
   - Don't use wildcard (*) in production
   - Update `allowedOrigins` array

3. **Rate Limiting**
   - Adjust limits based on usage
   - Monitor for abuse patterns
   - Consider IP-based restrictions

4. **HTTPS Only**
   - Always use HTTPS in production
   - Enable HSTS headers
   - Use SSL certificates

5. **Monitoring**
   - Log all API requests
   - Monitor error rates
   - Set up alerts for anomalies

## 📊 Architecture

```
┌─────────────┐     HTTPS      ┌──────────────┐     HTTPS      ┌─────────────┐
│   Browser   │ ───────────▶   │ Proxy Server │ ───────────▶   │  Retell API │
│   (Widget)  │                 │  (Your API)  │                 │             │
└─────────────┘                 └──────────────┘                 └─────────────┘
     No API Key                   Has API Key                     Receives Token
```

## 🔍 Testing Security

1. **Check Network Tab**
   - No API keys visible in requests
   - Only proxy endpoint called
   - Access token received safely

2. **View Page Source**
   - No credentials in HTML
   - No API keys in JavaScript
   - Only public configuration

3. **Test Rate Limiting**
   ```bash
   # Should be rate limited after 20 requests
   for i in {1..25}; do
     curl -X POST http://localhost:3001/api/create-web-call \
       -H "Content-Type: application/json" \
       -d '{"agent_id":"test"}'
   done
   ```

## 📝 License

MIT License - Use freely in your projects!

## 🤝 Support

For issues or questions about the secure implementation, please open an issue on GitHub.

---

**Remember:** Never expose API keys in client-side code. Always use a backend proxy for production deployments.
