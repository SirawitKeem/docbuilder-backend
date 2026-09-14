import puppeteer from "puppeteer";
import fs from "fs";

async function captureScreenshots() {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });

  // 1. Slide Editor Screenshot
  await page.goto("http://localhost:3000/templates/new?categoryId=notification&editorType=slide&canvasPreset=slide-16-9", {
    waitUntil: "networkidle0",
  });
  await new Promise((r) => setTimeout(r, 1000));
  await page.screenshot({ path: "public/screenshot_slide_toolbar_pptx.png" });
  fs.copyFileSync(
    "public/screenshot_slide_toolbar_pptx.png",
    "C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/screenshot_slide_toolbar_pptx.png"
  );
  console.log("Captured screenshot_slide_toolbar_pptx.png");

  // 2. Document Editor Screenshot (Docs zero leakage)
  await page.goto("http://localhost:3000/templates/new?categoryId=notification&editorType=document&canvasPreset=a4-portrait", {
    waitUntil: "networkidle0",
  });
  await new Promise((r) => setTimeout(r, 1000));
  await page.screenshot({ path: "public/screenshot_doc_toolbar_clean.png" });
  fs.copyFileSync(
    "public/screenshot_doc_toolbar_clean.png",
    "C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/screenshot_doc_toolbar_clean.png"
  );
  console.log("Captured screenshot_doc_toolbar_clean.png");

  // 3. Quotation Editor with Export PDF button
  await page.goto("http://localhost:3000/create/quotation", {
    waitUntil: "networkidle0",
  });
  await page.waitForFunction(() => {
    const text = document.body.innerText;
    return text.includes("เริ่มจากเอกสารเปล่า") || text.includes("เลือกชุดข้อมูล");
  }, { timeout: 15000 });

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

  await page.waitForFunction(() => {
    const buttons = Array.from(document.querySelectorAll("button"));
    return buttons.some((b) => b.textContent && b.textContent.includes("Export PDF"));
  }, { timeout: 15000 });

  await new Promise((r) => setTimeout(r, 1000));
  await page.screenshot({ path: "public/screenshot_quotation_export_pdf.png" });
  fs.copyFileSync(
    "public/screenshot_quotation_export_pdf.png",
    "C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/screenshot_quotation_export_pdf.png"
  );
  console.log("Captured screenshot_quotation_export_pdf.png");

  await browser.close();
  console.log("All screenshots captured successfully!");
}

captureScreenshots().catch(console.error);
