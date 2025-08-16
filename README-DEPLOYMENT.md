# Retell AI Widget - Deployment Guide

## 🚀 Quick Start

This guide provides domain-agnostic deployment scripts that work with ANY domain.

## ⚡ Recent Improvements (Systemd Fix)

**IMPORTANT**: If you experienced systemd service failures with "Changing to the requested working directory failed" errors, these have been **FIXED**! 

### What was fixed:
- ✅ **Absolute path detection** in systemd-setup.sh
- ✅ **Pre-flight validation** of directories and files
- ✅ **Better error messages** with detailed troubleshooting info
- ✅ **Dependency checking** before service creation

### Updated files:
- `systemd-setup.sh` - Now uses absolute paths and validates everything before creating service
- `systemd-fix.sh` - Emergency fix script for existing deployments
- `DEPLOYMENT-GUIDE.md` - Comprehensive guide for fresh server deployments

For detailed troubleshooting and fresh server setup, see [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md).

## 📋 Prerequisites

- Ubuntu/Debian server (tested on Ubuntu 24.04)
- Root or sudo access
- Domain name pointing to your server (for production)
- Node.js and npm installed

## 🔧 Deployment Options

### Option 1: Nginx Deployment (Recommended for Production)

Perfect for production deployments with custom domains and SSL.

```bash
# Basic deployment with domain
sudo ./deploy.sh yourdomain.com

# With email for SSL certificate
sudo ./deploy.sh yourdomain.com nginx admin@yourdomain.com

# Custom ports
sudo ./nginx-setup-fixed.sh yourdomain.com 3001 5173
```

### Option 2: Docker Deployment

Great for containerized deployments and local development.

```bash
# Deploy with Docker
./deploy.sh localhost docker

# Or with a domain
./deploy.sh yourdomain.com docker
```

### Option 3: Manual Deployment

For custom setups or other web servers.

```bash
# Build only
./deploy.sh yourdomain.com manual
```

## 📝 Step-by-Step Nginx Deployment

### 1. Initial Setup

```bash
# Clone the repository
git clone <your-repo>
cd RetellAI-Web-Widget

# Create .env file
cp .env.example .env
# Edit .env and add your RETELL_API_KEY

# Make scripts executable
chmod +x *.sh
```

### 2. Configure Nginx (HTTP First)

```bash
# Run the setup script with YOUR domain
sudo ./nginx-setup-fixed.sh yourdomain.com

# This creates HTTP-only config for SSL verification
```

### 3. Obtain SSL Certificate

```bash
# Get SSL certificate from Let's Encrypt
sudo certbot certonly --webroot \
  -w /var/www/certbot \
  -d yourdomain.com \
  -d www.yourdomain.com \
  --email admin@yourdomain.com
```

### 4. Enable HTTPS

```bash
# After certificate is obtained, enable SSL
sudo ./enable-ssl.sh yourdomain.com
```

### 5. Deploy Application

```bash
# Build the application
npm run build

# Copy to web root
sudo cp -r dist/* /var/www/retell-widget/dist/

# Start backend server
cd server && npm start
```

## 🔥 Quick Fix for SSL Issues

If you encounter SSL configuration errors:

```bash
# Run quick fix script with YOUR domain
sudo ./quick-fix.sh yourdomain.com

# Follow the instructions provided by the script
```

## 🛠️ Script Reference

### `deploy.sh`
Main deployment script that handles the entire process.

```bash
Usage: ./deploy.sh <domain> [deploy_type] [email]

Examples:
  ./deploy.sh example.com                    # Nginx with prompts
  ./deploy.sh example.com nginx admin@ex.com # Full auto
  ./deploy.sh localhost docker               # Docker deployment
```

### `nginx-setup-fixed.sh`
Sets up Nginx with HTTP-only configuration initially.

```bash
Usage: ./nginx-setup-fixed.sh <domain> [backend_port] [frontend_port]

Examples:
  ./nginx-setup-fixed.sh example.com         # Default ports
  ./nginx-setup-fixed.sh example.com 3001 5173  # Custom ports
```

### `enable-ssl.sh`
Enables HTTPS after SSL certificate is obtained.

```bash
Usage: ./enable-ssl.sh <domain> [backend_port]

Examples:
  ./enable-ssl.sh example.com                # Default backend port
  ./enable-ssl.sh example.com 3001           # Custom backend port
```

### `quick-fix.sh`
Emergency fix for SSL configuration issues.

```bash
Usage: ./quick-fix.sh <domain>

Example:
  ./quick-fix.sh example.com
```

## 📁 Directory Structure

```
/var/www/
├── retell-widget/
│   └── dist/           # Frontend build files
└── certbot/            # Let's Encrypt challenges

/etc/nginx/
├── sites-available/
│   └── retell-widget   # Nginx configuration
└── sites-enabled/
    └── retell-widget   # Symlink to config
```

## 🔒 SSL Certificate Management

### View Certificate Info
```bash
sudo certbot certificates
```

### Test Auto-Renewal
```bash
sudo certbot renew --dry-run
```

### Force Renewal
```bash
sudo certbot renew --force-renewal
```

## 📊 Monitoring

### Check Service Status
```bash
# Nginx
sudo systemctl status nginx

# Backend (if using systemd)
sudo systemctl status retell-backend

# View logs
sudo tail -f /var/log/nginx/yourdomain-*.log
```

### Test Endpoints
```bash
# Health check
curl https://yourdomain.com/health

# API test
curl https://yourdomain.com/api/health
```

## 🚨 Troubleshooting

### Nginx Configuration Error
```bash
# Test configuration
sudo nginx -t

# View detailed error
sudo journalctl -xe
```

### SSL Certificate Issues
```bash
# Check certificate paths
ls -la /etc/letsencrypt/live/yourdomain.com/

# Verify DNS
dig yourdomain.com
```

### Port Already in Use
```bash
# Find process using port
sudo lsof -i :3001

# Kill process
sudo kill -9 <PID>
```

## 🔄 Updating

To update your deployment:

```bash
# Pull latest changes
git pull

# Rebuild
npm run build

# Deploy new build
sudo cp -r dist/* /var/www/retell-widget/dist/

# Restart backend
sudo systemctl restart retell-backend
```

## 🌍 Multiple Domains

To deploy on multiple domains:

```bash
# Run setup for each domain
sudo ./nginx-setup-fixed.sh domain1.com
sudo ./nginx-setup-fixed.sh domain2.com

# Get certificates for each
sudo certbot certonly --webroot -w /var/www/certbot -d domain1.com
sudo certbot certonly --webroot -w /var/www/certbot -d domain2.com

# Enable SSL for each
sudo ./enable-ssl.sh domain1.com
sudo ./enable-ssl.sh domain2.com
```

## 📧 Support

For issues or questions:
1. Check the logs: `sudo tail -f /var/log/nginx/*.log`
2. Test configuration: `sudo nginx -t`
3. Verify DNS: `nslookup yourdomain.com`
4. Check firewall: `sudo ufw status`

## ✅ Production Checklist

- [ ] Domain DNS configured
- [ ] Firewall rules set (ports 80, 443)
- [ ] SSL certificate obtained
- [ ] HTTPS enabled and tested
- [ ] Backend service running
- [ ] Monitoring configured
- [ ] Backup strategy in place
- [ ] Auto-renewal tested
