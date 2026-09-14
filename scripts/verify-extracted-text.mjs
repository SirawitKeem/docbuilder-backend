import puppeteer from "puppeteer";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function verifyPdfTextExtraction() {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-gpu"],
  });

  const page = await browser.newPage();
  
  // Open the generated PDF in chromium viewer to extract text
  const pdfPath = "file:///" + path.join(__dirname, "test-production-sample.pdf").replace(/\\/g, "/");
  await page.goto(pdfPath, { waitUntil: "networkidle0" });

  const extractedText = await page.evaluate(() => {
    return document.body.innerText;
  });

  console.log("Extracted Text from PDF Viewer:\n", extractedText);
  await browser.close();
}

verifyPdfTextExtraction().catch(console.error);