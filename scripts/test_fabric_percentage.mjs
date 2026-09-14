import puppeteer from "puppeteer";

async function testGradientPercentage() {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-gpu"],
  });

  const page = await browser.newPage();
  await page.goto("http://localhost:3000/templates/new?editorType=document", { waitUntil: "networkidle0" });
  await page.waitForFunction(() => !!window.__FABRIC__, { timeout: 15000 });

  const result = await page.evaluate(async () => {
    const fabric = window.__FABRIC__;
    const canvas = new fabric.Canvas(document.createElement("canvas"), { width: 500, height: 500 });

    const angleDeg = 90; // Left to right
    const angleRad = ((angleDeg - 90) * Math.PI) / 180;
    const dx = Math.cos(angleRad) * 0.5;
    const dy = Math.sin(angleRad) * 0.5;

    const grad = new fabric.Gradient({
      type: "linear",
      gradientUnits: "percentage",
      coords: {
        x1: 0.5 - dx,
        y1: 0.5 - dy,
        x2: 0.5 + dx,
        y2: 0.5 + dy,
      },
      colorStops: [
        { offset: 0, color: "#FF0000" },
        { offset: 1, color: "#0000FF" },
      ],
    });

    const rect = new fabric.Rect({
      left: 20,
      top: 20,
      width: 200,
      height: 100,
      fill: grad,
    });

    canvas.add(rect);
    canvas.renderAll();

    const json = canvas.toJSON();
    const svg = canvas.toSVG();

    const canvas2 = new fabric.Canvas(document.createElement("canvas"), { width: 500, height: 500 });
    await canvas2.loadFromJSON(json);
    const loadedRect = canvas2.getObjects()[0];

    return {
      serializedFill: json.objects[0].fill,
      isGradInstance: loadedRect.fill instanceof fabric.Gradient,
      loadedUnits: loadedRect.fill?.gradientUnits,
      svgDefs: svg.match(/<defs>[\s\S]*?<\/defs>/)?.[0],
    };
  });

  console.log("Percentage Gradient Test Result:", JSON.stringify(result, null, 2));
  await browser.close();
}

testGradientPercentage().catch(console.error);
