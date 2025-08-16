#!/usr/bin/env node

/**
 * Interactive environment setup for RetellAI Widget Server
 * Helps users configure their environment variables
 */

import fs from 'fs';
import readline from 'readline';
import path from 'path';

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

console.log('🚀 RetellAI Widget Server - Environment Setup');
console.log('='.repeat(50));
console.log();

const config = {};

async function question(prompt) {
  return new Promise((resolve) => {
    rl.question(prompt, resolve);
  });
}

async function setupEnvironment() {
  console.log('This setup will help you configure your .env file.\n');
  
  // Get API key
  config.RETELL_API_KEY = await question('1. Enter your Retell AI API Key: ');
  
  while (!config.RETELL_API_KEY || config.RETELL_API_KEY.trim() === '') {
    console.log('❌ API Key is required!');
    config.RETELL_API_KEY = await question('   Please enter your Retell AI API Key: ');
  }
  
  console.log();
  
  // Choose access mode
  console.log('2. Choose widget access mode:');
  console.log('   a) Universal Access - Anyone can embed (public widget)');
  console.log('   b) Wildcard Access - Any domain can embed');
  console.log('   c) Specific Domains - Only allow certain websites');
  console.log();
  
  const accessMode = await question('   Choose (a/b/c): ');
  
  switch (accessMode.toLowerCase()) {
    case 'a':
      config.UNIVERSAL_ACCESS = 'true';
      console.log('✅ Universal access enabled - widget can be embedded anywhere');
      break;
      
    case 'b':
      config.ALLOWED_ORIGINS = '*';
      console.log('✅ Wildcard access enabled - any domain can embed');
      break;
      
    case 'c':
      console.log('\n   Enter allowed domains (comma-separated):');
      console.log('   Example: https://client1.com,https://client2.org,*.clients.example.com');
      config.ALLOWED_ORIGINS = await question('   Domains: ');
      
      if (!config.ALLOWED_ORIGINS || config.ALLOWED_ORIGINS.trim() === '') {
        console.log('⚠️  No domains specified, defaulting to universal access');
        config.UNIVERSAL_ACCESS = 'true';
      } else {
        console.log(`✅ Specific domains configured: ${config.ALLOWED_ORIGINS}`);
      }
      break;
      
    default:
      console.log('⚠️  Invalid choice, defaulting to universal access');
      config.UNIVERSAL_ACCESS = 'true';
  }
  
  console.log();
  
  // Port
  const port = await question('3. Server port (default: 3001): ');
  config.PORT = port || '3001';
  
  // Environment
  const env = await question('4. Environment (development/production, default: production): ');
  config.NODE_ENV = env || 'production';
  
  console.log();
  
  // Generate .env file
  const envContent = Object.entries(config)
    .map(([key, value]) => `${key}=${value}`)
    .join('\n');
  
  const envPath = path.join(process.cwd(), '.env');
  
  // Check if .env already exists
  if (fs.existsSync(envPath)) {
    const overwrite = await question('⚠️  .env file already exists. Overwrite? (y/N): ');
    if (overwrite.toLowerCase() !== 'y') {
      console.log('Setup cancelled. Your existing .env file was not modified.');
      rl.close();
      return;
    }
  }
  
  fs.writeFileSync(envPath, envContent);
  
  console.log('🎉 Environment setup complete!');
  console.log();
  console.log('Generated .env file:');
  console.log('-'.repeat(30));
  console.log(envContent);
  console.log('-'.repeat(30));
  console.log();
  console.log('Next steps:');
  console.log('1. Run "npm start" to start the server');
  console.log('2. Test the health endpoint: curl http://localhost:' + config.PORT + '/health');
  
  if (config.UNIVERSAL_ACCESS === 'true') {
    console.log('3. 🌍 Your widget can now be embedded on ANY website!');
  } else if (config.ALLOWED_ORIGINS === '*') {
    console.log('3. 🌐 Your widget can be embedded on any domain!');
  } else {
    console.log('3. 🔒 Your widget is restricted to configured domains only');
  }
  
  rl.close();
}

setupEnvironment().catch(console.error);