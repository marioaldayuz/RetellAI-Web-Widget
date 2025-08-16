#!/bin/bash

# Test script to diagnose CORS headers from production server
# This will help identify if headers are being duplicated or misconfigured

echo "================================================"
echo "CORS Header Diagnostic Tool"
echo "Testing: https://retelldemo.olliebot.ai"
echo "================================================"
echo ""

# Test 1: OPTIONS preflight from app.olliebot.ai
echo "Test 1: OPTIONS preflight request from app.olliebot.ai"
echo "--------------------------------------------------------"
curl -s -I -X OPTIONS https://retelldemo.olliebot.ai/api/create-web-call \
  -H "Origin: https://app.olliebot.ai" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" 2>&1 | grep -i "access-control" || echo "No Access-Control headers found"

echo ""
echo "Full headers:"
curl -s -I -X OPTIONS https://retelldemo.olliebot.ai/api/create-web-call \
  -H "Origin: https://app.olliebot.ai" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type"

echo ""
echo "================================================"
echo "Test 2: Direct POST request from app.olliebot.ai"
echo "--------------------------------------------------------"
curl -s -I -X POST https://retelldemo.olliebot.ai/api/create-web-call \
  -H "Origin: https://app.olliebot.ai" \
  -H "Content-Type: application/json" \
  -d '{"agent_id":"test"}' 2>&1 | grep -i "access-control" || echo "No Access-Control headers found"

echo ""
echo "================================================"
echo "Test 3: Health check endpoint"
echo "--------------------------------------------------------"
curl -s https://retelldemo.olliebot.ai/health 2>&1 || echo "Health endpoint not available"

echo ""
echo "================================================"
echo "Test 4: Count Access-Control-Allow-Origin headers"
echo "--------------------------------------------------------"
HEADERS=$(curl -s -I -X OPTIONS https://retelldemo.olliebot.ai/api/create-web-call \
  -H "Origin: https://app.olliebot.ai" \
  -H "Access-Control-Request-Method: POST" 2>&1)

COUNT=$(echo "$HEADERS" | grep -i "access-control-allow-origin" | wc -l)
echo "Number of Access-Control-Allow-Origin headers: $COUNT"

if [ "$COUNT" -gt 1 ]; then
    echo "❌ ERROR: Multiple Access-Control-Allow-Origin headers detected!"
    echo "Headers found:"
    echo "$HEADERS" | grep -i "access-control-allow-origin"
elif [ "$COUNT" -eq 1 ]; then
    echo "✅ Single Access-Control-Allow-Origin header found:"
    echo "$HEADERS" | grep -i "access-control-allow-origin"
else
    echo "⚠️ No Access-Control-Allow-Origin header found"
fi

echo ""
echo "================================================"
echo "Recommendations:"
echo "------------------------------------------------"
echo "If you see duplicate headers, check:"
echo "1. Nginx config: /etc/nginx/sites-enabled/retelldemo.olliebot.ai"
echo "2. Express server: server/server.js"
echo "3. Any middleware or proxy layers"
echo ""
echo "To fix, use the simplified server:"
echo "  cp server/server-simple-cors.js server/server.js"
echo "  # Then restart the service"
echo "================================================" 