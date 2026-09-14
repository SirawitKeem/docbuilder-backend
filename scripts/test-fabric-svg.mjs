import puppeteer from "puppeteer";

async function testFabricSvg() {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-gpu"],
  });

  const page = await browser.newPage();
  await page.goto("http://localhost:3000/templates/new?editorType=document", { waitUntil: "networkidle0" });

  const result = await page.evaluate(async () => {
    // We can get fabric from window or import it
    const fabricModule = await import("fabric");
    const canvas = new fabricModule.Canvas(document.createElement("canvas"), { width: 600, height: 200 });
    const text = new fabricModule.IText("บริษัท เครสท์ เซนโด จำกัด", {
      left: 20,
      top: 20,
      fontSize: 20,
      fontFamily: "'Noto Sans Thai', sans-serif",
    });
    canvas.add(text);
    canvas.renderAll();
    const svg = canvas.toSVG();
    const textObjectSvg = text.toSVG();

    return {
      svg,
      textObjectSvg,
      textLines: text._textLines,
      graphemeLines: text._textLines ? text._textLines[0] : null,
    };
  });

  console.log("================================================================================");
  console.log("🔍 FABRIC 6 SVG OUTPUT FOR THAI TEXT:");
  console.log("================================================================================");
  console.log("SVG Markup:\n", result.textObjectSvg);
  console.log("\nText lines:", result.textLines);
  console.log("Grapheme array for line 0:", result.graphemeLines);

  await browser.close();
}

testFabricSvg().catch(console.error);