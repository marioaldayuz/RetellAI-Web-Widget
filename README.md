# Retell AI Widget - Secure Implementation

A beautiful, embeddable voice call widget for Retell AI with enterprise-grade security and production-ready deployment configurations.

## 🔒 Security Features

- **No API keys in client code** - All sensitive credentials stored server-side
- **Proxy server architecture** - Backend handles all API authentication
- **Rate limiting** - Prevents abuse and protects against attacks
- **CORS protection** - Configurable allowed origins
- **Environment variables** - Secure credential management
- **Helmet.js** - Additional security headers
- **SSL/TLS support** - Full HTTPS encryption in production

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

### 🔧 Deployment Options

#### Option 1: Nginx Reverse Proxy (Recommended)

Perfect for VPS, dedicated servers, or cloud VMs (AWS EC2, DigitalOcean, Linode).

**Setup Steps:**

1. **Prepare your server:**
```bash
# Clone the repository
git clone https://github.com/yourusername/retell-widget.git
cd retell-widget

# Make scripts executable
chmod +x nginx-setup.sh systemd-setup.sh

# Install dependencies
npm install
cd server && npm install && cd ..
```

2. **Build the frontend:**
```bash
npm run build
```

3. **Setup Nginx proxy:**
```bash
# Run with your domain
sudo ./nginx-setup.sh yourdomain.com

# The script will:
# - Install Nginx if not present
# - Create optimized configuration
# - Set up rate limiting
# - Configure security headers
# - Enable HTTPS redirect
```

4. **Setup SSL certificate:**
```bash
# Using Let's Encrypt (free SSL)
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

5. **Setup backend as systemd service:**
```bash
# This ensures your backend runs continuously
sudo ./systemd-setup.sh

# Check service status
sudo systemctl status retell-widget-backend
```

6. **Deploy frontend files:**
```bash
# Copy built files to web root
sudo cp -r dist/* /var/www/retell-widget/dist/
sudo chown -R www-data:www-data /var/www/retell-widget
```

**Nginx Configuration Features:**
- ✅ Rate limiting (10 req/s for API, 30 req/s general)
- ✅ Gzip compression for better performance
- ✅ Security headers (HSTS, CSP, X-Frame-Options)
- ✅ WebSocket support for real-time communication
- ✅ SSL/TLS with modern cipher suites
- ✅ Static asset caching (30 days)
- ✅ Health check endpoint
- ✅ Logging and monitoring

#### Option 2: Docker Deployment

Perfect for containerized environments and orchestration platforms.

**Setup Steps:**

1. **Build and run with Docker Compose:**
```bash
# Build all services
docker-compose build

# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f
```

2. **For production with Docker:**
```bash
# Build images
docker build -t retell-backend ./server
docker build -t retell-frontend .

# Run with environment variables
docker run -d \
  --name retell-backend \
  -p 3001:3001 \
  --env-file .env \
  retell-backend

docker run -d \
  --name retell-frontend \
  -p 80:80 \
  retell-frontend
```

**Docker Features:**
- ✅ Multi-stage builds for smaller images
- ✅ Health checks for container monitoring
- ✅ Non-root user for security
- ✅ Signal handling with dumb-init
- ✅ Network isolation
- ✅ Volume mounting for persistence

#### Option 3: Node.js Hosting Platforms

**Heroku:**
```bash
# Backend deployment
cd server
heroku create your-app-backend
heroku config:set RETELL_API_KEY=your_key_here
git push heroku main

# Frontend - use static site hosting
```

**Railway/Render:**
```bash
# Connect GitHub repo
# Set environment variables in dashboard
# Deploy automatically on push
```

#### Option 4: Serverless Deployment

**Vercel (Frontend + API Routes):**
```javascript
// api/create-web-call.js
export default async function handler(req, res) {
  // Proxy logic here
}
```

**AWS Lambda:**
```bash
# Use Serverless Framework
serverless deploy
```

### 🔐 Production Security Checklist

- [ ] **Environment Variables**
  ```bash
  # Production .env
  RETELL_API_KEY=your_production_key
  NODE_ENV=production
  ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
  ```

- [ ] **Update CORS Origins**
  ```javascript
  // server/server.js
  const allowedOrigins = [
    'https://yourdomain.com',
    'https://app.yourdomain.com'
  ];
  ```

- [ ] **Enable SSL/TLS**
  - Use Let's Encrypt for free certificates
  - Enable HSTS headers
  - Redirect HTTP to HTTPS

- [ ] **Configure Rate Limiting**
  ```javascript
  // Adjust based on your needs
  const limiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minute
    max: 20 // limit each IP to 20 requests
  });
  ```

- [ ] **Set Up Monitoring**
  - Application logs
  - Error tracking (Sentry)
  - Uptime monitoring
  - Performance metrics

- [ ] **Regular Updates**
  - Keep dependencies updated
  - Security patches
  - API key rotation

### 📊 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└─────────────────┬───────────────────────────────────────────┘
                  │ HTTPS
┌─────────────────▼───────────────────────────────────────────┐
│              Nginx Reverse Proxy (Port 80/443)              │
│  • SSL Termination  • Rate Limiting  • Load Balancing       │
└────────┬──────────────────────────────────┬─────────────────┘
         │                                  │
         │ /api/*                           │ /*
         │                                  │
┌────────▼────────────┐           ┌────────▼────────────┐
│   Backend Server    │           │   Static Files      │
│    (Port 3001)      │           │   (Nginx/CDN)       │
│                     │           │                     │
│  • API Proxy        │           │  • HTML/CSS/JS      │
│  • Auth Token       │           │  • Assets           │
│  • Rate Limiting    │           │  • Widget Code      │
└────────┬────────────┘           └─────────────────────┘
         │
         │ HTTPS + API Key
         │
┌────────▼────────────┐
│    Retell AI API    │
│   (External Service) │
└─────────────────────┘
```

### 🛠️ Configuration

#### Widget Configuration

```javascript
// Embed in your website
new RetellWidget({
  agentId: 'your_agent_id',
  proxyEndpoint: 'https://yourdomain.com/api/create-web-call',
  position: 'bottom-right', // or 'bottom-left', 'top-right', 'top-left'
  theme: 'purple' // or 'blue', 'green'
});
```

#### Server Configuration

```javascript
// server/server.js
const config = {
  port: process.env.PORT || 3001,
  corsOrigins: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:5173'],
  rateLimit: {
    windowMs: 60000,
    max: 20
  }
};
```

### 🔍 Testing & Monitoring

#### Health Checks

```bash
# Check backend health
curl https://yourdomain.com/api/health

# Check frontend
curl https://yourdomain.com/

# Check Nginx status
sudo nginx -t
sudo systemctl status nginx
```

#### Load Testing

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Test API endpoint
ab -n 1000 -c 10 https://yourdomain.com/api/health
```

#### Monitoring Commands

```bash
# View backend logs (systemd)
sudo journalctl -u retell-widget-backend -f

# View Nginx access logs
sudo tail -f /var/log/nginx/retell-widget-access.log

# View Nginx error logs
sudo tail -f /var/log/nginx/retell-widget-error.log

# Check system resources
htop
```

### 📈 Performance Optimization

1. **Enable Caching:**
   - Static assets: 30 days
   - API responses: Based on content type
   - CDN integration for global distribution

2. **Compression:**
   - Gzip enabled for text content
   - Brotli compression for modern browsers

3. **Connection Pooling:**
   - Keep-alive connections
   - HTTP/2 enabled

4. **Resource Optimization:**
   - Minified JavaScript and CSS
   - Optimized images
   - Lazy loading for non-critical resources

### 🚨 Troubleshooting

#### Common Issues

**Backend won't start:**
```bash
# Check logs
sudo journalctl -u retell-widget-backend -n 50

# Verify .env file
cat .env

# Check port availability
sudo lsof -i :3001
```

**Nginx errors:**
```bash
# Test configuration
sudo nginx -t

# Reload after changes
sudo systemctl reload nginx

# Check error logs
sudo tail -f /var/log/nginx/error.log
```

**CORS issues:**
```javascript
// Ensure your domain is in allowedOrigins
const allowedOrigins = [
  'https://yourdomain.com' // Add your domain here
];
```

**SSL certificate issues:**
```bash
# Renew certificate
sudo certbot renew

# Force renewal
sudo certbot renew --force-renewal
```

### 📝 Maintenance

#### Regular Tasks

- **Weekly:** Check logs for errors
- **Monthly:** Update dependencies
- **Quarterly:** Rotate API keys
- **Yearly:** Renew SSL certificates (auto-renewal recommended)

#### Backup Strategy

```bash
# Backup configuration
tar -czf backup-$(date +%Y%m%d).tar.gz .env server/ nginx/

# Backup to remote location
rsync -avz backup-*.tar.gz user@backup-server:/backups/
```

### 🤝 Support

For issues or questions:
1. Check the troubleshooting section
2. Review server logs
3. Open an issue on GitHub
4. Contact support with error logs

### 📄 License

MIT License - Use freely in your projects!

---

**Remember:** 
- Never expose API keys in client-side code
- Always use HTTPS in production
- Keep your dependencies updated
- Monitor your application logs
- Set up proper backups
