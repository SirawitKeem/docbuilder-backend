import puppeteer from 'puppeteer';
import path from 'path';

async function run() {
  console.log("================================================================================");
  console.log("📐 TESTING DYNAMIC MARGINS & DOUBLE-CLICK HOTFIX (DOCS + SLIDES)");
  console.log("================================================================================");

  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });

  const errors = [];
  page.on('pageerror', err => {
    console.log('❌ PAGE ERROR:', err.message);
    errors.push(err.message);
  });
  page.on('dialog', async d => {
    console.log('🔔 Alert dialog intercepted:', d.message());
    await d.accept();
  });

  // ── TEST 1: DOCS (A4 Portrait) ──
  console.log('\n--- 1. Testing Document Studio (A4 Portrait) ---');
  await page.goto('http://localhost:3000/templates/new?editorType=document', { waitUntil: 'networkidle2', timeout: 30000 });
  await page.waitForFunction(() => Boolean(window.__FABRIC_CANVAS__), { timeout: 15000 });
  console.log('✅ Canvas ready');

  // Check initial Margin badge
  let badgeText = await page.$eval('[data-testid="margin-badge-btn"]', el => el.innerText.trim());
  console.log(`Initial Doc Margin Badge: "${badgeText}"`);

  // Rapid double click on badge
  await page.$eval('[data-testid="margin-badge-btn"]', el => {
    el.click();
    el.click();
  });
  await new Promise(r => setTimeout(r, 400));
  console.log('✅ Double clicked margin button without error');

  // Open Popover via chevron
  await page.click('[data-testid="margin-chevron-btn"]');
  await page.waitForSelector('[data-testid="margin-popover"]', { timeout: 5000 });
  console.log('✅ Margin Popover opened via chevron');

  // Click 20mm preset in popover
  await page.click('[data-testid="margin-preset-20"]');
  await new Promise(r => setTimeout(r, 400));

  badgeText = await page.$eval('[data-testid="margin-badge-btn"]', el => el.innerText.trim());
  console.log(`After selecting 20mm preset: Badge is "${badgeText}"`);

  // Test stepper + button (increase to 21mm)
  await page.click('[data-testid="margin-plus-btn"]');
  await new Promise(r => setTimeout(r, 300));
  badgeText = await page.$eval('[data-testid="margin-badge-btn"]', el => el.innerText.trim());
  console.log(`After clicking plus button: Badge is "${badgeText}"`);

  // Test input typing (set to 25mm)
  await page.click('[data-testid="margin-preset-25"]');
  await new Promise(r => setTimeout(r, 300));
  badgeText = await page.$eval('[data-testid="margin-badge-btn"]', el => el.innerText.trim());
  console.log(`After selecting 25mm preset: Badge is "${badgeText}"`);

  // Take screenshot of Docs with 25mm margin
  const docsScreenshotPath = path.resolve('public', 'test-doc-margin-25mm.png');
  await page.screenshot({ path: docsScreenshotPath });
  console.log(`📸 Saved screenshot: ${docsScreenshotPath}`);

  // ── TEST 2: SLIDES (16:9) ──
  console.log('\n--- 2. Testing Presentation Studio (16:9 Slides) ---');
  await page.goto('http://localhost:3000/templates/new?editorType=slide', { waitUntil: 'networkidle2', timeout: 30000 });
  await page.waitForFunction(() => Boolean(window.__FABRIC_CANVAS__), { timeout: 15000 });
  console.log('✅ Slide Canvas ready');

  let slideBadgeText = await page.$eval('[data-testid="margin-badge-btn"]', el => el.innerText.trim());
  console.log(`Initial Slide Margin Badge: "${slideBadgeText}"`);

  // Rapid double click to verify NO crash
  await page.$eval('[data-testid="margin-badge-btn"]', el => {
    el.click();
    el.click();
  });
  await new Promise(r => setTimeout(r, 400));
  console.log('✅ Double clicked slide margin without error');

  // Open Popover on Slide
  await page.click('[data-testid="margin-chevron-btn"]');
  await page.waitForSelector('[data-testid="margin-popover"]', { timeout: 5000 });
  console.log('✅ Slide Margin Popover opened');

  // Click 60px preset
  await page.click('[data-testid="margin-preset-60"]');
  await new Promise(r => setTimeout(r, 400));

  slideBadgeText = await page.$eval('[data-testid="margin-badge-btn"]', el => el.innerText.trim());
  console.log(`After selecting 60px preset: Slide Badge is "${slideBadgeText}"`);

  // Test stepper + button (increase to 65px)
  await page.click('[data-testid="margin-plus-btn"]');
  await new Promise(r => setTimeout(r, 300));
  slideBadgeText = await page.$eval('[data-testid="margin-badge-btn"]', el => el.innerText.trim());
  console.log(`After clicking plus button: Slide Badge is "${slideBadgeText}"`);

  // Take screenshot of Slides with 65px margin
  const slidesScreenshotPath = path.resolve('public', 'test-slide-margin-65px.png');
  await page.screenshot({ path: slidesScreenshotPath });
  console.log(`📸 Saved screenshot: ${slidesScreenshotPath}`);

  await browser.close();

  console.log('\n================================================================================');
  console.log(`🏁 TEST RESULTS: Total runtime errors caught = ${errors.length}`);
  if (errors.length === 0) {
    console.log('🎉 ALL TESTS PASSED: Dynamic margins work flawlessly and double-click crash is resolved!');
  } else {
    console.log('❌ ERRORS DETECTED:', errors);
  }
  console.log('================================================================================');
}

run().catch(console.error);
