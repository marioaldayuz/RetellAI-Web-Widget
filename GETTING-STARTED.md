# 🚀 Getting Started - RetellAI Universal Widget

This is a **complete, cloneable repository** for deploying your own universal AI voice assistant widget.

## ⚡ One-Command Setup

```bash
# 1. Clone this repo
git clone https://github.com/yourusername/RetellAI-Web-Widget.git
cd RetellAI-Web-Widget

# 2. Setup everything
npm run setup

# 3. Configure environment
cd server
npm run setup:env
# Follow the prompts to enter your Retell AI API key and choose access mode

# 4. Build and test
cd ..
npm run build
npm run server:start

# 5. Test everything works
cd server && npm test
```

**Done!** Your widget is now ready to be embedded anywhere.

## 🌍 Make It Universal

To allow **anyone** to embed your widget on **any website**:

```bash
cd server
echo "UNIVERSAL_ACCESS=true" >> .env
npm start
```

Now anyone can use this integration code:

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

## 📦 Deploy to Production

```bash
# Prepare deployment files
npm run deploy:prepare

# This creates a deployment/ folder with:
# - widget/ (files for your CDN)
# - server/ (files for your backend hosting)
# - integration-example.html (working example)
```

## 🎯 What You Get

- ✅ **Universal Widget**: Embeddable on any website
- ✅ **Secure Backend**: Proxy server with CORS and rate limiting
- ✅ **Easy Configuration**: Interactive setup scripts
- ✅ **Production Ready**: Built-in security and monitoring
- ✅ **Deployment Tools**: Automated preparation scripts

## 📚 Full Documentation

- [Complete Setup Guide](./CLONE-AND-DEPLOY.md)
- [Universal Deployment](./universal-widget-deployment.md)
- [Integration Examples](./widget-usage-guide.md)

## 🆘 Need Help?

1. **Setup Issues**: Run `npm run setup` in the root directory
2. **Server Issues**: Run `cd server && npm test` to diagnose
3. **Configuration**: Use `cd server && npm run setup:env` for guided setup

Happy deploying! 🎉