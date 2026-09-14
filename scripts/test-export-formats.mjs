import puppeteer from 'puppeteer';
import fs from 'fs';

async function testExportFormats() {
  console.log("Testing WebP and HTML generation...");
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 794, height: 1123, deviceScaleFactor: 2 });
  
  await page.goto('http://localhost:3000/print/notification', { waitUntil: 'networkidle0' });
  await page.waitForSelector('[data-ready="true"]', { timeout: 15000 });

  // 1. Test WebP
  const printRoot = await page.$('#print-root');
  const webpBuffer = await printRoot.screenshot({ type: 'webp', quality: 95 });
  fs.writeFileSync('C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/scratch/test_export.webp', webpBuffer);
  console.log("✓ WebP generated, size:", webpBuffer.length, "bytes");

  // 2. Test HTML
  const htmlContent = await page.content();
  fs.writeFileSync('C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/scratch/test_export.html', htmlContent);
  console.log("✓ HTML generated, size:", htmlContent.length, "bytes");

  await browser.close();
}

testExportFormats().catch(console.error);
