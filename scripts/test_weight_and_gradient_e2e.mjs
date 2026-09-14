import puppeteer from "puppeteer";
import pptxgen from "pptxgenjs";
import JSZip from "jszip";
import fs from "fs";
import { mapFabricObjectToSlide, extractShapeColor } from "../lib/export/fabricToPptx.js";
import { DEFAULT_FONTS, CURATED_THAI_FONTS, getAvailableWeights, FONT_WEIGHT_LABELS } from "../lib/fonts/fontRegistry.js";

async function runEndToEndVerification() {
  console.log("=========================================================");
  console.log("🚀 E2E VERIFICATION: FONT WEIGHT VARIANTS & GRADIENT FILL");
  console.log("=========================================================\n");

  // 1. UNIT & REGISTRY VERIFICATION
  console.log("--- 1. Testing Registry & Available Weights ---");
  const kanitWeights = getAvailableWeights("Kanit");
  console.log("Kanit Available Weights:", kanitWeights);
  if (!kanitWeights.includes(300) || !kanitWeights.includes(600) || !kanitWeights.includes(800)) {
    throw new Error("Kanit missing required weights!");
  }

  const chonburiWeights = getAvailableWeights("Chonburi");
  console.log("Chonburi Available Weights:", chonburiWeights);
  if (chonburiWeights.length !== 1 || chonburiWeights[0] !== 400) {
    throw new Error("Chonburi should only have [400]!");
  }

  // 2. PPTX EXPORT PIPELINE UNIT TEST (Fallback & Snap)
  console.log("\n--- 2. Testing PPTX Export Pipeline Fallback & Weight Snap ---");
  const pptx = new pptxgen();
  const slide = pptx.addSlide();

  // Test text with weight 500 (< 600 => normal) and weight 600 (>= 600 => bold)
  const textObj500 = {
    type: "textbox",
    text: "น้ำหนัก 500 Medium",
    left: 20,
    top: 20,
    width: 200,
    height: 40,
    fontSize: 16,
    fontFamily: "Kanit",
    fontWeight: 500,
    fill: "#1E293B",
  };

  const textObj600 = {
    type: "textbox",
    text: "น้ำหนัก 600 SemiBold",
    left: 20,
    top: 80,
    width: 200,
    height: 40,
    fontSize: 16,
    fontFamily: "Kanit",
    fontWeight: 600,
    fill: "#1E293B",
  };

  // Test shape with Gradient Fill -> Must fallback to solid color, NOT transparent!
  const gradientRectObj = {
    type: "rect",
    left: 20,
    top: 150,
    width: 250,
    height: 120,
    fill: {
      type: "linear",
      colorStops: [
        { offset: 0, color: "#4F46E5" },
        { offset: 1, color: "#06B6D4" },
      ],
    },
    stroke: "#1E1B4B",
    strokeWidth: 2,
    rx: 8,
  };

  mapFabricObjectToSlide(textObj500, slide, pptx);
  mapFabricObjectToSlide(textObj600, slide, pptx);
  mapFabricObjectToSlide(gradientRectObj, slide, pptx);

  const pptxBuf = await pptx.write({ outputType: "nodebuffer" });
  const zip = await JSZip.loadAsync(pptxBuf);
  const slideXml = await zip.file("ppt/slides/slide1.xml").async("string");

  // Check Text 1: weight 500 should NOT have bold (b="1")
  // Check Text 2: weight 600 MUST have bold (b="1")
  // Check Rect: must have <a:solidFill><a:srgbClr val="4F46E5"/>
  console.log("Checking generated PPTX OOXML:");
  const hasSolidFill = slideXml.includes('<a:srgbClr val="4F46E5"/>');
  console.log("  Shape has solid fallback fill (4F46E5):", hasSolidFill);
  if (!hasSolidFill) {
    throw new Error("Shape gradient did NOT fallback to solid fill in PPTX!");
  }

  const boldMatches = slideXml.match(/<a:rPr[^>]*b="1"[^>]*>/g) || [];
  console.log("  Total bold text runs (>= 600):", boldMatches.length);
  if (boldMatches.length !== 1) {
    throw new Error(`Expected exactly 1 bold text run, found ${boldMatches.length}`);
  }

  // 3. BROWSER UI & CANVAS INTEGRATION TEST
  console.log("\n--- 3. Testing Browser UI & Canvas Integration via Puppeteer ---");
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--disable-gpu"],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });

  await page.goto("http://localhost:3000/templates/new?editorType=slide&canvasPreset=slide-16-9", {
    waitUntil: "networkidle0",
  });

  await page.waitForFunction(() => !!window.__FABRIC__ && !!window.__FABRIC_CANVAS__, { timeout: 15000 });

  // Add a Textbox and a Rect using Fabric
  const evalResult = await page.evaluate(async () => {
    const fabric = window.__FABRIC__;
    const canvas = window.__FABRIC_CANVAS__;

    // 1. Create Text with weight 600
    const tb = new fabric.Textbox("ข้อความทดสอบ Font Weight 600", {
      left: 100,
      top: 100,
      width: 350,
      fontSize: 24,
      fontFamily: "'Kanit', sans-serif",
      fontWeight: 600,
      fill: "#1E293B",
    });

    // 2. Create Rect with Linear Gradient
    const grad = new fabric.Gradient({
      type: "linear",
      gradientUnits: "percentage",
      coords: { x1: 0, y1: 0.5, x2: 1, y2: 0.5 },
      colorStops: [
        { offset: 0, color: "#6366F1" },
        { offset: 1, color: "#EC4899" },
      ],
    });

    const rect = new fabric.Rect({
      left: 100,
      top: 200,
      width: 300,
      height: 150,
      rx: 12,
      ry: 12,
      fill: grad,
      stroke: "#4338CA",
      strokeWidth: 2,
    });

    canvas.add(tb, rect);
    canvas.setActiveObject(rect);
    canvas.renderAll();

    // Verify SVG export
    const svg = canvas.toSVG();

    // Verify serialization & deserialization
    const json = canvas.toJSON();
    const canvas2 = new fabric.Canvas(document.createElement("canvas"), { width: 960, height: 540 });
    await canvas2.loadFromJSON(json);
    const loadedObjects = canvas2.getObjects();
    const loadedTb = loadedObjects[loadedObjects.length - 2];
    const loadedRect = loadedObjects[loadedObjects.length - 1];

    return {
      totalObjects: loadedObjects.length,
      svgHasLinearGradient: svg.includes("<linearGradient"),
      loadedTextWeight: loadedTb.fontWeight,
      loadedRectIsGradient: loadedRect.fill instanceof fabric.Gradient,
      loadedRectStopsCount: loadedRect.fill?.colorStops?.length,
    };
  });

  console.log("Browser Evaluation Result:", JSON.stringify(evalResult, null, 2));

  if (!evalResult.svgHasLinearGradient) {
    throw new Error("SVG export does not contain <linearGradient>!");
  }
  if (evalResult.loadedTextWeight !== 600) {
    throw new Error(`Loaded text weight mismatch: expected 600, got ${evalResult.loadedTextWeight}`);
  }
  if (!evalResult.loadedRectIsGradient) {
    throw new Error("Loaded rect fill is not instanceof fabric.Gradient!");
  }

  // Capture Screenshot of Editor with properties panel showing the shape gradient controls
  await new Promise((r) => setTimeout(r, 1200));
  await page.screenshot({ path: "public/test_gradient_and_weight_ui.png" });
  fs.copyFileSync(
    "public/test_gradient_and_weight_ui.png",
    "C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/test_gradient_and_weight_ui.png"
  );
  console.log("📸 Captured public/test_gradient_and_weight_ui.png");

  // Select text object to test RightSidebar text UI
  await page.evaluate(() => {
    const canvas = window.__FABRIC_CANVAS__;
    const tb = canvas.getObjects()[0];
    canvas.setActiveObject(tb);
    canvas.renderAll();
  });
  await new Promise((r) => setTimeout(r, 1200));
  await page.screenshot({ path: "public/test_text_weight_ui.png" });
  fs.copyFileSync(
    "public/test_text_weight_ui.png",
    "C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/test_text_weight_ui.png"
  );
  console.log("📸 Captured public/test_text_weight_ui.png");

  await browser.close();
  console.log("\n🎉 ALL E2E TESTS PASSED SUCCESSFULLY!");
}

runEndToEndVerification().catch((err) => {
  console.error("❌ E2E Verification failed:", err);
  process.exit(1);
});
