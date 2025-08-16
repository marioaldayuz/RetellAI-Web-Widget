# RetellAI Widget - Complete Deployment Guide

This guide ensures a smooth deployment on fresh Ubuntu servers without the systemd path issues.

## Prerequisites

1. **Ubuntu Server** (20.04 LTS or 22.04 LTS recommended)
2. **Domain name** pointing to your server
3. **Root access** or sudo privileges

## Step 1: Initial Server Setup

### Install Node.js and dependencies
```bash
# Update package manager
sudo apt update && sudo apt upgrade -y

# Install Node.js (LTS version)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install additional dependencies
sudo apt install -y nginx certbot python3-certbot-nginx git

# Verify installations
node --version
npm --version
nginx -v
```

### Clone the repository
```bash
# Clone to a standard location
cd /root  # or /home/ubuntu if not root
git clone https://github.com/your-username/RetellAI-Web-Widget.git
cd RetellAI-Web-Widget
```

## Step 2: Install Dependencies

```bash
# Install backend dependencies
cd server
npm install
cd ..

# Install frontend dependencies
npm install
```

## Step 3: Build the Frontend

```bash
# Build the production frontend
npm run build
```

## Step 4: Deploy with Fixed Scripts

### Option A: Use the Updated Setup Scripts (Recommended)

The scripts have been updated to prevent the systemd path issues:

```bash
# Make scripts executable
chmod +x nginx-setup.sh systemd-setup.sh enable-ssl.sh

# Run Nginx setup
sudo ./nginx-setup.sh yourdomain.com 3001

# Run systemd setup (this now has proper path validation)
sudo ./systemd-setup.sh

# After DNS is configured and propagated, enable SSL
sudo ./enable-ssl.sh yourdomain.com 3001
```

### Option B: Manual Setup (If scripts still have issues)

```bash
# 1. Setup Nginx manually
sudo mkdir -p /var/www/retell-widget/dist
sudo cp -r dist/* /var/www/retell-widget/dist/

# 2. Create Nginx config
sudo tee /etc/nginx/sites-available/retell-widget << 'EOF'
server {
    listen 80;
    server_name yourdomain.com;
    
    # Frontend
    location / {
        root /var/www/retell-widget/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# 3. Enable the site
sudo ln -s /etc/nginx/sites-available/retell-widget /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# 4. Create systemd service manually
sudo tee /etc/systemd/system/retell-widget-backend.service << EOF
[Unit]
Description=Retell AI Widget Backend Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$(pwd)/server
ExecStart=$(which node) server.js
Restart=always
RestartSec=10
Environment="NODE_ENV=production"
StandardOutput=append:/var/log/retell-widget-backend.log
StandardError=append:/var/log/retell-widget-backend-error.log

[Install]
WantedBy=multi-user.target
EOF

# 5. Start the service
sudo systemctl daemon-reload
sudo systemctl enable retell-widget-backend
sudo systemctl start retell-widget-backend
sudo systemctl status retell-widget-backend
```

## Step 5: SSL Certificate Setup

```bash
# Obtain SSL certificate
sudo certbot certonly --webroot -w /var/www/certbot -d yourdomain.com

# Update Nginx config for SSL
sudo tee /etc/nginx/sites-available/retell-widget << 'EOF'
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Frontend
    location / {
        root /var/www/retell-widget/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Reload Nginx
sudo nginx -t
sudo systemctl reload nginx
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Systemd Service Fails to Start
```bash
# Check the service status
sudo systemctl status retell-widget-backend

# Check logs
sudo journalctl -u retell-widget-backend -n 50

# Common fixes:
# - Ensure Node.js is installed: which node
# - Verify server.js exists: ls -la /path/to/project/server/server.js
# - Check dependencies: cd /path/to/project/server && npm install
```

#### 2. Working Directory Issues
```bash
# Verify the correct path
cd /path/to/RetellAI-Web-Widget
pwd  # This should be the WorkingDirectory in systemd service

# Update service file if needed
sudo systemctl edit retell-widget-backend --full
# Update WorkingDirectory to the correct absolute path
```

#### 3. Permission Issues
```bash
# Fix ownership
sudo chown -R root:root /path/to/RetellAI-Web-Widget
sudo chown -R www-data:www-data /var/www/retell-widget
```

### Key Improvements in Updated Scripts

1. **Absolute Path Detection**: Uses `dirname "${BASH_SOURCE[0]}"` for reliable path detection
2. **Pre-flight Validation**: Checks for required files and directories before creating service
3. **Dependency Verification**: Ensures Node.js is installed and dependencies are available
4. **Better Error Messages**: Provides clear feedback when things go wrong
5. **Configuration Summary**: Shows exactly what paths and settings were used

### Monitoring and Maintenance

```bash
# Check service status
sudo systemctl status retell-widget-backend

# View real-time logs
sudo journalctl -u retell-widget-backend -f

# Restart service
sudo systemctl restart retell-widget-backend

# Update SSL certificate (automatic with certbot)
sudo certbot renew --dry-run
```

## Security Considerations

1. **Firewall**: Ensure only ports 80, 443, and SSH are open
2. **SSL**: Always use SSL in production
3. **Updates**: Keep the system updated with `sudo apt update && sudo apt upgrade`
4. **Logs**: Monitor logs regularly for any issues

This guide ensures that the systemd path issues won't occur on fresh servers by using absolute paths and proper validation throughout the deployment process.