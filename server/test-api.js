#!/usr/bin/env node

// API Test Script - Tests the backend server directly
const http = require('http');

console.log('🧪 Testing RetellAI Backend Server...\n');

// Test configuration
const HOST = 'localhost';
const PORT = 3001;
const API_ENDPOINT = '/api/create-web-call';

// 1. Test if server is running
console.log('1. Checking if server is running on port', PORT + '...');

const healthReq = http.get(`http://${HOST}:${PORT}/health`, (res) => {
  if (res.statusCode === 200) {
    console.log('✅ Server is running!\n');
    
    // 2. Test API endpoint
    console.log('2. Testing API endpoint...');
    
    const postData = JSON.stringify({
      agentId: 'test_agent_id'
    });
    
    const options = {
      hostname: HOST,
      port: PORT,
      path: API_ENDPOINT,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'Origin': 'https://example.com' // Test CORS
      }
    };
    
    const apiReq = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log('Response Status:', res.statusCode);
        console.log('Response Headers:', JSON.stringify(res.headers, null, 2));
        
        // Check CORS headers
        if (res.headers['access-control-allow-origin']) {
          console.log('✅ CORS headers present:', res.headers['access-control-allow-origin']);
        } else {
          console.log('❌ CORS headers missing!');
        }
        
        console.log('\nResponse Body:', data);
        
        // Parse response
        try {
          const json = JSON.parse(data);
          if (json.error) {
            console.log('\n⚠️  API returned error:', json.error);
            if (json.error.includes('API key')) {
              console.log('   → Add your Retell API key to server/.env');
            }
          } else {
            console.log('\n✅ API endpoint working!');
          }
        } catch (e) {
          console.log('\n❌ Invalid JSON response');
        }
      });
    });
    
    apiReq.on('error', (error) => {
      console.error('❌ API request failed:', error.message);
    });
    
    apiReq.write(postData);
    apiReq.end();
    
  } else {
    console.log('❌ Server returned status:', res.statusCode);
  }
});

healthReq.on('error', (error) => {
  console.error('❌ Server is not running!');
  console.error('   Error:', error.message);
  console.log('\n📝 To start the server:');
  console.log('   cd server && npm start');
  console.log('\n   Or using systemd:');
  console.log('   sudo systemctl start retell-widget-backend');
  process.exit(1);
});

healthReq.end();