import puppeteer from "puppeteer";

async function inspectFabricSvg() {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-gpu"],
  });

  const page = await browser.newPage();
  await page.goto("http://localhost:3000/templates/new?editorType=document", { waitUntil: "networkidle0" });

  const svgOutput = await page.evaluate(() => {
    const canvas = new fabric.Canvas(document.createElement("canvas"), { width: 500, height: 200 });
    const text = new fabric.IText("บริษัท เครสท์ เซนโด จำกัด", {
      left: 20,
      top: 20,
      fontSize: 20,
      fontFamily: "'Noto Sans Thai', sans-serif",
    });
    canvas.add(text);
    return canvas.toSVG();
  });

  console.log("================================================================================");
  console.log("🔍 FABRIC DEFAULT toSVG() OUTPUT FOR THAI TEXT:");
  console.log("================================================================================");
  console.log(svgOutput);

  await browser.close();
}

inspectFabricSvg().catch(console.error);