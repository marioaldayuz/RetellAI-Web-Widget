#!/usr/bin/env node

/**
 * Test script for RetellAI Widget Server
 * Validates server configuration and endpoints
 */

import http from 'http';
import https from 'https';

const PORT = process.env.PORT || 3001;
const BASE_URL = `http://localhost:${PORT}`;

console.log('🧪 Testing RetellAI Widget Server');
console.log('='.repeat(40));
console.log();

function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const req = client.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: data
        });
      });
    });
    
    req.on('error', reject);
    
    if (options.body) {
      req.write(options.body);
    }
    
    req.end();
  });
}

async function testEndpoint(name, url, options = {}) {
  try {
    console.log(`Testing ${name}...`);
    const response = await makeRequest(url, options);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      console.log(`✅ ${name}: OK (${response.statusCode})`);
      return true;
    } else {
      console.log(`❌ ${name}: Failed (${response.statusCode})`);
      console.log(`   Response: ${response.body}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ ${name}: Error - ${error.message}`);
    return false;
  }
}

async function testCORS(url) {
  try {
    console.log('Testing CORS configuration...');
    const response = await makeRequest(url, {
      method: 'OPTIONS',
      headers: {
        'Origin': 'https://example.com',
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type'
      }
    });
    
    const corsHeaders = response.headers['access-control-allow-origin'];
    if (corsHeaders) {
      console.log(`✅ CORS: Configured (${corsHeaders})`);
      return true;
    } else {
      console.log('❌ CORS: Not properly configured');
      return false;
    }
  } catch (error) {
    console.log(`❌ CORS: Error - ${error.message}`);
    return false;
  }
}

async function runTests() {
  let passed = 0;
  let total = 0;
  
  console.log(`Server URL: ${BASE_URL}\n`);
  
  // Test health endpoint
  total++;
  if (await testEndpoint('Health Check', `${BASE_URL}/health`)) {
    passed++;
  }
  
  // Test CORS
  total++;
  if (await testCORS(`${BASE_URL}/api/create-web-call`)) {
    passed++;
  }
  
  // Test create-web-call endpoint (should fail without API key but respond)
  total++;
  const testPayload = JSON.stringify({ agent_id: 'test_agent_123' });
  if (await testEndpoint('Create Web Call Endpoint', `${BASE_URL}/api/create-web-call`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Origin': 'https://test-domain.com'
    },
    body: testPayload
  })) {
    passed++;
  }
  
  // Test 404 handling
  total++;
  const response404 = await makeRequest(`${BASE_URL}/nonexistent`);
  if (response404.statusCode === 404) {
    console.log('✅ 404 Handling: OK');
    passed++;
  } else {
    console.log('❌ 404 Handling: Failed');
  }
  
  console.log();
  console.log('='.repeat(40));
  console.log(`Test Results: ${passed}/${total} passed`);
  
  if (passed === total) {
    console.log('🎉 All tests passed! Server is ready for deployment.');
  } else {
    console.log('⚠️  Some tests failed. Check your configuration.');
    console.log();
    console.log('Common issues:');
    console.log('- Make sure the server is running (npm start)');
    console.log('- Check your .env file configuration');
    console.log('- Verify RETELL_API_KEY is set');
  }
  
  console.log();
  console.log('To start the server: npm start');
  console.log('To setup environment: npm run setup:env');
}

// Check if server is running
console.log('Checking if server is running...');
makeRequest(`${BASE_URL}/health`)
  .then(() => {
    console.log('✅ Server is running\n');
    runTests();
  })
  .catch(() => {
    console.log('❌ Server is not running');
    console.log('Please start the server first: npm start');
    console.log();
  });