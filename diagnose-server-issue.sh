#!/bin/bash

# Diagnostic script for server startup issues

echo "================================================"
echo "Diagnosing RetellAI Backend Server Issues"
echo "================================================"
echo ""

# 1. Check current directory and server file
echo "1. Checking working directory and server file:"
echo "   Current directory: $(pwd)"
echo "   Server directory from service: /root/RetellAI-Web-Widget/server"
echo ""

# 2. Check if server.js exists
echo "2. Checking if server files exist:"
if [ -f "server/server.js" ]; then
    echo "   ✅ server/server.js exists"
    echo "   File size: $(ls -lh server/server.js | awk '{print $5}')"
else
    echo "   ❌ server/server.js NOT FOUND!"
fi
echo ""

# 3. Check Node.js version
echo "3. Node.js version:"
node --version
echo ""

# 4. Try to run the server directly to see error
echo "4. Testing server directly (will show actual error):"
echo "   Running: cd server && node server.js"
echo "----------------------------------------"
cd server 2>/dev/null || cd /root/RetellAI-Web-Widget/server
timeout 3 node server.js 2>&1 | head -20
echo "----------------------------------------"
echo ""

# 5. Check for missing dependencies
echo "5. Checking package.json and node_modules:"
if [ -f "package.json" ]; then
    echo "   ✅ package.json exists"
    
    # Check if node_modules exists
    if [ -d "node_modules" ]; then
        echo "   ✅ node_modules exists"
    else
        echo "   ❌ node_modules NOT FOUND - need to run: npm install"
    fi
    
    # Check for specific required packages
    echo ""
    echo "   Checking for required packages:"
    for package in express cors dotenv node-fetch; do
        if [ -d "node_modules/$package" ]; then
            echo "   ✅ $package installed"
        else
            echo "   ❌ $package NOT installed"
        fi
    done
else
    echo "   ❌ package.json NOT FOUND!"
fi
echo ""

# 6. Check environment file
echo "6. Checking .env file:"
if [ -f ".env" ]; then
    echo "   ✅ .env file exists"
    grep -q "RETELL_API_KEY" .env && echo "   ✅ RETELL_API_KEY is set" || echo "   ⚠️  RETELL_API_KEY not found"
    grep -q "ALLOWED_ORIGINS" .env && echo "   ✅ ALLOWED_ORIGINS is set" || echo "   ℹ️  ALLOWED_ORIGINS not set"
else
    echo "   ⚠️  .env file not found (server will use defaults)"
fi
echo ""

# 7. Check service configuration
echo "7. Service configuration:"
echo "   Service file: /etc/systemd/system/retell-widget-backend.service"
if [ -f "/etc/systemd/system/retell-widget-backend.service" ]; then
    echo "   Working directory:"
    grep "WorkingDirectory" /etc/systemd/system/retell-widget-backend.service
    echo "   Exec command:"
    grep "ExecStart" /etc/systemd/system/retell-widget-backend.service
fi
echo ""

# 8. Recent logs
echo "8. Recent service logs:"
sudo journalctl -u retell-widget-backend -n 10 --no-pager 2>/dev/null | tail -10
echo ""

echo "================================================"
echo "LIKELY ISSUES AND SOLUTIONS:"
echo "================================================"
echo ""
echo "If you see 'Cannot find module' errors:"
echo "  cd /root/RetellAI-Web-Widget/server"
echo "  npm install"
echo ""
echo "If server.js is in wrong location:"
echo "  Make sure server.js is in /root/RetellAI-Web-Widget/server/"
echo ""
echo "If missing dependencies:"
echo "  cd /root/RetellAI-Web-Widget/server"
echo "  npm install express cors dotenv node-fetch"
echo ""
echo "After fixing, restart service:"
echo "  sudo systemctl restart retell-widget-backend"
echo "  sudo systemctl status retell-widget-backend"
echo "================================================"
