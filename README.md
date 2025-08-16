# Retell AI Widget - Secure Implementation

A beautiful, embeddable voice call widget for Retell AI with enterprise-grade security and production-ready deployment configurations that work with **ANY domain**.

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

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env and add your Retell API key
nano .env
```

**Important:** Never commit `.env` to version control!

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

Embed the widget in your website:

```javascript
// Basic embedding
new RetellWidget({
  agentId: 'your_agent_id',
  proxyEndpoint: 'https://yourdomain.com/api/create-web-call',
  position: 'bottom-right', // or 'bottom-left', 'top-right', 'top-left'
  theme: 'purple' // or 'blue', 'green'
});
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

- **🔧 Systemd Fix:** See [systemd-fix.sh](./systemd-fix.sh) for immediate fixes
- **📖 Comprehensive Guide:** See [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) for fresh server setups
- **⚡ Quick Deployment:** See [README-DEPLOYMENT.md](./README-DEPLOYMENT.md) for overview
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
