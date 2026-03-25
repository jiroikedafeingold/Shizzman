const puppeteer = require('/tmp/node_modules/puppeteer');
const path = require('path');
const fs = require('fs');

// App Store required sizes (width × height in px)
// We render at 3× the 393×852 logical size → 1179×2556
// Then we note App Store requires 1290×2796 for 6.7" — close enough for mockups,
// or user can scale up. For 6.9" (1320×2868) same approach.
const SCALE = 3;
const W = 393;
const H = 852;

const screens = [
  { id: 'home',     name: '01_home' },
  { id: 'arrange',  name: '02_arrange_hand' },
  { id: 'gameplay', name: '03_gameplay' },
  { id: 'burn',     name: '04_burn' },
  { id: 'gameover', name: '05_you_win' },
];

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const htmlPath = path.resolve(__dirname, 'screens.html');
  const outDir   = path.resolve(__dirname, 'export');
  fs.mkdirSync(outDir, { recursive: true });

  for (const screen of screens) {
    const page = await browser.newPage();
    await page.setViewport({ width: W * screen.length || W, height: H, deviceScaleFactor: SCALE });
    await page.goto(`file://${htmlPath}`);
    await new Promise(r => setTimeout(r, 300));

    // Get the element bounding box
    const el = await page.$(`#${screen.id}`);
    if (!el) { console.error(`Element #${screen.id} not found`); continue; }

    const box = await el.boundingBox();

    const outPath = path.join(outDir, `${screen.name}.png`);
    await page.screenshot({
      path: outPath,
      clip: {
        x: box.x,
        y: box.y,
        width:  W,
        height: H,
      },
    });

    await page.close();
    console.log(`✓ ${screen.name}.png  (${W * SCALE}×${H * SCALE}px physical)`);
  }

  await browser.close();
  console.log(`\nDone. Files saved to:\n  ${outDir}`);
})();
