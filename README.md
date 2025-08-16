# Retell AI Web Widget

A secure, embeddable voice call widget for Retell AI with enterprise-grade security and production-ready deployment.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Node](https://img.shields.io/badge/node-%3E%3D18.0.0-green.svg)

## 🚀 Quick Start

### One-Command Deployment

```bash
git clone https://github.com/yourusername/RetellAI-Web-Widget.git
cd RetellAI-Web-Widget
chmod +x one-touch-deploy.sh
./one-touch-deploy.sh YOUR_RETELL_API_KEY your-domain.com your@email.com
```

### Manual Setup

1. **Clone and Install**
   ```bash
   git clone https://github.com/yourusername/RetellAI-Web-Widget.git
   cd RetellAI-Web-Widget
   npm run setup  # Installs all dependencies
   ```

2. **Configure API Key**
   ```bash
   cd server
   npm run setup:env  # Interactive environment configuration
   ```

3. **Build and Test**
   ```bash
   npm run build
   npm run server:start
   cd server && npm test
   ```

4. **Deploy**
   ```bash
   npm run deploy:prepare
   # Upload deployment/widget/* to your CDN
   # Deploy deployment/server/* to your hosting service
   ```

## 🔒 Security Features

- **No API keys in client code** - All credentials stored server-side
- **Proxy server architecture** - Backend handles all API authentication
- **Rate limiting** - Protection against abuse and attacks
- **CORS protection** - Configurable allowed origins
- **Helmet.js** - Additional security headers
- **SSL/TLS support** - Full HTTPS encryption

## 🎨 Widget Integration

### Method 1: Built Files (Recommended)

```html
<!-- Include CSS and JS -->
<link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
<script src="https://your-cdn.com/retell-widget.js"></script>

<!-- Initialize widget -->
<script>
  const widget = new RetellWidget({
    agentId: 'your_agent_id',
    proxyEndpoint: 'https://your-backend.com/api/create-web-call',
    position: 'bottom-right', // or 'bottom-left', 'top-right', 'top-left'
    theme: 'purple' // or 'blue', 'green'
  });
</script>
```

### Method 2: Auto-initialization

```html
<script>
  window.retellWidgetConfig = {
    agentId: 'your_agent_id',
    proxyEndpoint: 'https://your-backend.com/api/create-web-call',
    position: 'bottom-right',
    theme: 'purple'
  };
</script>
<link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
<script src="https://your-cdn.com/retell-widget.js"></script>
```

## 📦 Production Deployment

### Nginx Deployment (Recommended)

```bash
# Make scripts executable
chmod +x *.sh

# Deploy to your domain
sudo ./one-touch-deploy.sh YOUR_RETELL_API_KEY yourdomain.com admin@yourdomain.com
```

### Docker Deployment

```bash
# Using Docker Compose
docker-compose up -d

# Check logs
docker-compose logs -f
```

### Platform Deployments

**Vercel (Frontend):**
```bash
vercel
# Set VITE_API_URL=https://your-backend.herokuapp.com
```

**Heroku (Backend):**
```bash
cd server
heroku create your-app-name
heroku config:set RETELL_API_KEY=your_key_here
git push heroku main
```

## 🌐 Configuration

### Environment Variables

```bash
# Required
RETELL_API_KEY=your_retell_api_key

# Optional
PORT=3001                    # Backend server port
NODE_ENV=production         # Environment mode
ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

### CORS Configuration

Choose your access mode:

1. **Universal Access** (Anyone can embed):
   ```bash
   UNIVERSAL_ACCESS=true
   ```

2. **Specific Domains**:
   ```bash
   ALLOWED_ORIGINS=https://client1.com,https://client2.com
   ```

## 📊 Architecture

```
┌──────────────────────────────────────────────────┐
│                   Internet                       │
└────────────────────┬─────────────────────────────┘
                     │ HTTPS (443)
┌────────────────────▼─────────────────────────────┐
│              Nginx Reverse Proxy                 │
│  • SSL Termination  • Rate Limiting  • Headers   │
└──────┬─────────────────────────┬─────────────────┘
       │ /api/*                  │ /* (static)
┌──────▼──────────┐       ┌──────▼──────────┐
│ Backend Server  │       │ Frontend Files  │
│  (Port 3001)    │       │  (Widget/App)   │
└──────┬──────────┘       └─────────────────┘
       │ HTTPS + API Key
┌──────▼──────────┐
│  Retell AI API  │
└─────────────────┘
```

## 🔍 Testing & Monitoring

### Health Checks

```bash
# Backend health
curl https://yourdomain.com/api/health

# Frontend
curl https://yourdomain.com/

# SSL certificate
curl -vI https://yourdomain.com
```

### Monitoring

```bash
# Backend logs
sudo journalctl -u retell-backend -f

# Nginx logs
sudo tail -f /var/log/nginx/yourdomain-access.log
sudo tail -f /var/log/nginx/yourdomain-error.log
```

## 🚨 Troubleshooting

| Issue | Solution |
|-------|----------|
| SSL certificate error | Run `sudo ./enable-ssl.sh yourdomain.com` |
| Backend won't start | Check `.env` file and logs: `sudo journalctl -u retell-backend -n 50` |
| CORS errors | Update `ALLOWED_ORIGINS` in `.env` file |
| Port already in use | Find process: `sudo lsof -i :3001` and kill it |

## 🔄 Updating

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

## 📚 Documentation

- [Integration Example](deployment/integration-example.html) - Complete HTML example
- [Server Documentation](server/README.md) - Backend setup details

## 🛠️ Development

### Project Structure

```
RetellAI-Web-Widget/
├── deployment/          # Production-ready files
│   ├── widget/         # Built widget files
│   └── server/         # Backend server
├── server/             # Backend source
├── src/                # Frontend source
│   ├── components/     # React components
│   └── widget.ts       # Widget entry point
└── nginx/              # Nginx configuration
```

### Available Scripts

```bash
npm run setup           # Install all dependencies
npm run build          # Build widget for production
npm run dev            # Start development server
npm run server:start   # Start backend server
npm run server:test    # Test backend API
npm run deploy:prepare # Prepare deployment files
```

## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/RetellAI-Web-Widget/issues)
- **Documentation**: Check the `/deployment` folder for integration examples

## 👨‍💼 About the Developer

<div align="center">
  <a href="https://linktr.ee/marioaldyauz">
    <img src="https://raw.githubusercontent.com/marioaldayuz/branding-assets/1acedbb7ac71e4066529372064eb7a907823e064/marioaldayuz-qr-code.png" alt="Mario Aldayuz QR Code" width="200"/>
  </a>
</div>

**Coach Mario Aldayuz** is a 7-year SaaS & HighLevel Veteran with over 15 years of Marketing, Sales, and Entrepreneurship experience. Having quarterbacked several successful startup launches and exits Mario understands what drives both business owner and consumer making him the ideal well rounded coach for your HighLevel SaaSpreneur journey.

If you are serious about scaling your business and ready for value packed coaching join Mario Aldayuz to learn everything from HighLevel to N8N to Artificial Intelligence to SaaS & Business operations.

🔗 **Consulting Services**: [OllieBot.ai](https://olliebot.ai) - N8N and HighLevel consulting service

## 🌊 Hosting Partner

[![DigitalOcean Referral Badge](https://web-platforms.sfo2.cdn.digitaloceanspaces.com/WWW/Badge%201.svg)](https://www.digitalocean.com/?refcode=c28f896d5736&utm_campaign=Referral_Invite&utm_medium=Referral_Program&utm_source=badge)

## 📄 License

MIT License - See [LICENSE.md](LICENSE.md) for details

---

**Built with** ❤️ **using** TypeScript, React, Express, and Vite