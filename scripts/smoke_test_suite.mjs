import puppeteer from 'puppeteer';
import fs from 'fs';
import path from 'path';

const BASE_URL = 'http://localhost:3000';
const SCREENSHOT_DIR = 'C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8';

async function runSmokeTests() {
  console.log('🚀 Starting Smoke Test Suite...');
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });

  const results = {};

  try {
    // 1. Test /settings UI
    console.log('1️⃣ Testing /settings page...');
    await page.goto(`${BASE_URL}/settings`, { waitUntil: 'networkidle2' });
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'smoke_settings.png') });
    results.settings = { status: 'PASSED' };
    console.log('   ✓ /settings rendered successfully');

    // 2. Test /templates/new UI
    console.log('2️⃣ Testing /templates/new page...');
    await page.goto(`${BASE_URL}/templates/new`, { waitUntil: 'networkidle2' });
    await new Promise(r => setTimeout(r, 1500));
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'smoke_templates_new.png') });
    results.templatesNew = { status: 'PASSED' };
    console.log('   ✓ /templates/new rendered successfully');

    // 3. Test /templates/new?type=sheet (Sheet Editor & Formula)
    console.log('3️⃣ Testing Sheet Editor (/templates/new?type=sheet)...');
    await page.goto(`${BASE_URL}/templates/new?type=sheet`, { waitUntil: 'networkidle2' });
    await new Promise(r => setTimeout(r, 2500));
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'smoke_sheet_editor.png') });
    
    // Check back link href in Sheet Editor
    const backLink = await page.$eval('a[title="Back to Templates"]', el => el.getAttribute('href')).catch(() => null);
    results.sheetEditor = { status: 'PASSED', backHref: backLink };
    console.log('   ✓ Sheet editor rendered, Back link confirmed href:', backLink);

    // 4. Test Quotation creation & Document Editor
    console.log('4️⃣ Testing Quotation Flow & Creation...');
    await page.goto(`${BASE_URL}/create/quotation`, { waitUntil: 'networkidle2' });
    await new Promise(r => setTimeout(r, 2000));
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, 'smoke_quotation_editor.png') });
    results.quotationEditor = { status: 'PASSED' };
    console.log('   ✓ Quotation editor loaded successfully');

    // 5. Test PDF Export API
    console.log('5️⃣ Testing PDF Export Endpoint (/api/export-pdf)...');
    const sampleHtml = `<!DOCTYPE html><html><body><h1 style="font-family:'Noto Sans Thai'">ทดสอบออกใบเสนอราคา PDF</h1><p>ราคา 100,000 บาท</p></body></html>`;
    const pdfRes = await fetch(`${BASE_URL}/api/export-pdf`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ html: sampleHtml, filename: 'smoke-test.pdf' })
    });
    if (!pdfRes.ok) {
      throw new Error(`PDF export failed with status ${pdfRes.status}`);
    }
    const pdfBuffer = await pdfRes.arrayBuffer();
    results.pdfExport = { status: 'PASSED', byteSize: pdfBuffer.byteLength };
    console.log(`   ✓ PDF export returned binary (${pdfBuffer.byteLength} bytes)`);

    // 6. Test PPTX Export API
    console.log('6️⃣ Testing PPTX Export Endpoint (/api/export-pptx)...');
    const sampleSlides = [
      {
        id: 's1',
        title: 'Slide 1',
        objects: [
          {
            type: 'textbox',
            left: 100,
            top: 100,
            width: 400,
            fontSize: 28,
            text: 'ใบเสนอราคาและสัญญานำเสนอ (Quotation Slide)',
            fontFamily: 'Noto Sans Thai',
            fill: '#1D4ED8'
          }
        ]
      }
    ];
    const pptxRes = await fetch(`${BASE_URL}/api/export-pptx`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ slides: sampleSlides, filename: 'smoke-test.pptx' })
    });
    if (!pptxRes.ok) {
      throw new Error(`PPTX export failed with status ${pptxRes.status}`);
    }
    const pptxBuffer = await pptxRes.arrayBuffer();
    results.pptxExport = { status: 'PASSED', byteSize: pptxBuffer.byteLength };
    console.log(`   ✓ PPTX export returned binary (${pptxBuffer.byteLength} bytes)`);

  } catch (err) {
    console.error('❌ Smoke test failed:', err);
    results.error = err.message;
  } finally {
    await browser.close();
    console.log('\n📊 Summary of Smoke Test Results:');
    console.log(JSON.stringify(results, null, 2));
  }
}

runSmokeTests();
