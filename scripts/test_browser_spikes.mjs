import puppeteer from "puppeteer";

async function runBrowserSpikes() {
  console.log("=================================================");
  console.log("🌐 FABRIC.JS BROWSER SPIKE: FONT WEIGHT & GRADIENTS");
  console.log("=================================================");

  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-gpu"],
  });

  const page = await browser.newPage();
  await page.goto("http://localhost:3000/templates/new?editorType=document", { waitUntil: "networkidle0" });

  // Wait for window.__FABRIC__ to exist
  await page.waitForFunction(() => !!window.__FABRIC__ && !!window.__FABRIC_CANVAS__, { timeout: 15000 });

  const result = await page.evaluate(async () => {
    const fabric = window.__FABRIC__;
    const testCanvas = new fabric.Canvas(document.createElement("canvas"), { width: 800, height: 600 });

    // 1. Test Font Weight serialization & deserialization
    const weightsTest = [300, 400, 500, 600, 700, 800, "300", "500", "600", "bold", "normal"];
    const weightResults = [];

    for (const w of weightsTest) {
      const tb = new fabric.Textbox("ข้อความทดสอบน้ำหนัก", {
        left: 20,
        top: 20,
        fontSize: 20,
        fontFamily: "'Kanit', sans-serif",
        fontWeight: w,
      });
      testCanvas.add(tb);
      const json = testCanvas.toJSON();
      const serialized = json.objects[json.objects.length - 1].fontWeight;
      weightResults.push({ input: w, serialized, type: typeof serialized });
      testCanvas.remove(tb);
    }

    // 2. Test Gradient serialization & deserialization
    const linearGrad = new fabric.Gradient({
      type: "linear",
      coords: { x1: 0, y1: 0, x2: 200, y2: 100 },
      colorStops: [
        { offset: 0, color: "#FF0000" },
        { offset: 0.5, color: "#00FF00" },
        { offset: 1, color: "#0000FF" },
      ],
    });

    const radialGrad = new fabric.Gradient({
      type: "radial",
      coords: { r1: 0, r2: 80, x1: 50, y1: 50, x2: 50, y2: 50 },
      colorStops: [
        { offset: 0, color: "#FFFFFF" },
        { offset: 1, color: "#4F46E5" },
      ],
    });

    const rect = new fabric.Rect({
      left: 50,
      top: 50,
      width: 200,
      height: 100,
      fill: linearGrad,
    });

    const circle = new fabric.Circle({
      left: 300,
      top: 50,
      radius: 50,
      fill: radialGrad,
    });

    // Thai Text on the same canvas to test SVG compatibility
    const thaiText = new fabric.Textbox("บริษัท เครสท์ เซนโด จำกัด (เอกสารทดสอบ)", {
      left: 50,
      top: 200,
      fontSize: 24,
      fontFamily: "'Noto Sans Thai', sans-serif",
      fontWeight: 600,
    });

    testCanvas.add(rect, circle, thaiText);
    testCanvas.renderAll();

    // Serialize to JSON
    const serializedJson = testCanvas.toJSON();

    // Reload into a second canvas
    const testCanvas2 = new fabric.Canvas(document.createElement("canvas"), { width: 800, height: 600 });
    await testCanvas2.loadFromJSON(serializedJson);
    testCanvas2.renderAll();

    const loadedRect = testCanvas2.getObjects()[0];
    const loadedCircle = testCanvas2.getObjects()[1];
    const loadedText = testCanvas2.getObjects()[2];

    const isRectGrad = loadedRect.fill instanceof fabric.Gradient;
    const isCircleGrad = loadedCircle.fill instanceof fabric.Gradient;
    const loadedRectStops = loadedRect.fill?.colorStops || [];
    const loadedTextWeight = loadedText.fontWeight;

    // Test toSVG()
    const svg = testCanvas2.toSVG();

    return {
      weightResults,
      gradient: {
        serializedRectFill: serializedJson.objects[0].fill,
        isRectGrad,
        isCircleGrad,
        loadedRectStopsCount: loadedRectStops.length,
        loadedTextWeight,
        svgContainsLinear: svg.includes("<linearGradient"),
        svgContainsRadial: svg.includes("<radialGradient"),
        svgContainsDefs: svg.includes("<defs"),
        svgLength: svg.length,
        svgDefsSnippet: svg.match(/<defs>[\s\S]*?<\/defs>/)?.[0]?.slice(0, 300),
      },
    };
  });

  console.log("Weight Results:", JSON.stringify(result.weightResults, null, 2));
  console.log("Gradient Results:", JSON.stringify(result.gradient, null, 2));

  await browser.close();
  console.log("✅ BROWSER SPIKE FINISHED SUCCESSFULLY!");
}

runBrowserSpikes().catch((err) => {
  console.error("Browser spike error:", err);
  process.exit(1);
});
