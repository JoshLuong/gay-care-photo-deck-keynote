const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFile } = require('child_process');

const PORT = 7890;

function parseMultipart(buffer, boundary) {
  const parts = [];
  const sep = Buffer.from('--' + boundary);
  const end = Buffer.from('--' + boundary + '--');
  let start = 0;

  while (start < buffer.length) {
    const sepIdx = buffer.indexOf(sep, start);
    if (sepIdx === -1) break;
    const headerStart = sepIdx + sep.length + 2;
    const headerEnd = buffer.indexOf(Buffer.from('\r\n\r\n'), headerStart);
    if (headerEnd === -1) break;
    const header = buffer.slice(headerStart, headerEnd).toString();
    const bodyStart = headerEnd + 4;
    const nextSep = buffer.indexOf(sep, bodyStart);
    const bodyEnd = nextSep === -1 ? buffer.length : nextSep - 2;
    const nameMatch = header.match(/name="([^"]+)"/);
    const fileMatch = header.match(/filename="([^"]+)"/);
    if (nameMatch && fileMatch) {
      parts.push({ name: nameMatch[1], filename: fileMatch[1], data: buffer.slice(bodyStart, bodyEnd) });
    }
    start = nextSep === -1 ? buffer.length : nextSep;
  }
  return parts;
}

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  if (req.method !== 'POST' || req.url !== '/build') {
    res.writeHead(404);
    res.end();
    return;
  }

  const chunks = [];
  req.on('data', chunk => chunks.push(chunk));
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    const contentType = req.headers['content-type'] || '';
    const boundaryMatch = contentType.match(/boundary=(.+)/);
    if (!boundaryMatch) {
      res.writeHead(400);
      res.end('Missing boundary');
      return;
    }

    const parts = parseMultipart(body, boundaryMatch[1]);
    if (parts.length === 0) {
      res.writeHead(400);
      res.end('No files');
      return;
    }

    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'photodeck-'));
    const folderName = parts[0].filename.split('/')[0] || 'deck';
    const outPath = path.join(os.homedir(), 'Desktop', folderName + '.key');

    for (const part of parts) {
      const filename = path.basename(part.filename);
      fs.writeFileSync(path.join(tmpDir, filename), part.data);
    }

    const scriptPath = path.join(path.dirname(process.execPath), '..', 'Resources', 'build_photo_deck.applescript');

    execFile('osascript', [scriptPath, tmpDir, outPath], (err, stdout, stderr) => {
      fs.rmSync(tmpDir, { recursive: true, force: true });

      if (err) {
        res.writeHead(500);
        res.end('Error: ' + (stderr || err.message));
        return;
      }

      const keyData = fs.readFileSync(outPath);
      res.writeHead(200, {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': `attachment; filename="${folderName}.key"`,
        'Content-Length': keyData.length,
      });
      res.end(keyData);
    });
  });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`PhotoDeck server running on http://127.0.0.1:${PORT}`);
});
