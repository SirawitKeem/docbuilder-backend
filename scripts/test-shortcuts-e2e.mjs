import puppeteer from "puppeteer";

const BASE_URL = "http://localhost:3000";

async function runShortcutTests() {
  console.log("================================================================================");
  console.log("⌨️ RUNNING E2E KEYBOARD SHORTCUTS TEST SUITE");
  console.log("================================================================================");

  const browser = await puppeteer.launch({
    headless: true,
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });

  page.on("console", (msg) => {
    const text = msg.text();
    if (text.includes("PAGE LOG") || text.includes("SHORTCUT TEST")) {
      console.log("  [Browser]", text);
    }
  });

  const testResults = [];

  function record(testName, passed, details = "") {
    const status = passed ? "✅ PASS" : "❌ FAIL";
    console.log(`${status} — ${testName} ${details ? "(" + details + ")" : ""}`);
    testResults.push({ testName, passed, details });
  }

  try {
    console.log("🌐 Navigating to Studio (/templates/new)...");
    await page.goto(`${BASE_URL}/templates/new`, { waitUntil: "networkidle2", timeout: 45000 });

    // Wait until Fabric canvas is mounted on window.__FABRIC_CANVAS__ and window.__FABRIC__
    await page.waitForFunction(
      () => Boolean(window.__FABRIC_CANVAS__) && Boolean(window.__FABRIC__),
      { timeout: 15000 }
    );
    console.log("Canvas is ready and connected to window.__FABRIC_CANVAS__ & window.__FABRIC__!\n");

    // Helper to evaluate in browser context
    async function exec(fn, ...args) {
      return await page.evaluate(fn, ...args);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 1: Copy & Paste Single Object (+20px offset)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("--- 1. Testing Copy & Paste (Ctrl+C / Ctrl+V) ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();
      const rect = new fabric.Rect({ left: 100, top: 100, width: 80, height: 60, fill: "#3B82F6" });
      canvas.add(rect);
      canvas.setActiveObject(rect);
      canvas.renderAll();
    });

    // Press Ctrl+C then Ctrl+V
    await page.keyboard.down("Control");
    await page.keyboard.press("KeyC");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 100));

    await page.keyboard.down("Control");
    await page.keyboard.press("KeyV");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 200));

    const t1Result = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const objs = canvas.getObjects();
      const active = canvas.getActiveObject();
      return {
        count: objs.length,
        activeLeft: active ? active.left : null,
        activeTop: active ? active.top : null,
      };
    });

    record(
      "Copy & Paste Single Object",
      t1Result.count === 2 && t1Result.activeLeft === 120 && t1Result.activeTop === 120,
      `Objects: ${t1Result.count} (expected 2), Pos: (${t1Result.activeLeft}, ${t1Result.activeTop}) (expected 120, 120)`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 2: Cascading Paste & Offset Reset upon new Copy
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 2. Testing Cascading Paste & Offset Reset ---");
    // Paste 2nd time without copying
    await page.keyboard.down("Control");
    await page.keyboard.press("KeyV");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 200));

    const t2Cascade = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      return { count: canvas.getObjects().length, activeLeft: active ? active.left : null, activeTop: active ? active.top : null };
    });

    record(
      "Cascading Paste Second Copy (+40px)",
      t2Cascade.count === 3 && t2Cascade.activeLeft === 140 && t2Cascade.activeTop === 140,
      `Objects: ${t2Cascade.count}, Pos: (${t2Cascade.activeLeft}, ${t2Cascade.activeTop}) (expected 140, 140)`
    );

    // Now select a new object B at (300, 300), copy it, and paste
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      const circle = new fabric.Circle({ radius: 30, left: 300, top: 300, fill: "#EF4444" });
      canvas.add(circle);
      canvas.setActiveObject(circle);
      canvas.renderAll();
    });

    await page.keyboard.down("Control");
    await page.keyboard.press("KeyC");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 100));

    await page.keyboard.down("Control");
    await page.keyboard.press("KeyV");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 200));

    const t2Reset = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      return { activeLeft: active ? active.left : null, activeTop: active ? active.top : null };
    });

    record(
      "Offset Reset Upon New Copy (+20px from new object)",
      t2Reset.activeLeft === 320 && t2Reset.activeTop === 320,
      `Pos: (${t2Reset.activeLeft}, ${t2Reset.activeTop}) (expected 320, 320, NOT accumulated)`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 3: Duplicate (Ctrl+D)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 3. Testing Duplicate (Ctrl+D) ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();
      const rect = new fabric.Rect({ left: 150, top: 150, width: 50, height: 50, fill: "#10B981" });
      canvas.add(rect);
      canvas.setActiveObject(rect);
      canvas.renderAll();
    });

    await page.keyboard.down("Control");
    await page.keyboard.press("KeyD");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 200));

    const t3Result = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const objs = canvas.getObjects();
      const active = canvas.getActiveObject();
      return { count: objs.length, left: active ? active.left : null, top: active ? active.top : null };
    });

    record(
      "Duplicate Single Object (Ctrl+D)",
      t3Result.count === 2 && t3Result.left === 170 && t3Result.top === 170,
      `Objects: ${t3Result.count} (expected 2), Pos: (${t3Result.left}, ${t3Result.top}) (expected 170, 170)`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 4: DocTable Duplicate & Method Verification (addRow / removeRow)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 4. Testing DocTable Duplicate & Method Preservation (CRITICAL) ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();
      const DocTableClass = fabric.classRegistry.getClass("DocTable");
      const table = new DocTableClass({}, { left: 56, top: 200 });
      canvas.add(table);
      canvas.setActiveObject(table);
      canvas.renderAll();
    });
    await new Promise((r) => setTimeout(r, 300));

    const t4Original = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      return {
        isDocTable: Boolean(active && active.isDocTable),
        hasAddRow: typeof active?.addRow === "function",
        initialRowCount: active?.docTableData?.items?.length || 0,
      };
    });

    console.log("   Original DocTable detected:", t4Original);

    // Duplicate DocTable with Ctrl+D
    await page.keyboard.down("Control");
    await page.keyboard.press("KeyD");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 400));

    const t4Duplicate = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      if (!active) return { error: "No active object after Ctrl+D" };

      const isDocTable = Boolean(active.isDocTable);
      const hasAddRow = typeof active.addRow === "function";
      const hasRemoveRow = typeof active.removeRow === "function";

      let addRowSuccess = false;
      let newCount = 0;
      if (hasAddRow) {
        active.addRow({ no: "4", desc: "สินค้าทดสอบชิ้นที่ 4", qty: 3, price: 99000 });
        newCount = active.docTableData.items.length;
        addRowSuccess = newCount === 4;
      }

      let removeRowSuccess = false;
      if (hasRemoveRow) {
        active.removeRow();
        removeRowSuccess = active.docTableData.items.length === 3;
      }

      return {
        isDocTable,
        hasAddRow,
        hasRemoveRow,
        addRowSuccess,
        newCount,
        removeRowSuccess,
      };
    });

    record(
      "DocTable Duplicate Class Preservation",
      t4Duplicate.isDocTable && t4Duplicate.hasAddRow && t4Duplicate.hasRemoveRow,
      `isDocTable: ${t4Duplicate.isDocTable}, addRow: ${t4Duplicate.hasAddRow}, removeRow: ${t4Duplicate.hasRemoveRow}`
    );

    record(
      "DocTable Duplicate addRow() Functional Verification",
      t4Duplicate.addRowSuccess === true,
      `New row count after addRow(): ${t4Duplicate.newCount} (expected 4)`
    );

    record(
      "DocTable Duplicate removeRow() Functional Verification",
      t4Duplicate.removeRowSuccess === true,
      `Row count restored to: 3`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 5: Multi-Selection (ActiveSelection) Copy & Paste
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 5. Testing Multi-Selection Copy & Paste ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();
      const r1 = new fabric.Rect({ left: 100, top: 100, width: 40, height: 40, fill: "blue" });
      const r2 = new fabric.Rect({ left: 200, top: 100, width: 40, height: 40, fill: "green" });
      canvas.add(r1, r2);
      const sel = new fabric.ActiveSelection([r1, r2], { canvas });
      canvas.setActiveObject(sel);
      canvas.renderAll();
    });

    await page.keyboard.down("Control");
    await page.keyboard.press("KeyC");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 100));

    await page.keyboard.down("Control");
    await page.keyboard.press("KeyV");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 250));

    const t5Result = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      return { totalObjects: canvas.getObjects().length, activeType: canvas.getActiveObject()?.type };
    });

    record(
      "Multi-Selection Copy & Paste",
      t5Result.totalObjects === 4,
      `Total Objects: ${t5Result.totalObjects} (expected 4), ActiveType: ${t5Result.activeType}`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 6: Select All (Ctrl+A) Filtering (Locked & System Objects)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 6. Testing Select All (Ctrl+A) Filtering ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();
      const normal1 = new fabric.Rect({ id: "norm1", left: 50, top: 50, width: 40, height: 40 });
      const normal2 = new fabric.Rect({ id: "norm2", left: 100, top: 50, width: 40, height: 40 });
      const lockedObj = new fabric.Rect({ id: "locked", left: 150, top: 50, width: 40, height: 40, locked: true, lockMovementX: true });
      const footerNum = new fabric.Textbox("1 / 2", { id: "footer", left: 200, top: 50, isPageFooterNumber: true });
      canvas.add(normal1, normal2, lockedObj, footerNum);
      canvas.discardActiveObject();
      canvas.renderAll();
    });

    await page.keyboard.down("Control");
    await page.keyboard.press("KeyA");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 150));

    const t6Result = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      if (!active || active.type?.toLowerCase() !== "activeselection") return { selectedCount: 0, ids: [] };
      const selectedIds = active.getObjects().map((o) => o.id);
      return { selectedCount: selectedIds.length, ids: selectedIds };
    });

    const hasLocked = t6Result.ids.includes("locked");
    const hasFooter = t6Result.ids.includes("footer");
    const hasBothNormals = t6Result.ids.includes("norm1") && t6Result.ids.includes("norm2");

    record(
      "Select All Excludes Locked & System Objects",
      t6Result.selectedCount === 2 && !hasLocked && !hasFooter && hasBothNormals,
      `Selected ${t6Result.selectedCount} objects: [${t6Result.ids.join(", ")}] (expected norm1, norm2 only)`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 7: Arrow Key Nudge (1px & Shift+Arrow 10px)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 7. Testing Arrow Key Nudge ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();
      const dot = new fabric.Circle({ radius: 10, left: 200, top: 200, fill: "orange" });
      canvas.add(dot);
      canvas.setActiveObject(dot);
      canvas.renderAll();
    });

    // Press ArrowRight (1px)
    await page.keyboard.press("ArrowRight");
    await new Promise((r) => setTimeout(r, 100));

    const t7Single = await exec(() => {
      const active = window.__FABRIC_CANVAS__.getActiveObject();
      return { left: active.left, top: active.top };
    });

    record(
      "Arrow Key Single Nudge (1px)",
      t7Single.left === 201 && t7Single.top === 200,
      `Pos: (${t7Single.left}, ${t7Single.top}) (expected 201, 200)`
    );

    // Press Shift + ArrowDown (10px)
    await page.keyboard.down("Shift");
    await page.keyboard.press("ArrowDown");
    await page.keyboard.up("Shift");
    await new Promise((r) => setTimeout(r, 100));

    const t7Shift = await exec(() => {
      const active = window.__FABRIC_CANVAS__.getActiveObject();
      return { left: active.left, top: active.top };
    });

    record(
      "Shift + Arrow Key Nudge (10px)",
      t7Shift.left === 201 && t7Shift.top === 210,
      `Pos: (${t7Shift.left}, ${t7Shift.top}) (expected 201, 210)`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 8: Text Editing Regression Check (Backspace inside Text)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 8. Testing Text Editing Regression (Backspace inside Text) ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();
      const text = new fabric.IText("Hello", { left: 100, top: 100, fontSize: 24 });
      canvas.add(text);
      canvas.setActiveObject(text);
      text.enterEditing();
      text.selectAll();
      canvas.renderAll();
    });

    // Type text into the editing textbox
    await page.keyboard.type("World!");
    await new Promise((r) => setTimeout(r, 100));

    // Press Backspace: should delete '!' character, not delete the Textbox object
    await page.keyboard.press("Backspace");
    await new Promise((r) => setTimeout(r, 100));

    const t8Result = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const objs = canvas.getObjects();
      const textObj = objs[0];
      return {
        objectCount: objs.length,
        currentText: textObj ? textObj.text : null,
        isEditing: textObj ? textObj.isEditing : false,
      };
    });

    record(
      "Backspace inside Text Deletes Character, Not Object",
      t8Result.objectCount === 1 && t8Result.currentText === "World",
      `Objects: ${t8Result.objectCount}, Text: "${t8Result.currentText}" (expected "World")`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 9: Escape Key (2-Level Exit Editing -> Deselect)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 9. Testing Escape Key (2-Level UX) ---");
    // 1st Escape: exit editing mode, but stay selected
    await page.keyboard.press("Escape");
    await new Promise((r) => setTimeout(r, 150));

    const t9Level1 = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      return { hasActive: Boolean(active), isEditing: active ? active.isEditing : false };
    });

    record(
      "Escape Level 1 (Exits Text Editing, Keeps Selection)",
      t9Level1.hasActive && !t9Level1.isEditing,
      `hasActive: ${t9Level1.hasActive}, isEditing: ${t9Level1.isEditing}`
    );

    // 2nd Escape: deselect object completely
    await page.keyboard.press("Escape");
    await new Promise((r) => setTimeout(r, 150));

    const t9Level2 = await exec(() => {
      const active = window.__FABRIC_CANVAS__.getActiveObject();
      return { hasActive: Boolean(active) };
    });

    record(
      "Escape Level 2 (Deselects Object)",
      !t9Level2.hasActive,
      `Active Object is null: ${!t9Level2.hasActive}`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 10: Delete Key on Active Object
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 10. Testing Delete Key on Non-editing Object ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      const r = new fabric.Rect({ left: 50, top: 50, width: 30, height: 30 });
      canvas.add(r);
      canvas.setActiveObject(r);
      canvas.renderAll();
    });

    await page.keyboard.press("Delete");
    await new Promise((r) => setTimeout(r, 150));

    const t10Result = await exec(() => {
      return { remainingCount: window.__FABRIC_CANVAS__.getObjects().length };
    });

    record(
      "Delete Key Removes Selected Object",
      t10Result.remainingCount === 1, // original text was kept
      `Remaining Objects: ${t10Result.remainingCount}`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // TEST 11: Cross-Page Copy & Paste
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 11. Testing Cross-Page Copy & Paste ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();
      const crossObj = new fabric.Rect({ id: "cross-page-star", left: 180, top: 180, width: 70, height: 70, fill: "purple" });
      canvas.add(crossObj);
      canvas.setActiveObject(crossObj);
      canvas.renderAll();
    });

    // Copy on Page 1
    await page.keyboard.down("Control");
    await page.keyboard.press("KeyC");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 150));

    // Click Add Page button (+ หน้าใหม่)
    await page.evaluate(() => {
      const btns = Array.from(document.querySelectorAll("button"));
      const addBtn = btns.find((b) => b.textContent && (b.textContent.includes("หน้าใหม่") || b.textContent.includes("เพิ่มหน้า")));
      if (addBtn) addBtn.click();
    });
    await new Promise((r) => setTimeout(r, 1000));

    // Paste onto new page (Page 2)
    await page.keyboard.down("Control");
    await page.keyboard.press("KeyV");
    await page.keyboard.up("Control");
    await new Promise((r) => setTimeout(r, 300));

    const t11Result = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      const objs = canvas.getObjects();
      return {
        hasActive: Boolean(active),
        left: active ? active.left : null,
        top: active ? active.top : null,
        totalOnCurrentPage: objs.length,
      };
    });

    record(
      "Cross-Page Copy & Paste",
      t11Result.hasActive && t11Result.left === 200 && t11Result.top === 200,
      `Pasted on active page at: (${t11Result.left}, ${t11Result.top})`
    );

    await page.screenshot({ path: "C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/shortcuts_verified.png" });
    console.log("\n📸 Saved verification screenshot to shortcuts_verified.png");

  } catch (err) {
    console.error("❌ Test runner error:", err);
  } finally {
    await browser.close();
    console.log("\n================================================================================");
    console.log("📊 FINAL SHORTCUT TEST SUMMARY:");
    console.log("================================================================================");
    const passedCount = testResults.filter((r) => r.passed).length;
    console.log(`Total Tests: ${testResults.length} | Passed: ${passedCount} | Failed: ${testResults.length - passedCount}`);
    if (passedCount === testResults.length && testResults.length > 0) {
      console.log("🎉 ALL SHORTCUT TESTS PASSED WITH 100% SUCCESS!");
    } else {
      console.log("⚠️ Some tests failed. Please inspect logs.");
    }
  }
}

runShortcutTests();
