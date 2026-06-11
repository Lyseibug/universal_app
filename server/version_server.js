/**
 * Simple Version Management Server for Universal ERP App.
 * 
 * Run: node version_server.js
 * Serves at: http://localhost:3000
 * 
 * Endpoint: GET /api/method/app_version_check
 * Returns version info matching the app's expected format.
 * 
 * To test different scenarios, edit version.json in this same folder.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;

const server = http.createServer((req, res) => {
  // CORS headers (for testing from any origin)
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Version check endpoint (matches Frappe API format)
  if (req.url === '/api/method/app_version_check' && req.method === 'GET') {
    try {
      const versionFile = path.join(__dirname, 'version.json');
      const versionData = JSON.parse(fs.readFileSync(versionFile, 'utf8'));

      // Wrap in Frappe's "message" key format
      const response = {
        message: versionData
      };

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(response));

      console.log(`[${new Date().toISOString()}] Version check served:`, versionData);
    } catch (err) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Failed to read version.json', details: err.message }));
      console.error('Error:', err.message);
    }
    return;
  }

  // Health check
  if (req.url === '/api/method/ping') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ message: 'pong' }));
    return;
  }

  // 404 for anything else
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not found' }));
});

server.listen(PORT, () => {
  console.log(`\n🚀 Version Management Server running at http://localhost:${PORT}`);
  console.log(`📋 Endpoint: GET http://localhost:${PORT}/api/method/app_version_check`);
  console.log(`\n📝 Edit server/version.json to change the response.\n`);
  console.log('Scenarios you can test:');
  console.log('  1. Up to date     → current_version = "1.0.0", force_update = false');
  console.log('  2. Optional update → current_version = "1.1.0", force_update = false');
  console.log('  3. Force update    → current_version = "2.0.0", minimum_supported_version = "1.5.0", force_update = true');
  console.log('\nWaiting for requests...\n');
});
