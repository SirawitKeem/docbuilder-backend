import puppeteer from "puppeteer";

const BASE_URL = "http://localhost:3000";

async function runPhaseG1Tests() {
  console.log("================================================================================");
  console.log("⌨️ RUNNING PHASE G.1 E2E TEST SUITE: HOTFIX SHORTCUTS, SHIFT-DRAG & GROUP/UNGROUP");
  console.log("================================================================================");

  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });

  page.on("dialog", async (dialog) => {
    console.log(`   🔔 Alert / Dialog intercepted: "${dialog.message()}"`);
    await dialog.accept();
  });

  page.on("console", (msg) => {
    const text = msg.text();
    if (!text.includes("Download the React DevTools") && !text.includes("Fast Refresh")) {
      console.log("   [Browser Console]", text);
    }
  });
  page.on("pageerror", (err) => {
    console.log("   ❌ [Browser Error]", err.message);
  });

  const testResults = [];
  function record(testName, passed, details) {
    const icon = passed ? "✅ PASS" : "❌ FAIL";
    console.log(`${icon} — ${testName} (${details})`);
    testResults.push({ testName, passed, details });
  }

  try {
    console.log("🌐 Navigating to Studio (/templates/new)...");
    await page.goto(`${BASE_URL}/templates/new`, { waitUntil: "networkidle2", timeout: 45000 });

    await page.waitForFunction(
      () => Boolean(window.__FABRIC_CANVAS__) && Boolean(window.__FABRIC__),
      { timeout: 15000 }
    );
    console.log("Canvas is ready and connected to window.__FABRIC_CANVAS__ & window.__FABRIC__!\n");

    async function exec(fn, ...args) {
      return await page.evaluate(fn, ...args);
    }

    // Helper to dispatch keyboard events simulating specific keyboard layouts (Thai vs English)
    async function dispatchKeyEvent({ code, key, ctrlKey = false, metaKey = false, shiftKey = false }) {
      await page.evaluate(
        ({ code, key, ctrlKey, metaKey, shiftKey }) => {
          const event = new KeyboardEvent("keydown", {
            code,
            key,
            ctrlKey,
            metaKey,
            shiftKey,
            bubbles: true,
            cancelable: true,
          });
          window.dispatchEvent(event);
        },
        { code, key, ctrlKey, metaKey, shiftKey }
      );
      await new Promise((r) => setTimeout(r, 120));
    }

    // ──────────────────────────────────────────────────────────────────────────
    // PART 1: Thai Keyboard Layout Verification (Root Cause e.code)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("--- 1. Testing Thai Keyboard Layout Shortcuts (e.code === Key...) ---");

    // T1.1: Copy & Paste with Thai input layout (KeyC='แ', KeyV='อ')
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();
      const rect = new fabric.Rect({ id: "thai-rect", left: 100, top: 100, width: 60, height: 60, fill: "#3B82F6" });
      canvas.add(rect);
      canvas.setActiveObject(rect);
      canvas.renderAll();
      if (window.__DOC_EDITOR_INIT_HISTORY__) {
        window.__DOC_EDITOR_INIT_HISTORY__(canvas);
      }
    });

    // Press Ctrl+C with Thai key 'แ'
    await dispatchKeyEvent({ code: "KeyC", key: "แ", ctrlKey: true });
    // Press Ctrl+V with Thai key 'อ'
    await dispatchKeyEvent({ code: "KeyV", key: "อ", ctrlKey: true });

    const t1CopyPaste = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const objs = canvas.getObjects();
      const active = canvas.getActiveObject();
      return { count: objs.length, left: active ? active.left : null, top: active ? active.top : null };
    });

    record(
      "Thai Keyboard Copy & Paste (KeyC='แ', KeyV='อ')",
      t1CopyPaste.count === 2 && t1CopyPaste.left === 120 && t1CopyPaste.top === 120,
      `Objects: ${t1CopyPaste.count} (expected 2), Pos: (${t1CopyPaste.left}, ${t1CopyPaste.top})`
    );

    // T1.2: Duplicate with Thai layout (KeyD='ด')
    await dispatchKeyEvent({ code: "KeyD", key: "ด", ctrlKey: true });
    const t1Dup = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      return { count: canvas.getObjects().length, activeLeft: canvas.getActiveObject()?.left };
    });

    record(
      "Thai Keyboard Duplicate (KeyD='ด')",
      t1Dup.count === 3 && t1Dup.activeLeft === 140,
      `Objects: ${t1Dup.count} (expected 3), Pos: ${t1Dup.activeLeft} (expected 140)`
    );

    // T1.3: Select All with Thai layout (KeyA='ฟ')
    await dispatchKeyEvent({ code: "KeyA", key: "ฟ", ctrlKey: true });
    const t1SelectAll = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      return { type: active?.type, selectedCount: active?.getObjects?.()?.length };
    });

    record(
      "Thai Keyboard Select All (KeyA='ฟ')",
      t1SelectAll.type?.toLowerCase() === "activeselection" && t1SelectAll.selectedCount === 3,
      `Type: ${t1SelectAll.type}, Selected Count: ${t1SelectAll.selectedCount} (expected 3)`
    );

    // T1.4: Undo with Thai layout (KeyZ='ผ')
    // We added rect, pasted (+1), duplicated (+1). Undo should remove duplicated object.
    await dispatchKeyEvent({ code: "KeyZ", key: "ผ", ctrlKey: true });
    await new Promise((r) => setTimeout(r, 400));

    const t1Undo = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      return { count: canvas.getObjects().length };
    });

    record(
      "Thai Keyboard Undo (KeyZ='ผ')",
      t1Undo.count === 2,
      `Objects after undo: ${t1Undo.count} (expected 2)`
    );

    // T1.5: Redo with Thai layout (KeyY='ย')
    await dispatchKeyEvent({ code: "KeyY", key: "ย", ctrlKey: true });
    await new Promise((r) => setTimeout(r, 200));

    const t1Redo = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      return { count: canvas.getObjects().length };
    });

    record(
      "Thai Keyboard Redo (KeyY='ย')",
      t1Redo.count === 3,
      `Objects after redo: ${t1Redo.count} (expected 3)`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // PART 2: Rubber-band Selection Lock Filtering
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 2. Testing Rubber-band Selection Lock Filtering ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();

      const normal1 = new fabric.Rect({ id: "norm1", left: 100, top: 100, width: 40, height: 40, fill: "blue" });
      const normal2 = new fabric.Rect({ id: "norm2", left: 200, top: 100, width: 40, height: 40, fill: "green" });
      const lockedObj = new fabric.Rect({
        id: "locked1",
        left: 300,
        top: 100,
        width: 40,
        height: 40,
        fill: "red",
        locked: true,
        lockMovementX: true,
        lockMovementY: true,
      });

      canvas.add(normal1, normal2, lockedObj);

      // Trigger selection:created with all 3 objects as Fabric does when rubber-banding
      const dirtySel = new fabric.ActiveSelection([normal1, normal2, lockedObj], { canvas });
      canvas.setActiveObject(dirtySel);
      canvas.fire("selection:created", { selected: [normal1, normal2, lockedObj], target: dirtySel });
    });

    await new Promise((r) => setTimeout(r, 150));

    const t2LockFilter = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      const selectedIds = active?.getObjects?.()?.map((o) => o.id) || [active?.id];
      const lockedObj = canvas.getObjects().find((o) => o.id === "locked1");

      // Now move the active selection by +50, +50
      if (active) {
        active.set({ left: active.left + 50, top: active.top + 50 });
        active.setCoords();
      }

      return {
        selectedIds,
        lockedLeft: lockedObj?.left,
        lockedTop: lockedObj?.top,
      };
    });

    const lockExcluded =
      !t2LockFilter.selectedIds.includes("locked1") &&
      t2LockFilter.selectedIds.includes("norm1") &&
      t2LockFilter.selectedIds.includes("norm2");

    const lockUnmoved = t2LockFilter.lockedLeft === 300 && t2LockFilter.lockedTop === 100;

    record(
      "Rubber-band Selection Excludes Locked Objects",
      lockExcluded,
      `Selected IDs: [${t2LockFilter.selectedIds.join(", ")}] (locked1 must not be in list)`
    );

    record(
      "Locked Object Remains Unmoved During Group Drag",
      lockUnmoved,
      `Locked Object Pos: (${t2LockFilter.lockedLeft}, ${t2LockFilter.lockedTop}) (expected 300, 100)`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // PART 3: Shift+Drag Axis Constrain (Horizontal & Vertical)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 3. Testing Shift+Drag Axis Constrain ---");
    const t3Result = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();

      const shape = new fabric.Rect({ id: "drag-rect", left: 200, top: 200, width: 50, height: 50, fill: "purple" });
      canvas.add(shape);
      canvas.setActiveObject(shape);

      // 1. Simulate horizontal drag with Shift key: move dx=80, dy=20
      shape.set({ left: 280, top: 220 });
      canvas.fire("object:moving", { target: shape, e: { shiftKey: true } });
      const hLockedPos = { left: shape.left, top: shape.top };

      // 2. Release mouse and axis lock
      canvas.fire("mouse:up", {});

      // 3. Simulate vertical drag with Shift key: move dx=15, dy=90
      shape.set({ left: shape.left + 15, top: shape.top + 90 });
      canvas.fire("object:moving", { target: shape, e: { shiftKey: true } });
      const vLockedPos = { left: shape.left, top: shape.top };

      // 4. Release Shift mid-drag: move dx=40, dy=40 freely
      shape.set({ left: shape.left + 40, top: shape.top + 40 });
      canvas.fire("object:moving", { target: shape, e: { shiftKey: false } });
      const freePos = { left: shape.left, top: shape.top };

      return { hLockedPos, vLockedPos, freePos };
    });

    record(
      "Shift+Drag Horizontal Axis Lock (dy=0)",
      t3Result.hLockedPos.left === 280 && t3Result.hLockedPos.top === 200,
      `Pos: (${t3Result.hLockedPos.left}, ${t3Result.hLockedPos.top}) (expected 280, 200)`
    );

    record(
      "Shift+Drag Vertical Axis Lock (dx=0)",
      t3Result.vLockedPos.left === 280 && t3Result.vLockedPos.top === 290,
      `Pos: (${t3Result.vLockedPos.left}, ${t3Result.vLockedPos.top}) (expected 280, 290)`
    );

    record(
      "Release Shift Mid-Drag Resumes Free Movement",
      t3Result.freePos.left === 320 && t3Result.freePos.top === 330,
      `Pos: (${t3Result.freePos.left}, ${t3Result.freePos.top}) (expected 320, 330)`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // PART 4: Group & Ungroup (Ctrl+G / Ctrl+Shift+G) with 0px Drift Verification
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 4. Testing Group & Ungroup (Ctrl+G / Ctrl+Shift+G) ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();

      const o1 = new fabric.Rect({ id: "item1", left: 100, top: 100, width: 40, height: 40, fill: "orange" });
      const o2 = new fabric.Rect({ id: "item2", left: 180, top: 140, width: 40, height: 40, fill: "teal" });
      const o3 = new fabric.Rect({ id: "item3", left: 260, top: 180, width: 40, height: 40, fill: "indigo" });

      canvas.add(o1, o2, o3);
      const sel = new fabric.ActiveSelection([o1, o2, o3], { canvas });
      canvas.setActiveObject(sel);
      canvas.renderAll();
    });

    // Press Ctrl+G to Group
    await dispatchKeyEvent({ code: "KeyG", key: "g", ctrlKey: true });

    const t4Grouped = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      return {
        type: active?.type,
        isUserGroup: active?.isUserGroup,
        childCount: active?.getObjects?.()?.length,
        canvasObjectCount: canvas.getObjects().length,
      };
    });

    record(
      "Group Creation (Ctrl+G) & isUserGroup Marking",
      t4Grouped.type === "group" && t4Grouped.isUserGroup === true && t4Grouped.childCount === 3 && t4Grouped.canvasObjectCount === 1,
      `Type: ${t4Grouped.type}, isUserGroup: ${t4Grouped.isUserGroup}, Children: ${t4Grouped.childCount}, Canvas Objects: ${t4Grouped.canvasObjectCount}`
    );

    // Now test Ungroup (Ctrl+Shift+G) and verify 0px coordinate drift
    await dispatchKeyEvent({ code: "KeyG", key: "G", ctrlKey: true, shiftKey: true });

    const t4Ungrouped = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const o1 = canvas.getObjects().find((o) => o.id === "item1");
      const o2 = canvas.getObjects().find((o) => o.id === "item2");
      const o3 = canvas.getObjects().find((o) => o.id === "item3");
      const active = canvas.getActiveObject();

      return {
        totalOnCanvas: canvas.getObjects().length,
        activeType: active?.type,
        p1: { left: o1?.left, top: o1?.top },
        p2: { left: o2?.left, top: o2?.top },
        p3: { left: o3?.left, top: o3?.top },
      };
    });

    const zeroDrift =
      Math.abs(t4Ungrouped.p1.left - 100) < 0.1 &&
      Math.abs(t4Ungrouped.p1.top - 100) < 0.1 &&
      Math.abs(t4Ungrouped.p2.left - 180) < 0.1 &&
      Math.abs(t4Ungrouped.p2.top - 140) < 0.1 &&
      Math.abs(t4Ungrouped.p3.left - 260) < 0.1 &&
      Math.abs(t4Ungrouped.p3.top - 180) < 0.1;

    record(
      "Ungroup (Ctrl+Shift+G) with 0px Coordinate Drift",
      t4Ungrouped.totalOnCanvas === 3 && zeroDrift,
      `p1: (${t4Ungrouped.p1.left}, ${t4Ungrouped.p1.top}), p2: (${t4Ungrouped.p2.left}, ${t4Ungrouped.p2.top}), p3: (${t4Ungrouped.p3.left}, ${t4Ungrouped.p3.top})`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // PART 5: Custom Class Guard (DocTable rejection in Group)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 5. Testing Custom Class Guard (DocTable Group Rejection) ---");
    const t5Guard = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();

      const DocTableClass = fabric.classRegistry.getClass("DocTable");
      const table = new DocTableClass({}, { left: 56, top: 200 });
      const rect = new fabric.Rect({ left: 300, top: 200, width: 40, height: 40 });

      canvas.add(table, rect);
      const sel = new fabric.ActiveSelection([table, rect], { canvas });
      canvas.setActiveObject(sel);
      return { initialCanvasCount: canvas.getObjects().length };
    });

    // Press Ctrl+G on DocTable + Rect -> should alert and be rejected
    await dispatchKeyEvent({ code: "KeyG", key: "g", ctrlKey: true });

    const t5AfterAttempt = await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const active = canvas.getActiveObject();
      return {
        canvasCount: canvas.getObjects().length,
        hasGroup: canvas.getObjects().some((o) => o.isUserGroup),
      };
    });

    record(
      "DocTable + Object Grouping Rejection (No Crash)",
      t5AfterAttempt.canvasCount === 2 && !t5AfterAttempt.hasGroup,
      `Canvas Objects: ${t5AfterAttempt.canvasCount} (expected 2), hasGroup: ${t5AfterAttempt.hasGroup}`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // PART 6: Group + Nudge and Group + Escape Regression
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 6. Testing Group Nudge & Escape Regression ---");
    await exec(() => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();

      const r1 = new fabric.Rect({ left: 150, top: 150, width: 30, height: 30 });
      const r2 = new fabric.Rect({ left: 200, top: 150, width: 30, height: 30 });
      const grp = new fabric.Group([r1, r2], { isUserGroup: true, left: 150, top: 150 });
      canvas.add(grp);
      canvas.setActiveObject(grp);
      canvas.renderAll();
    });

    // Press ArrowRight (1px nudge)
    await page.keyboard.press("ArrowRight");
    await new Promise((r) => setTimeout(r, 100));

    const t6Nudge1 = await exec(() => {
      const active = window.__FABRIC_CANVAS__.getActiveObject();
      return { left: active?.left, top: active?.top };
    });

    // Press Shift + ArrowDown (10px nudge)
    await page.keyboard.down("Shift");
    await page.keyboard.press("ArrowDown");
    await page.keyboard.up("Shift");
    await new Promise((r) => setTimeout(r, 100));

    const t6Nudge10 = await exec(() => {
      const active = window.__FABRIC_CANVAS__.getActiveObject();
      return { left: active?.left, top: active?.top };
    });

    record(
      "Group Arrow Nudge (1px Right & 10px Down)",
      t6Nudge1.left === 151 && t6Nudge10.top === 160,
      `After 1px: left=${t6Nudge1.left} (expected 151), After 10px: top=${t6Nudge10.top} (expected 160)`
    );

    // Press Escape to Deselect Group
    await dispatchKeyEvent({ code: "Escape", key: "Escape" });
    await new Promise((r) => setTimeout(r, 100));

    const t6Escape = await exec(() => {
      return { active: window.__FABRIC_CANVAS__.getActiveObject() };
    });

    record(
      "Group Escape Clean Deselection",
      !t6Escape.active,
      `Active Object is cleared: ${!t6Escape.active}`
    );

    // ──────────────────────────────────────────────────────────────────────────
    // PART 7: Persistence Verification (toJSON / loadFromJSON)
    // ──────────────────────────────────────────────────────────────────────────
    console.log("\n--- 7. Testing Group Persistence (CUSTOM_CANVAS_PROPS) ---");
    const t7Persist = await exec(async () => {
      const canvas = window.__FABRIC_CANVAS__;
      const fabric = window.__FABRIC__;
      canvas.clear();

      const r1 = new fabric.Rect({ left: 100, top: 100, width: 40, height: 40 });
      const r2 = new fabric.Rect({ left: 150, top: 100, width: 40, height: 40 });
      const grp = new fabric.Group([r1, r2], { isUserGroup: true, left: 100, top: 100 });
      canvas.add(grp);

      const json = canvas.toJSON();
      const groupInJson = json.objects.find((o) => o.type?.toLowerCase() === "group");
      const isUserGroupPreservedInJson = Boolean(groupInJson?.isUserGroup);

      // Reload from JSON
      canvas.clear();
      await canvas.loadFromJSON(json);

      const reloadedGroup = canvas.getObjects().find((o) => o.type?.toLowerCase() === "group");
      return {
        isUserGroupPreservedInJson,
        reloadedIsUserGroup: Boolean(reloadedGroup?.isUserGroup),
        reloadedChildrenCount: reloadedGroup?.getObjects?.()?.length,
      };
    });

    record(
      "Group Persistence Across toJSON & loadFromJSON",
      t7Persist.isUserGroupPreservedInJson && t7Persist.reloadedIsUserGroup && t7Persist.reloadedChildrenCount === 2,
      `In JSON: ${t7Persist.isUserGroupPreservedInJson}, After Reload: ${t7Persist.reloadedIsUserGroup}, Children: ${t7Persist.reloadedChildrenCount}`
    );

    console.log("\n📸 Saving verification screenshot...");
    await page.screenshot({ path: "C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/phase_g1_verified.png" });
    console.log("Saved to phase_g1_verified.png");

  } catch (err) {
    console.error("❌ Test runner error:", err);
  } finally {
    await browser.close();
    console.log("\n================================================================================");
    console.log("📊 FINAL PHASE G.1 TEST SUMMARY:");
    console.log("================================================================================");
    const passedCount = testResults.filter((r) => r.passed).length;
    console.log(`Total Tests: ${testResults.length} | Passed: ${passedCount} | Failed: ${testResults.length - passedCount}`);
    if (passedCount === testResults.length && testResults.length > 0) {
      console.log("🎉 ALL PHASE G.1 TESTS PASSED WITH 100% SUCCESS!");
    } else {
      console.log("⚠️ Some tests failed. Please inspect logs.");
    }
  }
}

runPhaseG1Tests();
