const puppeteer = require('C:\nvm4w\nodejs\node_modules\mcp\node_modules\puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
  const url = 'https://stitch.withgoogle.com/projects/18040412930613593715';
  const outDir = path.join(__dirname, '..', '..', 'parent_app', 'assets', 'snitch');
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

  const browser = await puppeteer.launch({ args: ['--no-sandbox','--disable-setuid-sandbox'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 900 });
  await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  await sleep(2000);

  // Save base full and mobile as previously
  await page.screenshot({ path: path.join(outDir, 'stitch_full.png'), fullPage: true });
  await page.setViewport({ width: 390, height: 844, isMobile: true });
  await page.reload({ waitUntil: 'networkidle2' });
  await page.screenshot({ path: path.join(outDir, 'stitch_mobile.png') });

  // Restore desktop viewport for captures
  await page.setViewport({ width: 1280, height: 900 });

  // Scan all frames for image URLs and links
  const frames = page.frames();
  const imageUrls = new Set();
  const linkUrls = new Set();
  for (const f of frames) {
    try {
      const imgs = await f.$$eval('img', els => els.map(e => e.src).filter(Boolean));
      imgs.forEach(u => imageUrls.add(u));
    } catch (e) {}
    try {
      const as = await f.$$eval('a', els => els.map(e => e.href).filter(Boolean));
      as.forEach(u => linkUrls.add(u));
    } catch (e) {}
  }

  console.log('Found image urls:', imageUrls.size, 'links:', linkUrls.size);

  const taken = new Set();
  let index = 1;

  // Helper to download images
  const { https, http } = require('follow-redirects');
  const download = (u, dest) => new Promise((resolve, reject) => {
    try {
      const urlObj = new URL(u);
      const mod = urlObj.protocol === 'https:' ? https : http;
      const req = mod.get(u, res => {
        if (res.statusCode !== 200) return reject(new Error('Status ' + res.statusCode));
        const file = fs.createWriteStream(dest);
        res.pipe(file);
        file.on('finish', () => file.close(resolve));
      });
      req.on('error', reject);
    } catch (err) { reject(err); }
  });

  // Download discovered images
  for (const u of imageUrls) {
    try {
      const parsed = u.split('/').pop().split('?')[0] || `image_${index}`;
      const fname = `stitch_asset_${index}_${parsed}`.replace(/[^a-z0-9._-]/ig,'_');
      const dest = path.join(outDir, fname);
      await download(u, dest);
      console.log('Downloaded', u, '->', dest);
      index++;
    } catch (e) {
      // ignore download errors
    }
  }

  // Try to visit each discovered link (limited) and capture screenshot
  const maxLinks = 40;
  let linkCount = 0;
  for (const u of linkUrls) {
    if (linkCount++ >= maxLinks) break;
    try {
      // Only capture same-origin or project related links
      if (!u.includes('stitch.withgoogle.com') && !u.includes('app-companion')) continue;
      await page.goto(u, { waitUntil: 'networkidle2', timeout: 60000 });
      await sleep(1000);
      const fname = `stitch_page_${linkCount}.png`;
      const outPath = path.join(outDir, fname);
      await page.screenshot({ path: outPath, fullPage: true });
      console.log('Captured link', u, outPath);
      // return to main project page
      await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
      await sleep(600);
    } catch (e) {
      // ignore
    }
  }

  // Additionally, attempt to click thumbnails/buttons in main frame
  const candidateHandles = await page.$$('[data-screen], img[src*="screen"], img[src*="thumbnail"], a[href*="/projects/"], button, [role="button"], [role="link"], .thumbnail, .screen, .preview');
  console.log('Found candidate elements:', candidateHandles.length);
  for (const handle of candidateHandles) {
    try {
      const box = await handle.boundingBox();
      if (!box || box.width < 40 || box.height < 40) continue;
      // get a short id/title for filename
      const desc = await page.evaluate(el => {
        return (el.getAttribute('aria-label') || el.getAttribute('alt') || el.getAttribute('title') || el.textContent || '').trim().slice(0,60).replace(/[^a-z0-9\-\_ ]/ig,'').replace(/\s+/g,'_') || 'screen';
      }, handle);
      const filenameBase = `stitch_capture_${index}_${desc}`;
      if (taken.has(filenameBase)) { index++; continue; }
      // Try click and capture
      try {
        await handle.click({ delay: 100 });
      } catch (err) {
        // fallback to evaluate click
        await page.evaluate(el => el.click(), handle);
      }
      // Wait for UI to update
      await sleep(1200);
      const outPath = path.join(outDir, `${filenameBase}.png`);
      await page.screenshot({ path: outPath, fullPage: true });
      console.log('Captured', outPath);
      taken.add(filenameBase);
      index++;
      // Reload base page to restore state
      await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
      await sleep(800);
    } catch (err) {
      // ignore errors and continue
      // console.error('error capturing element', err);
    }
  }

  await browser.close();
  console.log('Done capturing. Files in', outDir);
})();
