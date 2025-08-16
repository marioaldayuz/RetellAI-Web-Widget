# 🚀 Clone and Deploy Guide

This repository is designed to be **cloned and deployed by anyone**. Follow this guide to set up your own RetellAI widget service.

## 📋 Prerequisites

- **Node.js** 18+ and npm
- **Retell AI API Key** (get from [Retell AI Dashboard](https://dashboard.retellai.com))
- **Server/Hosting** for the backend
- **CDN or static hosting** for widget files (optional)

## 🔄 Quick Clone & Deploy

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/RetellAI-Web-Widget.git
cd RetellAI-Web-Widget
```

### 2. Setup Everything
```bash
# Install all dependencies and setup environment
npm run setup

# The setup script will:
# - Install frontend dependencies  
# - Install backend dependencies
# - Guide you through environment configuration
```

### 3. Configure Backend
```bash
cd server
npm run setup:env

# This will ask you:
# - Your Retell AI API Key
# - Access mode (universal/specific domains)
# - Server port
# - Environment settings
```

### 4. Build Widget
```bash
# Return to root directory
cd ..
npm run build

# This creates:
# - dist/retell-widget.js (424KB)
# - dist/retell-widget.css (15KB)
```

### 5. Start Server
```bash
npm run server:start

# Or for development:
npm run start:dev  # Starts both frontend and backend in dev mode
```

### 6. Test Everything
```bash
cd server
npm test

# This will validate:
# - Server is running
# - CORS is configured
# - Endpoints are working
# - Error handling works
```

## 🌍 Universal Widget Deployment

### Make Widget Available on ANY Website

1. **Set Universal Access**
   ```bash
   cd server
   echo "UNIVERSAL_ACCESS=true" >> .env
   ```

2. **Build and Host Widget Files**
   ```bash
   npm run deploy:prepare
   
   # This creates a deployment/ folder with:
   # - widget/ (JS/CSS files for CDN)
   # - server/ (Backend files for your server)
   # - README.md (Deployment instructions)
   # - integration-example.html (Working example)
   ```

3. **Upload Widget to CDN**
   Upload `deployment/widget/*` to your CDN or static hosting.

4. **Share Integration Code**
   ```html
   <!-- Anyone can embed this on their website -->
   <link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
   <script src="https://your-cdn.com/retell-widget.js"></script>
   <script>
     new RetellWidget({
       agentId: 'your_agent_id',
       proxyEndpoint: 'https://your-backend.com/api/create-web-call'
     });
   </script>
   ```

## 🎯 Different Deployment Scenarios

### Scenario 1: Public Widget Service
```bash
# Anyone can embed your widget
RETELL_API_KEY=your_api_key
UNIVERSAL_ACCESS=true
NODE_ENV=production
```

### Scenario 2: Client-Specific Service
```bash
# Only specific clients can embed
RETELL_API_KEY=your_api_key
ALLOWED_ORIGINS=https://client1.com,https://client2.org,*.clients.example.com
NODE_ENV=production
```

### Scenario 3: SaaS Widget Platform
```bash
# Wildcard access with monitoring
RETELL_API_KEY=your_api_key
ALLOWED_ORIGINS=*
NODE_ENV=production
```

## 📁 Repository Structure

```
RetellAI-Web-Widget/
├── 📦 Frontend Widget
│   ├── src/
│   │   ├── widget.ts          # Main widget code
│   │   ├── styles.css         # Widget styles
│   │   └── types/retell.d.ts  # TypeScript types
│   ├── dist/                  # Built widget files (after npm run build)
│   ├── package.json           # Frontend dependencies
│   └── vite.config.ts         # Build configuration
│
├── 🖥️ Backend Server
│   ├── server.js              # Express proxy server
│   ├── package.json           # Server dependencies
│   ├── env-example.txt        # Environment template
│   ├── setup-env.js          # Interactive setup
│   └── test-server.js        # Test suite
│
├── 🚀 Deployment
│   ├── scripts/
│   │   └── prepare-deployment.js  # Deployment prep script
│   └── deployment/           # Generated deployment files
│
├── 📚 Documentation
│   ├── README.md             # Main documentation
│   ├── CLONE-AND-DEPLOY.md   # This file
│   ├── universal-widget-deployment.md
│   ├── cross-domain-deployment-guide.md
│   └── deployment-checklist.md
│
└── 🛠️ Configuration
    ├── package.json          # Project metadata & scripts
    ├── tailwind.config.js    # CSS configuration
    └── tsconfig.json         # TypeScript configuration
```

## 🔧 Available Scripts

### Root Level Commands
```bash
npm run setup              # Setup everything (frontend + backend)
npm run build              # Build widget for production
npm run start:dev          # Start both frontend and backend in dev mode
npm run deploy:prepare     # Prepare files for deployment
```

### Backend Commands
```bash
cd server
npm run setup              # Install deps and setup environment
npm run setup:env          # Interactive environment setup
npm start                  # Start production server
npm run dev                # Start development server with auto-reload
npm test                   # Test server configuration
```

## 🌍 Going Live

### 1. Deploy Backend Server
Deploy the `server/` directory to any hosting service:
- **VPS/Dedicated**: PM2, systemd, or Docker
- **Cloud**: Heroku, Railway, Render, DigitalOcean App Platform
- **Serverless**: Vercel, Netlify Functions, AWS Lambda

### 2. Host Widget Files
Upload `dist/` files to:
- **CDN**: CloudFlare, AWS CloudFront, Google Cloud CDN
- **Static Hosting**: Netlify, Vercel, GitHub Pages
- **Your Server**: Nginx, Apache static directory

### 3. Configure Domain & SSL
- Point your domain to the backend server
- Set up SSL certificate (Let's Encrypt)
- Update CORS origins in your `.env`

### 4. Test Integration
Use the provided `integration-example.html` to test the widget on different websites.

## 🔒 Security Considerations

### For Public Widgets
- ✅ Rate limiting is pre-configured
- ✅ Input validation included
- ✅ No sensitive data exposed to clients
- ⚠️ Monitor usage and costs
- ⚠️ Consider usage limits per domain

### For Private Widgets
- ✅ Restrict origins in `.env`
- ✅ Use agent-specific configurations
- ✅ Monitor client usage
- ✅ Implement authentication if needed

## 🎉 Success!

After following this guide, you'll have:

1. **🖥️ Running Backend**: Handling all API calls securely
2. **📦 Built Widget**: Ready for CDN distribution
3. **🌍 Universal Access**: Widget embeddable anywhere (if configured)
4. **📊 Monitoring**: Server logs and request tracking
5. **🛡️ Security**: Rate limiting and CORS protection

Your widget is now ready to be embedded on any website in the world! 🌍✨

## 🆘 Need Help?

- **Issues**: Check the server logs and test endpoints
- **Configuration**: Use `npm run setup:env` for interactive setup
- **Testing**: Run `npm test` in the server directory
- **Documentation**: See the comprehensive guides in this repository

Happy deploying! 🚀