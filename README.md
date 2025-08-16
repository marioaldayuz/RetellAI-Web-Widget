# Retell AI Widget - Secure Implementation

A beautiful, embeddable voice call widget for Retell AI with enterprise-grade security and production-ready deployment configurations that work with **ANY domain**.

> **🚀 Ready to Clone & Deploy**: This repository is designed for easy cloning and deployment by anyone.

## 🎯 **New Here? ONE COMMAND DEPLOYMENT!**

```bash
git clone https://github.com/yourusername/RetellAI-Web-Widget.git
cd RetellAI-Web-Widget
chmod +x one-touch-deploy.sh
./one-touch-deploy.sh YOUR_RETELL_API_KEY your-domain.com your@email.com
```

👉 **[ONE-TOUCH-DEPLOY.md](./ONE-TOUCH-DEPLOY.md)** - Complete deployment guide

👉 **[GETTING-STARTED.md](./GETTING-STARTED.md)** - Manual setup guide

👉 **[CLONE-AND-DEPLOY.md](./CLONE-AND-DEPLOY.md)** - Detailed instructions

## ⚡ Recent Improvements (v2.1 - Systemd Fix)

**🎉 SYSTEMD DEPLOYMENT ISSUE FIXED!** 

If you experienced systemd service failures with "Changing to the requested working directory failed" errors, these are now **completely resolved**!

### ✅ What's Been Fixed:
- **Robust path detection** - Uses absolute paths instead of relative ones
- **Pre-deployment validation** - Checks all required files before creating services
- **Better error diagnostics** - Clear messages when something goes wrong
- **Dependency verification** - Ensures Node.js and packages are properly installed

### 📁 New Files:
- `systemd-fix.sh` - Emergency fix for existing broken deployments
- `DEPLOYMENT-GUIDE.md` - Comprehensive guide for fresh server setups

### 🔧 Updated Files:
- `systemd-setup.sh` - Now bulletproof with absolute path detection and validation
- `README-DEPLOYMENT.md` - Updated with fix information

**For existing deployments:** Use `sudo ./systemd-fix.sh` to fix immediately  
**For fresh deployments:** The updated scripts prevent the issue entirely

## 🔒 Security Features

- **No API keys in client code** - All sensitive credentials stored server-side
- **Proxy server architecture** - Backend handles all API authentication
- **Rate limiting** - Prevents abuse and protects against attacks
- **CORS protection** - Configurable allowed origins
- **Environment variables** - Secure credential management
- **Helmet.js** - Additional security headers
- **SSL/TLS support** - Full HTTPS encryption in production

## 🚀 Quick Start

### 1. Clone and Setup Everything
```bash
git clone https://github.com/yourusername/RetellAI-Web-Widget.git
cd RetellAI-Web-Widget
npm run setup  # Installs all dependencies and guides environment setup
```

### 2. Configure Your API Key
```bash
cd server
npm run setup:env  # Interactive environment configuration
```

This will ask for:
- Your Retell AI API Key
- Widget access mode (universal/specific domains)
- Server configuration

### 3. Build and Test
```bash
# Build the widget
npm run build

# Start the server
npm run server:start

# Test everything works
cd server && npm test
```

### 4. Deploy
```bash
# Prepare deployment files
npm run deploy:prepare

# Upload deployment/widget/* to your CDN
# Deploy deployment/server/* to your hosting service
```

**That's it!** Your widget is now ready to be embedded on any website.

## 📦 Production Deployment

### 🎯 Domain-Agnostic Deployment

All deployment scripts are **fully parameterized** and work with **ANY domain** - no hardcoding required!

### 🚀 One-Command Deployment

Deploy to your domain with a single command:

```bash
# Deploy to YOUR domain (replace with your actual domain)
sudo ./deploy.sh yourdomain.com nginx admin@yourdomain.com
```

This command will:
- ✅ Install and configure Nginx
- ✅ Set up SSL certificates (Let's Encrypt)
- ✅ Configure security headers and rate limiting
- ✅ Build and deploy your application
- ✅ Set up systemd service for the backend
- ✅ Enable HTTPS with auto-renewal

### 🔧 Deployment Options

#### Option 1: Nginx Reverse Proxy (Recommended)

Perfect for VPS, dedicated servers, or cloud VMs (AWS EC2, DigitalOcean, Linode).

**Quick Setup:**
```bash
# Make scripts executable
chmod +x *.sh

# Run deployment with YOUR domain
sudo ./deploy.sh yourdomain.com nginx admin@yourdomain.com
```

**Manual Setup:**
```bash
# Step 1: Setup Nginx (HTTP only initially)
sudo ./nginx-setup-fixed.sh yourdomain.com

# Step 2: Setup backend service (NOW FIXED!)
sudo ./systemd-setup.sh

# Step 3: Get SSL certificate
sudo certbot certonly --webroot \
  -w /var/www/certbot \
  -d yourdomain.com \
  --email admin@yourdomain.com

# Step 4: Enable HTTPS
sudo ./enable-ssl.sh yourdomain.com

# Step 5: Deploy application
npm run build
sudo cp -r dist/* /var/www/retell-widget/dist/
```

#### Option 2: Docker Deployment

Perfect for containerized environments:

```bash
# Deploy with Docker
./deploy.sh localhost docker

# Or with a domain
./deploy.sh yourdomain.com docker
```

Using Docker Compose:
```bash
# Build and start all services
docker-compose up -d

# Check logs
docker-compose logs -f
```

#### Option 3: Platform-Specific Deployments

**Vercel:**
```bash
# Deploy frontend to Vercel
vercel

# Set environment variable for API endpoint
VITE_API_URL=https://your-backend.herokuapp.com
```

**Heroku (Backend):**
```bash
cd server
heroku create your-app-name
heroku config:set RETELL_API_KEY=your_key_here
git push heroku main
```

**Railway/Render:**
- Connect GitHub repository
- Set environment variables in dashboard
- Deploy automatically on push

### 🛠️ Script Reference

All scripts accept domains as parameters - no modification needed!

| Script | Purpose | Usage |
|--------|---------|-------|
| `deploy.sh` | Complete deployment | `./deploy.sh yourdomain.com [nginx\|docker] [email]` |
| `nginx-setup-fixed.sh` | Nginx configuration | `./nginx-setup-fixed.sh yourdomain.com [backend_port] [frontend_port]` |
| `enable-ssl.sh` | Enable HTTPS | `./enable-ssl.sh yourdomain.com [backend_port]` |
| `quick-fix.sh` | Fix SSL issues | `./quick-fix.sh yourdomain.com` |
| `systemd-setup.sh` | Backend service (FIXED) | `./systemd-setup.sh` |
| `systemd-fix.sh` | **NEW:** Fix broken systemd | `sudo ./systemd-fix.sh` |

### 🌐 Domain Configuration

All scripts now support **intelligent www detection**:

- **Root domains** (`example.com`) → automatically includes `www.example.com`
- **Subdomains** (`api.example.com`) → no www support (auto-detected)
- **Override options** available: `--www` or `--no-www`

**Examples:**
```bash
# Auto-detection (recommended)
sudo ./nginx-setup-fixed.sh example.com          # includes www
sudo ./nginx-setup-fixed.sh api.example.com      # no www

# Explicit control
sudo ./nginx-setup-fixed.sh example.com --no-www # force no www
sudo ./nginx-setup-fixed.sh api.example.com --www # force www
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
  // server/server.js - automatically uses ALLOWED_ORIGINS from .env
  const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [
    'https://yourdomain.com',
    'https://app.yourdomain.com'
  ];
  ```

- [ ] **SSL/TLS Configuration**
  - Automatic with deployment scripts
  - Uses Let's Encrypt for free certificates
  - Auto-renewal configured via cron

- [ ] **Rate Limiting**
  - Pre-configured in Nginx (10 req/s for API)
  - Adjustable in nginx configuration

- [ ] **Monitoring Setup**
  - Application logs: `sudo journalctl -u retell-backend -f`
  - Nginx logs: `sudo tail -f /var/log/nginx/yourdomain-*.log`
  - Health endpoint: `https://yourdomain.com/health`

### 📊 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└─────────────────┬───────────────────────────────────────────┘
                  │ HTTPS (Port 443)
┌─────────────────▼───────────────────────────────────────────┐
│              Nginx Reverse Proxy                            │
│  • SSL Termination  • Rate Limiting  • Security Headers     │
└────────┬──────────────────────────────────┬─────────────────┘
         │ /api/* (proxy)                   │ /* (static)
┌────────▼────────────┐           ┌────────▼────────────┐
│   Backend Server    │           │   Frontend Files    │
│    (Port 3001)      │           │   (/var/www/...)    │
│  • API Proxy        │           │  • React App        │
│  • Authentication   │           │  • Widget Code      │
└────────┬────────────┘           └─────────────────────┘
         │ HTTPS + API Key
┌────────▼────────────┐
│    Retell AI API    │
└─────────────────────┘
```

### 🎨 Widget Configuration

#### Method 1: Include Built Files (Recommended)

1. **Build the widget:**
   ```bash
   npm install
   npm run build
   ```

2. **Include the generated files in your HTML:**
   ```html
   <!-- Include CSS and JS (can be hosted on CDN) -->
   <link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
   <script src="https://your-cdn.com/retell-widget.js"></script>
   
   <!-- Initialize the widget -->
   <script>
     const widget = new RetellWidget({
       agentId: 'your_agent_id',
       proxyEndpoint: 'https://your-backend-server.com/api/create-web-call', // MUST be full URL for 3rd party sites
       position: 'bottom-right', // or 'bottom-left', 'top-right', 'top-left'
       theme: 'purple' // or 'blue', 'green'
     });
   </script>
   ```

#### Method 2: Auto-initialization

```html
<!-- Set config before loading script -->
<script>
  window.retellWidgetConfig = {
    agentId: 'your_agent_id',
    proxyEndpoint: 'https://your-backend-server.com/api/create-web-call', // Full URL required
    position: 'bottom-right',
    theme: 'purple'
  };
</script>
<link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
<script src="https://your-cdn.com/retell-widget.js"></script>
```

#### Configuration Options

```typescript
interface WidgetConfig {
  agentId: string;                    // Required: Your Retell AI agent ID
  proxyEndpoint?: string;             // Required for 3rd party sites: Full URL to your backend
  position?: 'bottom-right' | 'bottom-left' | 'top-right' | 'top-left';
  theme?: 'purple' | 'blue' | 'green';
}
```

#### 🌐 **Deployment Options**

Choose the right deployment mode for your use case:

**1. Universal Access (Anyone can embed):**
```bash
# .env configuration
UNIVERSAL_ACCESS=true
```

**2. Wildcard Access (Any domain):**
```bash
# .env configuration  
ALLOWED_ORIGINS=*
```

**3. Specific Domains Only:**
```bash
# .env configuration
ALLOWED_ORIGINS=https://client1.com,https://client2.com,*.clients.example.com
```

**Universal Integration Example:**
```html
<!-- Can be embedded on ANY website -->
<link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
<script src="https://your-cdn.com/retell-widget.js"></script>
<script>
  new RetellWidget({
    agentId: 'your_agent_id',
    proxyEndpoint: 'https://your-backend.com/api/create-web-call'
  });
</script>
```

### 🔍 Testing & Monitoring

#### Health Checks

```bash
# Check backend health
curl https://yourdomain.com/api/health

# Check frontend
curl https://yourdomain.com/

# Check SSL certificate
curl -vI https://yourdomain.com
```

#### Monitor Services

```bash
# Backend logs (systemd)
sudo journalctl -u retell-backend -f

# Nginx access logs
sudo tail -f /var/log/nginx/yourdomain-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/yourdomain-error.log
```

### 🚨 Troubleshooting

#### Quick Fixes

```bash
# SSL configuration issues
sudo ./quick-fix.sh yourdomain.com

# Test Nginx configuration
sudo nginx -t

# Restart services
sudo systemctl restart nginx
sudo systemctl restart retell-backend
```

#### Common Issues

| Issue | Solution |
|-------|----------|
| **Systemd service won't start** | **FIXED in v2.1!** Use `sudo ./systemd-fix.sh` for existing deployments |
| SSL certificate error | Run `sudo ./quick-fix.sh yourdomain.com` then follow instructions |
| Backend won't start | Check `.env` file and logs: `sudo journalctl -u retell-widget-backend -n 50` |
| CORS errors | Update `ALLOWED_ORIGINS` in `.env` file |
| Port already in use | Find process: `sudo lsof -i :3001` and kill it |
| "Working directory failed" error | **FIXED!** Re-run `sudo ./systemd-setup.sh` with updated script |

### 📈 Performance Optimization

The deployment scripts automatically configure:

- **Gzip Compression** - Reduces bandwidth by 70%
- **Static Asset Caching** - 30-day cache for images/CSS/JS
- **HTTP/2** - Multiplexed connections for faster loading
- **Keep-Alive** - Persistent connections
- **Rate Limiting** - Prevents abuse and DDoS

### 🔄 Updating Your Deployment

```bash
# Pull latest changes
git pull

# Rebuild application
npm run build

# Deploy updates
sudo cp -r dist/* /var/www/retell-widget/dist/

# Restart backend if needed
sudo systemctl restart retell-backend
```

### 🌍 Multiple Domain Support

Deploy to multiple domains easily:

```bash
# Deploy to first domain
sudo ./deploy.sh domain1.com nginx admin@domain1.com

# Deploy to second domain
sudo ./deploy.sh domain2.com nginx admin@domain2.com
```

Each domain gets its own:
- Nginx configuration
- SSL certificate
- Log files
- Monitoring

### 📝 Environment Variables

Complete list of supported environment variables:

```bash
# Required
RETELL_API_KEY=your_retell_api_key

# Optional
PORT=3001                    # Backend server port
NODE_ENV=production          # Environment (development/production)
ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

### 🤝 Support & Documentation

#### 🚀 **Getting Started**
- **⚡ Quick Start:** [GETTING-STARTED.md](./GETTING-STARTED.md) - **NEW USERS START HERE**
- **🔄 Complete Setup:** [CLONE-AND-DEPLOY.md](./CLONE-AND-DEPLOY.md) - Detailed instructions
- **🌍 Universal Deployment:** [universal-widget-deployment.md](./universal-widget-deployment.md)
- **🎯 Widget Integration:** [widget-usage-guide.md](./widget-usage-guide.md)

#### 📚 **Advanced Deployment**
- **🌐 Cross-Domain Deployment:** [cross-domain-deployment-guide.md](./cross-domain-deployment-guide.md)
- **📋 Deployment Checklist:** [deployment-checklist.md](./deployment-checklist.md)
- **🔧 Systemd Fix:** [systemd-fix.sh](./systemd-fix.sh) for immediate fixes
- **📖 Comprehensive Guide:** [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) for fresh server setups
- **⚡ Quick Deployment:** [README-DEPLOYMENT.md](./README-DEPLOYMENT.md) for overview

#### 🛠️ **Technical Reference**
- **🛠️ Script Documentation:** Each script has `--help` option
- **📋 Logs Location:** `/var/log/nginx/` and `journalctl -u retell-widget-backend`
- **⚙️ Configuration Files:** `/etc/nginx/sites-available/retell-widget`

### 📄 License

MIT License - Use freely in your projects!

---

**Key Features:**
- 🎯 **Domain-agnostic** - Works with ANY domain
- 🔒 **Secure by default** - No API keys in client code
- 🚀 **One-command deployment** - Production-ready in minutes
- 📦 **Multiple deployment options** - Nginx, Docker, or manual
- 🛡️ **Enterprise-grade security** - SSL, CORS, rate limiting
- 📊 **Production monitoring** - Health checks and logging
- 🔄 **Easy updates** - Simple upgrade process
