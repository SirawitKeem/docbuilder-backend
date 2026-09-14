import puppeteer from "puppeteer";

async function runE2ETests() {
  console.log("=================================================");
  console.log("🎯 RUNNING E2E UI & REGRESSION VERIFICATION");
  console.log("=================================================");

  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });

  // -------------------------------------------------------------
  // TEST 1: Slide Template Editor (/templates/new?editorType=slide)
  // -------------------------------------------------------------
  console.log("\n[Test 1] Checking Slide Editor TopToolbar...");
  await page.goto("http://localhost:3000/templates/new?categoryId=notification&editorType=slide&canvasPreset=slide-16-9", {
    waitUntil: "networkidle0",
  });

  // Check if "ดาวน์โหลด .pptx" button exists
  const pptxButton = await page.evaluate(() => {
    const buttons = Array.from(document.querySelectorAll("button"));
    const btn = buttons.find((b) => b.textContent && b.textContent.includes("ดาวน์โหลด .pptx"));
    return btn ? { text: btn.textContent.trim(), exists: true } : { exists: false };
  });

  console.log("Slide Editor - 'ดาวน์โหลด .pptx' button found:", pptxButton.exists, pptxButton.text || "");
  if (!pptxButton.exists) {
    throw new Error("FAILED: 'ดาวน์โหลด .pptx' button missing in Slide Editor!");
  }

  // -------------------------------------------------------------
  // TEST 2: Document Template Editor (/templates/new?editorType=document)
  // -------------------------------------------------------------
  console.log("\n[Test 2] Checking Document Editor TopToolbar for zero pollution...");
  await page.goto("http://localhost:3000/templates/new?categoryId=notification&editorType=document&canvasPreset=a4-portrait", {
    waitUntil: "networkidle0",
  });

  const pptxButtonInDocs = await page.evaluate(() => {
    const buttons = Array.from(document.querySelectorAll("button"));
    const btn = buttons.find((b) => b.textContent && b.textContent.includes("ดาวน์โหลด .pptx"));
    return btn ? true : false;
  });

  console.log("Document Editor - 'ดาวน์โหลด .pptx' button present (should be false):", pptxButtonInDocs);
  if (pptxButtonInDocs) {
    throw new Error("FAILED: 'ดาวน์โหลด .pptx' button leaked into Document Editor!");
  }

  // -------------------------------------------------------------
  // TEST 3: Original Quotation Document Editor (/create/quotation)
  // -------------------------------------------------------------
  console.log("\n[Test 3] Checking Quotation Document Creation (/create/quotation)...");
  await page.goto("http://localhost:3000/create/quotation", {
    waitUntil: "networkidle0",
  });

  // Wait for ProfileSelectGate to finish loading profiles
  await page.waitForFunction(() => {
    const text = document.body.innerText;
    return text.includes("เริ่มจากเอกสารเปล่า") || text.includes("เลือกชุดข้อมูล");
  }, { timeout: 15000 });

  // Click "เลือกเอกสารเปล่า" to enter editor
  await page.evaluate(() => {
    const buttons = Array.from(document.querySelectorAll("button, div, span"));
    const blankBtn = buttons.find((el) => el.textContent && el.textContent.trim() === "เลือกเอกสารเปล่า");
    if (blankBtn) {
      blankBtn.click();
    } else {
      const card = buttons.find((el) => el.textContent && el.textContent.includes("เริ่มจากเอกสารเปล่า"));
      if (card) card.click();
    }
  });

  // Wait for EditorToolbar to mount with Export PDF button
  await page.waitForFunction(() => {
    const buttons = Array.from(document.querySelectorAll("button"));
    return buttons.some((b) => b.textContent && (b.textContent.includes("Export PDF") || b.textContent.includes("ส่งออก PDF")));
  }, { timeout: 15000 });

  const pdfExportBtn = await page.evaluate(() => {
    const buttons = Array.from(document.querySelectorAll("button"));
    const btn = buttons.find((b) => b.textContent && (b.textContent.includes("Export PDF") || b.textContent.includes("ส่งออก PDF")));
    return btn ? { text: btn.textContent.trim(), exists: true } : { exists: false };
  });

  console.log("Quotation Editor - 'Export PDF' button found:", pdfExportBtn.exists, pdfExportBtn.text || "");
  if (!pdfExportBtn.exists) {
    throw new Error("FAILED: 'Export PDF' button missing or broken in /create/quotation!");
  }

  await browser.close();

  console.log("\n=================================================");
  console.log("🎉 ALL E2E & REGRESSION TESTS PASSED 100%!");
  console.log("=================================================");
}

runE2ETests().catch((err) => {
  console.error("E2E Test Error:", err);
  process.exit(1);
});
