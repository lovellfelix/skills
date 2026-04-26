#!/usr/bin/env node
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT ? Number(process.env.PORT) : 4040;
const ROOT = process.cwd();

function serveJSON(res, file) {
  const p = path.join(ROOT, file);
  if (!fs.existsSync(p)) {
    res.writeHead(404, {'Content-Type':'application/json'});
    res.end(JSON.stringify({ error: 'not found' }));
    return;
  }
  try {
    const body = fs.readFileSync(p, 'utf8');
    res.writeHead(200, {'Content-Type':'application/json'});
    res.end(body);
  } catch (e) {
    res.writeHead(500, {'Content-Type':'application/json'});
    res.end(JSON.stringify({ error: e.message }));
  }
}

const server = http.createServer((req, res) => {
  if (req.url === '/' || req.url === '/.mcp') {
    serveJSON(res, '.mcp/manifest.json');
    return;
  }
  if (req.url === '/.mcp/index.json') {
    serveJSON(res, '.mcp/index.json');
    return;
  }
  if (req.url === '/.mcp/manifest.json') {
    serveJSON(res, '.mcp/manifest.json');
    return;
  }
  res.writeHead(404, {'Content-Type':'text/plain'});
  res.end('Not found');
});

server.listen(PORT, () => {
  console.log(`KB MCP server running on http://localhost:${PORT}/.mcp/manifest.json`);
});
