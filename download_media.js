const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const url = require('url');

const pagesDir = String.raw`C:\Users\User\Documents\Antigravity\pinelaki-content-backup\pages`;
const mediaDir = String.raw`C:\Users\User\Documents\Antigravity\pinelaki-content-backup\media`;
const mapFile  = String.raw`C:\Users\User\Documents\Antigravity\pinelaki-content-backup\media-map.json`;

fs.mkdirSync(mediaDir, { recursive: true });

const wpPat = /https?:\/\/(?:www\.)?pinelaki\.com\/wp-content\/uploads\/[^\s)"'\]]+/g;

const mediaMap = {};
const allImages = new Map(); // url -> localAbs

const mdFiles = fs.readdirSync(pagesDir).filter(f => f.endsWith('.md'));
console.log(`Processing ${mdFiles.length} pages...`);

for (const fname of mdFiles) {
  const content = fs.readFileSync(path.join(pagesDir, fname), 'utf8');
  const m = content.match(/^url: (.+)/m);
  const pageUrl = m ? m[1].trim() : '';

  const matches = [...content.matchAll(new RegExp(wpPat.source, 'g'))];
  const urls = [...new Set(matches.map(m => m[0].replace(/[)"'\]\s]+$/, '')))];

  const pageImages = [];
  for (const imgUrl of urls) {
    try {
      const parsed = new url.URL(imgUrl);
      const rel = parsed.pathname.replace(/^\//, ''); // wp-content/uploads/...
      const safe = rel.replace(/[\\:*?<>|]/g, '_');
      const localAbs = path.join(mediaDir, ...safe.split('/'));
      pageImages.push({ url: imgUrl, localPath: 'media/' + safe });
      if (!allImages.has(imgUrl)) allImages.set(imgUrl, localAbs);
    } catch (e) {}
  }

  if (pageImages.length && pageUrl) {
    mediaMap[pageUrl] = pageImages;
  }
}

console.log(`Found ${allImages.size} unique images total`);

const headers = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
  'Accept-Language': 'en-US,en;q=0.9',
  'Referer': 'https://pinelaki.com/',
};

function download(imgUrl, dest) {
  return new Promise((resolve) => {
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    const parsed = new url.URL(imgUrl);
    const lib = parsed.protocol === 'https:' ? https : http;
    const req = lib.get(imgUrl, { headers, timeout: 30000 }, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        // follow redirect
        return download(res.headers.location, dest).then(resolve);
      }
      if (res.statusCode !== 200) {
        res.resume();
        return resolve({ ok: false, status: res.statusCode });
      }
      const out = fs.createWriteStream(dest);
      res.pipe(out);
      out.on('finish', () => resolve({ ok: true }));
      out.on('error', (e) => resolve({ ok: false, err: e.message }));
    });
    req.on('error', (e) => resolve({ ok: false, err: e.message }));
    req.on('timeout', () => { req.destroy(); resolve({ ok: false, err: 'timeout' }); });
  });
}

async function main() {
  let ok = 0, fail = 0, i = 0;
  const entries = [...allImages.entries()];

  for (const [imgUrl, localAbs] of entries) {
    i++;
    const fname = path.basename(imgUrl);
    const result = await download(imgUrl, localAbs);
    if (result.ok) {
      ok++;
      process.stdout.write(`  [${i}/${entries.length}] OK   ${fname}\n`);
    } else {
      fail++;
      process.stdout.write(`  [${i}/${entries.length}] ERR  ${fname} -- ${result.status || result.err}\n`);
    }
    await new Promise(r => setTimeout(r, 100));
  }

  fs.writeFileSync(mapFile, JSON.stringify(mediaMap, null, 2), 'utf8');

  console.log(`\n=== Done ===`);
  console.log(`Unique images    : ${entries.length}`);
  console.log(`Downloaded OK    : ${ok}`);
  console.log(`Failed           : ${fail}`);
  console.log(`Media map saved  : ${mapFile}`);
}

main().catch(console.error);
