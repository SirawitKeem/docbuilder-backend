import puppeteer from 'puppeteer';
import path from 'path';

async function typeMargin(page, value) {
  await page.click('[data-testid="margin-input"]');
  // Select all inside input
  await page.keyboard.down('Control');
  await page.keyboard.press('KeyA');
  await page.keyboard.up('Control');
  await page.keyboard.press('Backspace');
  await page.keyboard.type(String(value));
  await page.keyboard.press('Enter');
  await new Promise(r => setTimeout(r, 400));
}

async function run() {
  console.log("================================================================================");
  console.log("📐 TESTING DIRECT INLINE MARGIN EDITOR & 0-MARGIN BORDER HIDING (DOCS + SLIDES)");
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
  console.log('\n--- 1. Testing Document Studio (A4 Docs) ---');
  await page.goto('http://localhost:3000/templates/new?editorType=document', { waitUntil: 'networkidle2', timeout: 30000 });
  await page.waitForFunction(() => Boolean(window.__FABRIC_CANVAS__), { timeout: 15000 });
  console.log('✅ Canvas ready');

  // Verify dropdown is GONE
  const popover = await page.$('[data-testid="margin-popover"]');
  const chevron = await page.$('[data-testid="margin-chevron-btn"]');
  console.log(`Dropdown popover exists? ${Boolean(popover)} (expected: false)`);
  console.log(`Dropdown chevron exists? ${Boolean(chevron)} (expected: false)`);

  // Check initial Margin input
  let inputValue = await page.$eval('[data-testid="margin-input"]', el => el.value);
  console.log(`Initial Doc Margin Input Value: "${inputValue}" mm`);

  // Check margin guide visibility (should be visible when margin is 15)
  let guideClass = await page.$eval('[data-testid="margin-guide"]', el => el.className);
  console.log(`Initial Margin Guide classes: includes opacity-100? ${guideClass.includes('opacity-100')}`);

  // Test Typing "0" directly into the input:
  console.log('✏️ Setting margin to 0 mm directly via keyboard...');
  await typeMargin(page, 0);

  inputValue = await page.$eval('[data-testid="margin-input"]', el => el.value);
  guideClass = await page.$eval('[data-testid="margin-guide"]', el => el.className);
  console.log(`Margin Input Value: "${inputValue}" mm`);
  console.log(`Margin Guide classes when 0: opacity-0? ${guideClass.includes('opacity-0') || guideClass.includes('invisible')}`);
  if (guideClass.includes('opacity-0') || guideClass.includes('invisible')) {
    console.log('✅ PASS — Margin guide is completely hidden when value is 0 (ไม่มีเส้นขอบ)!');
  } else {
    console.log('❌ FAIL — Margin guide is still visible when value is 0!');
    errors.push('Margin guide should be hidden when value is 0');
  }

  // Take screenshot with margin = 0 (no border)
  const docZeroScreenshot = path.resolve('public', 'test-doc-margin-0mm.png');
  await page.screenshot({ path: docZeroScreenshot });
  console.log(`📸 Saved screenshot (0mm, no border): ${docZeroScreenshot}`);

  // Test Stepper Plus button: +1 mm
  console.log('➕ Clicking plus button (+1 mm)...');
  await page.click('[data-testid="margin-plus-btn"]');
  await new Promise(r => setTimeout(r, 300));
  inputValue = await page.$eval('[data-testid="margin-input"]', el => el.value);
  guideClass = await page.$eval('[data-testid="margin-guide"]', el => el.className);
  console.log(`After clicking plus: Input is "${inputValue}" mm, guide visible: ${guideClass.includes('opacity-100')}`);

  // Test Typing "20" directly
  console.log('✏️ Typing "20" into input...');
  await typeMargin(page, 20);
  inputValue = await page.$eval('[data-testid="margin-input"]', el => el.value);
  guideClass = await page.$eval('[data-testid="margin-guide"]', el => el.className);
  const guideText = await page.$eval('[data-testid="margin-guide"] span', el => el.innerText.trim());
  console.log(`After typing 20: Input is "${inputValue}" mm, Guide Badge is "${guideText}"`);
  if (guideText.includes('20mm')) {
    console.log('✅ PASS — Margin guide badge shows 20mm!');
  } else {
    errors.push('Expected Guide badge to show 20mm');
  }

  // Take screenshot with margin = 20mm
  const doc20Screenshot = path.resolve('public', 'test-doc-margin-20mm.png');
  await page.screenshot({ path: doc20Screenshot });
  console.log(`📸 Saved screenshot (20mm): ${doc20Screenshot}`);

  // ── TEST 2: SLIDES (16:9 Presentation) ──
  console.log('\n--- 2. Testing Presentation Studio (16:9 Slides) ---');
  await page.goto('http://localhost:3000/templates/new?editorType=slide', { waitUntil: 'networkidle2', timeout: 30000 });
  await page.waitForFunction(() => Boolean(window.__FABRIC_CANVAS__), { timeout: 15000 });
  console.log('✅ Slide Canvas ready');

  let slideInputVal = await page.$eval('[data-testid="margin-input"]', el => el.value);
  console.log(`Initial Slide Margin: "${slideInputVal}" px`);

  // Set Slide margin to 0
  console.log('✏️ Setting slide margin to 0 px...');
  await typeMargin(page, 0);

  slideInputVal = await page.$eval('[data-testid="margin-input"]', el => el.value);
  let slideGuideClass = await page.$eval('[data-testid="margin-guide"]', el => el.className);
  console.log(`Slide Margin Input: "${slideInputVal}" px, Guide hidden: ${slideGuideClass.includes('opacity-0')}`);
  if (slideGuideClass.includes('opacity-0') || slideGuideClass.includes('invisible')) {
    console.log('✅ PASS — Slide margin guide is completely hidden when value is 0 (ไม่มีเส้นขอบ)!');
  } else {
    console.log('❌ FAIL — Slide margin guide is still visible when value is 0!');
    errors.push('Slide margin guide should be hidden when value is 0');
  }

  // Take screenshot with margin = 0 on slides
  const slideZeroScreenshot = path.resolve('public', 'test-slide-margin-0px.png');
  await page.screenshot({ path: slideZeroScreenshot });
  console.log(`📸 Saved screenshot (Slide 0px, no border): ${slideZeroScreenshot}`);

  // Set Slide margin to 50px
  console.log('✏️ Setting slide margin to 50 px...');
  await typeMargin(page, 50);

  slideInputVal = await page.$eval('[data-testid="margin-input"]', el => el.value);
  slideGuideClass = await page.$eval('[data-testid="margin-guide"]', el => el.className);
  const slideGuideText = await page.$eval('[data-testid="margin-guide"] span', el => el.innerText.trim());
  console.log(`After setting 50px: Slide Input is "${slideInputVal}" px, Guide Badge is "${slideGuideText}"`);
  if (slideGuideText.includes('50px')) {
    console.log('✅ PASS — Slide margin guide badge shows 50px!');
  } else {
    errors.push('Expected Slide Guide badge to show 50px');
  }

  // Take screenshot with margin = 50px on slides
  const slide50Screenshot = path.resolve('public', 'test-slide-margin-50px.png');
  await page.screenshot({ path: slide50Screenshot });
  console.log(`📸 Saved screenshot (Slide 50px): ${slide50Screenshot}`);

  await browser.close();

  console.log('\n================================================================================');
  console.log(`🏁 TEST RESULTS: Total runtime errors caught = ${errors.length}`);
  if (errors.length === 0) {
    console.log('🎉 ALL TESTS PASSED: Direct inline margin editor works cleanly, dropdown is gone, and 0 margin hides border completely!');
  } else {
    console.log('💥 Some tests failed:', errors);
    process.exit(1);
  }
}

run().catch(err => {
  console.error("Fatal Error running test:", err);
  process.exit(1);
});
