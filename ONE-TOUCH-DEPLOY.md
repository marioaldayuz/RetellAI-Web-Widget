# 🚀 ONE-TOUCH DEPLOYMENT

Deploy everything with a single command on your Linux server!

## ⚡ Quick Deploy

```bash
git clone https://github.com/yourusername/RetellAI-Web-Widget.git
cd RetellAI-Web-Widget
chmod +x one-touch-deploy.sh
./one-touch-deploy.sh YOUR_RETELL_API_KEY your-domain.com your@email.com
```

## 🎯 What It Does

1. ✅ Installs Node.js and dependencies
2. ✅ Configures universal access (any website can embed)
3. ✅ Builds the widget
4. ✅ Sets up Nginx with SSL
5. ✅ Creates systemd service
6. ✅ Obtains SSL certificate
7. ✅ Gives you ready-to-paste widget code

## 📋 Usage

```bash
./one-touch-deploy.sh YOUR_RETELL_API_KEY YOUR_DOMAIN [YOUR_EMAIL]
```

### Examples

```bash
# Basic deployment
./one-touch-deploy.sh retell_sk_1234567890 api.mycompany.com

# With email for SSL certificate
./one-touch-deploy.sh retell_sk_1234567890 api.mycompany.com admin@mycompany.com

# Subdomain deployment
./one-touch-deploy.sh retell_sk_1234567890 widget.mycompany.com admin@mycompany.com
```

## 📦 After Running Deploy Script

You'll get this output ready to copy-paste:

```html
<!-- RetellAI Widget Integration Code -->
<link rel="stylesheet" href="https://your-domain.com/widget/retell-widget.css">
<script src="https://your-domain.com/widget/retell-widget.js"></script>
<script>
  new RetellWidget({
    agentId: 'your_agent_id_here',  // Replace with your Retell agent ID
    proxyEndpoint: 'https://your-domain.com/api/create-web-call'
  });
</script>
```

## ✅ What Gets Deployed

The script automatically:

1. **Installs everything needed**
   - Node.js 20.x (if not present)
   - All npm dependencies
   - Nginx web server
   - Certbot for SSL

2. **Configures Nginx**
   - Serves widget files at `/widget/`
   - Proxies API calls to backend
   - Sets up CORS headers

3. **Sets up SSL**
   - Obtains Let's Encrypt certificate
   - Auto-configures HTTPS
   - Redirects HTTP to HTTPS

4. **Creates systemd service**
   - Auto-starts on boot
   - Auto-restarts on failure
   - Logs to `/var/log/retell-widget-backend.log`

## 🔧 Server Management

### Service Commands
```bash
# Check status
sudo systemctl status retell-widget-backend

# View logs
sudo journalctl -u retell-widget-backend -f

# Restart service
sudo systemctl restart retell-widget-backend

# Stop service
sudo systemctl stop retell-widget-backend

# Start service
sudo systemctl start retell-widget-backend
```

### Test Deployment
```bash
# Test health endpoint
curl https://your-domain.com/health

# Check widget files
curl -I https://your-domain.com/widget/retell-widget.js
curl -I https://your-domain.com/widget/retell-widget.css
```

## 🚨 Troubleshooting

### DNS Not Pointing to Server
Make sure your domain's A record points to your server's IP address

### Port Already in Use
```bash
sudo lsof -i :3001
sudo kill -9 <PID>
```

### API Key Issues
Make sure your Retell API key starts with `retell_sk_`

### Service Won't Start
```bash
# Check logs
sudo journalctl -u retell-widget-backend -n 50

# Check if Node.js is installed
node --version

# Check if server directory exists
ls -la server/
```

### SSL Certificate Issues
```bash
# Renew certificate manually
sudo certbot renew --nginx

# Test certificate
sudo certbot certificates
```

## 🔒 Security Features

Even with universal access enabled, the deployment includes:

- ✅ **Rate limiting** - Prevents abuse
- ✅ **HTTPS only** - Encrypted traffic
- ✅ **Security headers** - XSS protection
- ✅ **Input validation** - Prevents injection
- ✅ **Error handling** - No data leaks
- ✅ **Logging** - Full audit trail

## 📋 Pre-requisites

Before running the script, ensure:

1. **Fresh Ubuntu server** (20.04 or 22.04 recommended)
2. **Domain pointing to server** (A record configured)
3. **Root or sudo access**
4. **Port 80 and 443 open** in firewall

## 💡 That's It!

One command to:
- ✅ Setup everything
- ✅ Configure SSL
- ✅ Deploy to production
- ✅ Get copy-paste widget code

Your widget is now ready to embed on ANY website! 🎉