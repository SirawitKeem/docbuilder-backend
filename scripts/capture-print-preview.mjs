import puppeteer from "puppeteer";
import fs from "fs";

async function capture() {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 794, height: 1123, deviceScaleFactor: 2 });
  await page.goto("http://localhost:3000/print/tmpl-recovery-advisor-studio", {
    waitUntil: "networkidle0",
  });
  await page.waitForSelector("[data-ready='true']", { timeout: 15000 });
  await new Promise((r) => setTimeout(r, 500));

  await page.screenshot({ path: "public/fabric_studio_page_preview.png" });
  fs.copyFileSync(
    "public/fabric_studio_page_preview.png",
    "C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/fabric_studio_page_preview.png"
  );
  await browser.close();
  console.log("Captured fabric_studio_page_preview.png successfully!");
}

capture().catch(console.error);
