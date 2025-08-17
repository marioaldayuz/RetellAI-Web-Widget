# RetellAI Web Widget - Beautiful Voice AI Assistant for Any Website

**Transform your website with conversational AI in minutes.** Beautiful Intercom-style voice widget with customizable design, real-time speech, and simple integration.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Node](https://img.shields.io/badge/node-%3E%3D18.0.0-green.svg)
![TypeScript](https://img.shields.io/badge/typescript-%3E%3D5.0.0-blue.svg)
![Production Ready](https://img.shields.io/badge/production-ready-green.svg)

## ✨ Overview

RetellAI Web Widget is a production-ready, embeddable voice assistant that transforms any website into an interactive voice-enabled experience. Built with TypeScript and modern web technologies, this open-source widget provides a beautiful Intercom-style interface for RetellAI's powerful conversational AI platform.

### 🎯 Key Features

- 🎨 **Fully Customizable Design** - Match your brand with custom colors, Font Awesome icons, welcome messages, and button labels
- 🎯 **Intercom-Style Interface** - Familiar floating bubble design that users love, expanding into a beautiful chat window
- 🎵 **Real-Time Voice Interaction** - Seamless WebRTC-powered voice conversations with visual sound wave feedback
- 🚀 **One-Touch Deployment** - Deploy to production in minutes with automated SSL, NGINX configuration, and systemd service setup
- 🔒 **Secure Proxy Server** - Built-in Node.js backend protects your API keys while enabling CORS-compliant integration
- 📱 **Responsive Design** - Perfect experience on desktop, tablet, and mobile devices
- ⚡ **Lightweight & Fast** - Optimized bundle size with Vite build system, loads instantly on any website
- 🛠️ **Developer-Friendly** - Simple JavaScript API, comprehensive documentation, and example implementations

## 🚀 Quick Start

### One-Command Deployment

```bash
git clone https://github.com/marioaldayuz/RetellAI-Web-Widget.git
cd RetellAI-Web-Widget
chmod +x one-touch-deploy.sh
./one-touch-deploy.sh YOUR_RETELL_API_KEY your-domain.com your@email.com
```

### Add to Any Website (3 Lines of Code!)

```html
<!-- Add beautiful voice AI to your website -->
<link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
<script src="https://your-cdn.com/retell-widget.js"></script>
<script>
  new RetellWidget({
    agentId: 'your_agent_id',
    proxyEndpoint: 'https://your-backend.com/api/create-web-call'
  });
</script>
```

## 🎨 Customization Examples

### Default Configuration
Simple setup with purple theme and headset icon:

```javascript
new RetellWidget({
  agentId: 'your_agent_id',
  proxyEndpoint: 'https://your-backend.com/api/create-web-call'
});
```

### Custom Brand Colors
Match your brand identity:

```javascript
new RetellWidget({
  agentId: 'your_agent_id',
  proxyEndpoint: 'https://your-backend.com/api/create-web-call',
  primaryColor: '#2563eb',      // Your brand color
  secondaryColor: '#3b82f6',    // Accent color
  bubbleIcon: 'fa-robot',       // Font Awesome icon
  position: 'bottom-right'
});
```

### Personalized Experience
Custom messages and labels:

```javascript
new RetellWidget({
  agentId: 'your_agent_id',
  proxyEndpoint: 'https://your-backend.com/api/create-web-call',
  welcomeMessage: 'Hi! How can I help you today?',
  buttonLabel: 'Talk to Assistant',
  primaryColor: '#059669',
  secondaryColor: '#10b981',
  bubbleIcon: 'fa-headset',
  position: 'bottom-left'
});
```

### Support Agent Configuration
Professional customer support setup:

```javascript
new RetellWidget({
  agentId: 'your_agent_id',
  proxyEndpoint: 'https://your-backend.com/api/create-web-call',
  bubbleIcon: 'fa-phone',
  welcomeMessage: 'Call our support team',
  buttonLabel: 'Start Support Call',
  primaryColor: '#dc2626',
  secondaryColor: '#ef4444'
});
```

## ⚙️ Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `agentId` | string | required | Your RetellAI agent ID |
| `proxyEndpoint` | string | '/api/create-web-call' | Your backend API endpoint |
| `primaryColor` | string | '#9333ea' | Primary color (hex) |
| `secondaryColor` | string | '#a855f7' | Secondary color (hex) |
| `bubbleIcon` | string | 'fa-headset' | Font Awesome icon class |
| `welcomeMessage` | string | 'How can I help you today?' | Welcome text above button |
| `buttonLabel` | string | 'Start Conversation' | Button text label |
| `position` | string | 'bottom-right' | Widget position ('bottom-right', 'bottom-left', 'top-right', 'top-left') |

### 🎯 Popular Icon Options
- `fa-headset` - Customer support
- `fa-robot` - AI assistant
- `fa-message` - Chat/messaging
- `fa-comments` - Conversation
- `fa-microphone` - Voice/audio
- `fa-phone` - Phone call
- `fa-user-headset` - Support agent
- `fa-circle-question` - Help desk

## 📋 Use Cases

- **Customer Support** - Replace traditional chat with voice-powered support agents
- **Sales Automation** - Qualify leads and answer product questions 24/7
- **Healthcare** - Patient intake, appointment scheduling, and health screening
- **E-commerce** - Product recommendations and shopping assistance
- **Education** - Interactive tutoring and language learning
- **Real Estate** - Property inquiries and virtual tour scheduling
- **Financial Services** - Account support and financial advice

## 🔒 Security Features

- **No API keys in client code** - All credentials stored server-side
- **Proxy server architecture** - Backend handles all API authentication
- **Rate limiting** - Protection against abuse and attacks
- **CORS protection** - Configurable allowed origins
- **Helmet.js** - Additional security headers
- **SSL/TLS support** - Full HTTPS encryption

## 📦 Production Deployment

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

## 🌐 Environment Configuration

### Required Variables
```bash
RETELL_API_KEY=your_retell_api_key
```

### Optional Variables
```bash
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
| Widget not appearing | Check browser console for errors, verify script URLs |
| Voice not working | Ensure HTTPS is enabled and microphone permissions granted |

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
- [Widget Demo](example.html) - Interactive demonstration
- [Test Suite](test-widget.html) - Multiple configuration examples

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

### Technical Specifications

- **Frontend**: TypeScript, Vite, Tailwind CSS, Retell Web SDK
- **Backend**: Node.js, Express.js, CORS-enabled API proxy
- **Deployment**: Docker support, NGINX reverse proxy, SSL/TLS ready
- **Integration**: Simple script tag embedding, CDN-ready distribution
- **Browser Support**: Chrome, Firefox, Safari, Edge (all modern browsers)
- **Dependencies**: Minimal - only RetellAI SDK required

## 🤝 Support & Community

- **Issues**: [GitHub Issues](https://github.com/yourusername/RetellAI-Web-Widget/issues)
- **Documentation**: Check the `/deployment` folder for integration examples
- **License**: MIT License - See [LICENSE.md](LICENSE.md) for details

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

## 🏷️ Keywords

`retell-ai`, `voice-assistant`, `web-widget`, `conversational-ai`, `voice-chat`, `embeddable-widget`, `intercom-style`, `webrtc`, `real-time-voice`, `ai-customer-support`, `voice-enabled-website`, `javascript-widget`, `typescript`, `open-source`, `voice-ai-sdk`, `customer-service-automation`, `chatbot-alternative`, `speech-to-text`, `text-to-speech`, `ai-agent`, `voice-interface`

---

**Built with** ❤️ **using** TypeScript, React, Express, and Vite
