import puppeteer from "puppeteer";

async function testInteractiveUI() {
  console.log("=========================================================");
  console.log("🧪 INTERACTIVE UI TEST: FONT WEIGHT & GRADIENT CONTROLS");
  console.log("=========================================================\n");

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

  // 1. Add Text and Shape
  await page.evaluate(() => {
    const fabric = window.__FABRIC__;
    const canvas = window.__FABRIC_CANVAS__;

    const tb = new fabric.Textbox("ข้อความทดสอบ UI อินเทอร์แอคทีฟ", {
      left: 120,
      top: 100,
      width: 400,
      fontSize: 28,
      fontFamily: "'Kanit', sans-serif",
      fontWeight: 400,
      fill: "#1E293B",
    });

    const rect = new fabric.Rect({
      left: 120,
      top: 200,
      width: 320,
      height: 160,
      rx: 16,
      ry: 16,
      fill: "#3B82F6",
      stroke: "#1D4ED8",
      strokeWidth: 2,
    });

    canvas.add(tb, rect);
    canvas.setActiveObject(tb);
    canvas.renderAll();
  });

  await new Promise((r) => setTimeout(r, 1000));

  // 2. Select Text -> Change weight via select dropdown to 700
  console.log("Testing Text Weight dropdown change to 700...");
  const selectSuccess = await page.evaluate(() => {
    const selects = Array.from(document.querySelectorAll("select"));
    const weightSelect = selects.find((s) => s.querySelector('option[value="700"]'));
    if (!weightSelect) return false;
    weightSelect.value = "700";
    weightSelect.dispatchEvent(new Event("change", { bubbles: true }));
    return true;
  });

  if (!selectSuccess) {
    throw new Error("Could not find Font Weight select element in DOM!");
  }
  await new Promise((r) => setTimeout(r, 800));

  const textWeightAfterSelect = await page.evaluate(() => {
    const canvas = window.__FABRIC_CANVAS__;
    const active = canvas.getActiveObject();
    return active.fontWeight;
  });
  console.log("  Text fontWeight after dropdown select:", textWeightAfterSelect);
  if (Number(textWeightAfterSelect) !== 700) {
    throw new Error(`Expected 700, got ${textWeightAfterSelect}`);
  }

  // 3. Click Bold button to toggle back to 400
  console.log("Testing Bold button toggle...");
  await page.evaluate(() => {
    const btns = Array.from(document.querySelectorAll("button"));
    const boldBtn = btns.find((b) => b.title && b.title.includes("ตัว"));
    if (boldBtn) boldBtn.click();
  });
  await new Promise((r) => setTimeout(r, 800));

  const textWeightAfterToggle = await page.evaluate(() => {
    const canvas = window.__FABRIC_CANVAS__;
    const active = canvas.getActiveObject();
    return active.fontWeight;
  });
  console.log("  Text fontWeight after toggle:", textWeightAfterToggle);
  if (Number(textWeightAfterToggle) !== 400) {
    throw new Error(`Expected 400, got ${textWeightAfterToggle}`);
  }

  // 4. Select Shape -> Switch to Linear Gradient
  console.log("\nTesting Shape Fill switch to Linear Gradient...");
  await page.evaluate(() => {
    const canvas = window.__FABRIC_CANVAS__;
    const objs = canvas.getObjects();
    const rect = objs[objs.length - 1];
    canvas.setActiveObject(rect);
    canvas.renderAll();
  });
  await new Promise((r) => setTimeout(r, 1000));

  // Click "ไล่สีเส้นตรง" button
  const linearClickSuccess = await page.evaluate(() => {
    const btns = Array.from(document.querySelectorAll("button"));
    const btn = btns.find((b) => b.textContent.includes("ไล่สีเส้นตรง"));
    if (!btn) return false;
    btn.click();
    return true;
  });
  if (!linearClickSuccess) throw new Error("Could not find 'ไล่สีเส้นตรง' button!");
  await new Promise((r) => setTimeout(r, 800));

  const shapeFillAfterLinear = await page.evaluate(() => {
    const canvas = window.__FABRIC_CANVAS__;
    const active = canvas.getActiveObject();
    return {
      isGradient: active.fill instanceof window.__FABRIC__.Gradient,
      type: active.fill?.type,
      units: active.fill?.gradientUnits,
      stopsCount: active.fill?.colorStops?.length,
    };
  });
  console.log("  Shape fill after switching to Linear:", JSON.stringify(shapeFillAfterLinear));
  if (!shapeFillAfterLinear.isGradient || shapeFillAfterLinear.type !== "linear") {
    throw new Error("Shape fill is not linear gradient!");
  }

  // 5. Switch to Radial Gradient
  console.log("Testing Shape Fill switch to Radial Gradient...");
  await page.evaluate(() => {
    const btns = Array.from(document.querySelectorAll("button"));
    const btn = btns.find((b) => b.textContent.includes("ไล่สีวงกลม"));
    if (btn) btn.click();
  });
  await new Promise((r) => setTimeout(r, 800));

  const shapeFillAfterRadial = await page.evaluate(() => {
    const canvas = window.__FABRIC_CANVAS__;
    const active = canvas.getActiveObject();
    return {
      isGradient: active.fill instanceof window.__FABRIC__.Gradient,
      type: active.fill?.type,
      stopsCount: active.fill?.colorStops?.length,
    };
  });
  console.log("  Shape fill after switching to Radial:", JSON.stringify(shapeFillAfterRadial));
  if (!shapeFillAfterRadial.isGradient || shapeFillAfterRadial.type !== "radial") {
    throw new Error("Shape fill is not radial gradient!");
  }

  // 6. Switch back to Solid
  console.log("Testing Shape Fill switch back to Solid...");
  await page.evaluate(() => {
    const btns = Array.from(document.querySelectorAll("button"));
    const btn = btns.find((b) => b.textContent.includes("สีเดี่ยว"));
    if (btn) btn.click();
  });
  await new Promise((r) => setTimeout(r, 800));

  const shapeFillAfterSolid = await page.evaluate(() => {
    const canvas = window.__FABRIC_CANVAS__;
    const active = canvas.getActiveObject();
    return {
      type: typeof active.fill,
      val: active.fill,
    };
  });
  console.log("  Shape fill after switching to Solid:", JSON.stringify(shapeFillAfterSolid));
  if (shapeFillAfterSolid.type !== "string") {
    throw new Error("Shape fill is not solid color string!");
  }

  await browser.close();
  console.log("\n🎉 ALL INTERACTIVE UI TESTS PASSED 100%!");
}

testInteractiveUI().catch((err) => {
  console.error("❌ Interactive UI test failed:", err);
  process.exit(1);
});
