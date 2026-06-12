/**
 * Version Management Server for Universal ERP App.
 *
 * Run: node version_server.js
 * Serves at: http://localhost:3000
 *
 * Endpoints:
 *   GET /api/method/app_version_check — Returns version.json (no-cache)
 *   GET /files/mobile-updates/*       — Serves APK files (no-cache)
 *
 * APK Naming Convention:
 *   app-release-v{version}.apk  (e.g. app-release-v1.0.6.apk)
 *
 * To test different scenarios, edit version.json in this same folder.
 * The apk_url in version.json should point to the versioned filename.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;

// Directory where APK files are stored (same as this script)
const FILES_DIR = __dirname;

const server = http.createServer((req, res) => {
  // CORS headers (for testing from any origin)
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Cache-Control, Pragma');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // ─── Version check endpoint ──────────────────────────────────────────────
  // Strip query params for route matching (client sends ?t=timestamp for cache busting)
  const urlPath = req.url.split('?')[0];

  if (urlPath === '/api/method/app_version_check' && req.method === 'GET') {
    try {
      const versionFile = path.join(__dirname, 'version.json');
      const versionData = JSON.parse(fs.readFileSync(versionFile, 'utf8'));

      // Wrap in Frappe's "message" key format
      const response = { message: versionData };

      // No-cache headers — critical to prevent stale version info
      res.writeHead(200, {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      });
      res.end(JSON.stringify(response));

      console.log(`[${new Date().toISOString()}] Version check served:`, versionData);
    } catch (err) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Failed to read version.json', details: err.message }));
      console.error('Error:', err.message);
    }
    return;
  }

  // ─── APK file serving ────────────────────────────────────────────────────
  // Serves versioned APK files: /files/mobile-updates/app-release-v1.0.6.apk
  if (urlPath.startsWith('/files/') && urlPath.endsWith('.apk') && req.method === 'GET') {
    const filename = path.basename(urlPath);
    const filePath = path.join(FILES_DIR, filename);

    if (!fs.existsSync(filePath)) {
      console.log(`[${new Date().toISOString()}] APK not found: ${filename}`);
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: `APK not found: ${filename}` }));
      return;
    }

    const stat = fs.statSync(filePath);
    console.log(`[${new Date().toISOString()}] Serving APK: ${filename} (${(stat.size / 1024 / 1024).toFixed(1)} MB)`);

    // No-cache headers — each versioned file is unique, but prevent CDN staleness
    res.writeHead(200, {
      'Content-Type': 'application/vnd.android.package-archive',
      'Content-Length': stat.size,
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
    });

    const readStream = fs.createReadStream(filePath);
    readStream.pipe(res);
    return;
  }

  // ─── Health check ────────────────────────────────────────────────────────
  if (urlPath === '/api/method/ping') {
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
  console.log(`📦 APK files: http://localhost:${PORT}/files/mobile-updates/app-release-v{version}.apk`);
  console.log(`\n📝 Edit server/version.json to change the response.`);
  console.log(`\n─── APK Naming Convention ───`);
  console.log(`  Place versioned APKs in this folder:`);
  console.log(`    app-release-v1.0.6.apk`);
  console.log(`    app-release-v1.0.7.apk`);
  console.log(`  Then update version.json "apk_url" accordingly.\n`);
  console.log('Scenarios you can test:');
  console.log('  1. Up to date      → latest_version matches installed, no dialog');
  console.log('  2. Optional update → latest_version > installed, force_update=false');
  console.log('  3. Force update    → installed < minimum_version OR force_update=true');
  console.log('\nWaiting for requests...\n');
});
