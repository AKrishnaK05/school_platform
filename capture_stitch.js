const puppeteer = require('C:\\nvm4w\\nodejs\\node_modules\\mcp\\node_modules\\puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
  const url = 'https://stitch.withgoogle.com/projects/18040412930613593715';
  const outDir = path.join(__dirname, 'parent_app', 'assets', 'snitch');
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

  const browser = await puppeteer.launch({ args: ['--no-sandbox','--disable-setuid-sandbox'] });
  const page = await browser.newPage();

  // full page screenshot
  await page.setViewport({ width: 1280, height: 900 });
  await page.goto(url, { waitUntil: 'networkidle2', timeout: 60000 });
  await page.screenshot({ path: path.join(outDir, 'stitch_full.png'), fullPage: true });

  // mobile viewport screenshot
  await page.setViewport({ width: 390, height: 844, isMobile: true });
  await page.reload({ waitUntil: 'networkidle2', timeout: 60000 });
  await page.screenshot({ path: path.join(outDir, 'stitch_mobile.png'), fullPage: false });

  await browser.close();
  console.log('Screenshots saved to', outDir);
})();
