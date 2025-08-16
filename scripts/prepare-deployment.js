#!/usr/bin/env node

/**
 * Deployment Preparation Script
 * Prepares the widget for deployment by copying necessary files
 * and creating deployment packages
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.join(__dirname, '..');

console.log('🚀 Preparing deployment files...');

// Create deployment directory
const deployDir = path.join(rootDir, 'deployment');
if (!fs.existsSync(deployDir)) {
  fs.mkdirSync(deployDir, { recursive: true });
}

// Copy widget files
const distDir = path.join(rootDir, 'dist');
const widgetDeployDir = path.join(deployDir, 'widget');
if (!fs.existsSync(widgetDeployDir)) {
  fs.mkdirSync(widgetDeployDir, { recursive: true });
}

// Copy built widget files
if (fs.existsSync(distDir)) {
  const files = fs.readdirSync(distDir);
  files.forEach(file => {
    const srcFile = path.join(distDir, file);
    const destFile = path.join(widgetDeployDir, file);
    fs.copyFileSync(srcFile, destFile);
    console.log(`✅ Copied ${file} to deployment/widget/`);
  });
} else {
  console.warn('⚠️  dist/ directory not found. Run "npm run build" first.');
}

// Copy server files
const serverDeployDir = path.join(deployDir, 'server');
if (!fs.existsSync(serverDeployDir)) {
  fs.mkdirSync(serverDeployDir, { recursive: true });
}

const serverFiles = ['server.js', 'package.json', 'env-example.txt'];
const serverDir = path.join(rootDir, 'server');

serverFiles.forEach(file => {
  const srcFile = path.join(serverDir, file);
  const destFile = path.join(serverDeployDir, file);
  if (fs.existsSync(srcFile)) {
    fs.copyFileSync(srcFile, destFile);
    console.log(`✅ Copied server/${file} to deployment/server/`);
  }
});

// Create deployment README
const deploymentReadme = `# RetellAI Widget Deployment Package

## Quick Start

### 1. Deploy Backend Server
\`\`\`bash
cd server
npm install
cp env-example.txt .env
# Edit .env with your RETELL_API_KEY and settings
npm start
\`\`\`

### 2. Host Widget Files
Upload these files to your CDN or static hosting:
- \`widget/retell-widget.js\`
- \`widget/retell-widget.css\`

### 3. Integration Code
Share this code for universal embedding:

\`\`\`html
<link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
<script src="https://your-cdn.com/retell-widget.js"></script>
<script>
  new RetellWidget({
    agentId: 'your_agent_id',
    proxyEndpoint: 'https://your-backend.com/api/create-web-call'
  });
</script>
\`\`\`

## Server Configuration

### Universal Access (Anyone can embed)
\`\`\`bash
RETELL_API_KEY=your_api_key
UNIVERSAL_ACCESS=true
NODE_ENV=production
\`\`\`

### Specific Domains Only
\`\`\`bash
RETELL_API_KEY=your_api_key
ALLOWED_ORIGINS=https://client1.com,https://client2.com
NODE_ENV=production
\`\`\`

## Files in this package:
- \`server/\` - Backend proxy server
- \`widget/\` - Frontend widget files
- \`README.md\` - This file

Deploy the server on your domain and host the widget files on a CDN for best performance.
`;

fs.writeFileSync(path.join(deployDir, 'README.md'), deploymentReadme);
console.log('✅ Created deployment/README.md');

// Create integration example
const integrationExample = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RetellAI Widget Integration Example</title>
    
    <!-- Include widget CSS -->
    <link rel="stylesheet" href="https://your-cdn.com/retell-widget.css">
    
    <style>
        body { 
            font-family: Arial, sans-serif; 
            padding: 40px; 
            background: #f0f2f5; 
        }
        .container { 
            max-width: 800px; 
            margin: 0 auto; 
            background: white; 
            padding: 40px; 
            border-radius: 8px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
        }
        .code { 
            background: #f8f9fa; 
            padding: 15px; 
            border-radius: 4px; 
            font-family: monospace; 
            white-space: pre-wrap; 
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 RetellAI Widget Integration Example</h1>
        <p>This page demonstrates how to integrate the RetellAI widget on any website.</p>
        
        <h2>📋 Integration Steps:</h2>
        <ol>
            <li>Include the widget CSS and JS files</li>
            <li>Initialize the widget with your configuration</li>
            <li>Look for the widget in the bottom-right corner!</li>
        </ol>
        
        <h2>💻 Code Used:</h2>
        <div class="code"><!-- Include widget files -->
&lt;link rel="stylesheet" href="https://your-cdn.com/retell-widget.css"&gt;
&lt;script src="https://your-cdn.com/retell-widget.js"&gt;&lt;/script&gt;

&lt;!-- Initialize widget --&gt;
&lt;script&gt;
  new RetellWidget({
    agentId: 'your_agent_id',
    proxyEndpoint: 'https://your-backend.com/api/create-web-call',
    position: 'bottom-right',
    theme: 'purple'
  });
&lt;/script&gt;</div>
        
        <p><strong>Note:</strong> Update the URLs and agentId with your actual values.</p>
    </div>
    
    <!-- Include widget JS -->
    <script src="https://your-cdn.com/retell-widget.js"></script>
    
    <!-- Initialize widget -->
    <script>
        new RetellWidget({
            agentId: 'demo_agent_12345', // Replace with your agent ID
            proxyEndpoint: 'https://your-backend.com/api/create-web-call', // Replace with your backend URL
            position: 'bottom-right',
            theme: 'purple'
        });
    </script>
</body>
</html>`;

fs.writeFileSync(path.join(deployDir, 'integration-example.html'), integrationExample);
console.log('✅ Created deployment/integration-example.html');

console.log('\n🎉 Deployment preparation complete!');
console.log('\nFiles created in deployment/:');
console.log('├── widget/');
console.log('│   ├── retell-widget.js');
console.log('│   └── retell-widget.css');
console.log('├── server/');
console.log('│   ├── server.js');
console.log('│   ├── package.json');
console.log('│   └── env-example.txt');
console.log('├── README.md');
console.log('└── integration-example.html');
console.log('\n📦 Ready for deployment!');