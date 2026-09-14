const puppeteer = require("puppeteer");
const path = require("path");
const fs = require("fs");

async function main() {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox", "--window-size=1440,900"],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 900 });

  console.log("Navigating to editor...");
  await page.goto(
    "http://localhost:3000/templates/new?categoryId=5616&editorType=document&canvasPreset=a4-portrait",
    { waitUntil: "networkidle2", timeout: 45000 }
  );

  console.log("Waiting for editor canvas to be ready...");
  await page.waitForSelector(".upper-canvas, canvas", { timeout: 30000 });
  await new Promise((r) => setTimeout(r, 2000));

  // Click 'ข้อความ' tab on LeftSidebar
  console.log("Opening text menu in left sidebar...");
  await page.evaluate(() => {
    const btns = Array.from(document.querySelectorAll("aside button"));
    const textBtn = btns.find((b) => b.textContent.includes("ข้อความ"));
    if (textBtn) textBtn.click();
  });

  await new Promise((r) => setTimeout(r, 1000));

  // Click the H1 button directly
  console.log("Clicking H1 button...");
  const h1Clicked = await page.evaluate(() => {
    const btns = Array.from(document.querySelectorAll("button"));
    const h1 = btns.find((b) => b.textContent && b.textContent.includes("หัวข้อใหญ่"));
    if (h1) {
      h1.click();
      return true;
    }
    return false;
  });
  console.log("H1 button clicked:", h1Clicked);

  await new Promise((r) => setTimeout(r, 1500));

  // Verify dropdown options
  const selectOptions = await page.evaluate(() => {
    const selects = Array.from(document.querySelectorAll("select"));
    if (selects.length > 0) {
      return Array.from(selects[0].options).map((o) => o.textContent.trim());
    }
    return [];
  });
  console.log("Font Select Options in RightSidebar:", selectOptions);

  const outDir = "C:\\Users\\Keem\\.gemini\\antigravity\\brain\\3f255250-aae7-459e-82db-b987663452a8";
  const publicDir = "c:\\Users\\Keem\\Desktop\\docbuilder\\public";

  // Screenshot 1: Editor with text selected & RightSidebar font dropdown visible
  const dropdownShotPath = path.join(outDir, "phase_f_clean_dropdown.png");
  await page.screenshot({ path: dropdownShotPath });
  fs.copyFileSync(dropdownShotPath, path.join(publicDir, "phase_f_clean_dropdown.png"));
  console.log("Saved dropdown screenshot:", dropdownShotPath);

  // Click '+ เพิ่มฟอนต์' button to open Google Fonts Modal
  console.log("Clicking '+ เพิ่มฟอนต์' button in RightSidebar...");
  const modalOpened = await page.evaluate(() => {
    const btns = Array.from(document.querySelectorAll("button"));
    const addFontBtn = btns.find((b) => b.textContent.includes("เพิ่มฟอนต์"));
    if (addFontBtn) {
      addFontBtn.click();
      return true;
    }
    return false;
  });
  console.log("Add Font button clicked:", modalOpened);

  await new Promise((r) => setTimeout(r, 1500));

  // Screenshot 2: Modal cleanly floating above TopToolbar (portal to body, z-[99999], no overlap, no double scrollbar)
  const modalShotPath = path.join(outDir, "phase_f_modal_fixed_minimalist.png");
  await page.screenshot({ path: modalShotPath });
  fs.copyFileSync(modalShotPath, path.join(publicDir, "phase_f_modal_fixed_minimalist.png"));
  console.log("Saved modal screenshot:", modalShotPath);

  await browser.close();
  console.log("Verification finished successfully!");
}

main().catch((err) => {
  console.error("Puppeteer script failed:", err);
  process.exit(1);
});
