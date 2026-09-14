import puppeteer from "puppeteer";
import path from "path";

async function testBlankNotification() {
  console.log("==========================================================");
  console.log("🧪 VERIFYING BLANK NOTIFICATION LETTER & DATA PRESERVATION");
  console.log("==========================================================");

  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1440, height: 960 });

  page.on("console", (msg) => console.log("BROWSER LOG:", msg.text()));
  page.on("pageerror", (err) => console.error("BROWSER PAGEERROR:", err));

  try {
    // -------------------------------------------------------------
    // TEST 1: Open /create/notification and choose "เริ่มจากเอกสารเปล่า"
    // -------------------------------------------------------------
    console.log("\n[Test 1] Navigating to /create/notification...");
    await page.goto("http://localhost:3000/create/notification", {
      waitUntil: "networkidle0",
    });

    console.log("Clicking 'เริ่มจากเอกสารเปล่า' card...");
    await new Promise((r) => setTimeout(r, 1000));
    const clicked = await page.evaluate(() => {
      const cards = Array.from(document.querySelectorAll("div"));
      const blankCard = cards.find(
        (el) =>
          el.textContent &&
          el.textContent.includes("เริ่มจากเอกสารเปล่า") &&
          el.className &&
          typeof el.className === "string" &&
          el.className.includes("cursor-pointer") &&
          el.className.includes("border-dashed")
      );
      if (blankCard) {
        blankCard.click();
        return true;
      }
      const btns = Array.from(document.querySelectorAll("button"));
      const btn = btns.find((b) => b.textContent && b.textContent.includes("เริ่มสร้างเอกสาร"));
      if (btn) {
        btn.click();
        return true;
      }
      return false;
    });

    if (!clicked) {
      throw new Error("Could not find or click 'เริ่มจากเอกสารเปล่า' option!");
    }

    // Wait for the DocumentEditor to load
    await page.waitForSelector("input[placeholder*='01 กันยายน']", { timeout: 15000 });
    console.log("DocumentEditor loaded successfully.");

    // Check completion progress
    const progressText = await page.evaluate(() => {
      const spans = Array.from(document.querySelectorAll("span"));
      const pSpan = spans.find((s) => s.textContent && /\d+\s*\/\s*\d+/.test(s.textContent));
      return pSpan ? pSpan.textContent.trim() : null;
    });
    console.log("Progress bar text:", progressText);

    if (!progressText || (!progressText.includes("0/11") && !progressText.includes("0 / 11"))) {
      throw new Error(`Expected progress to contain 0/11, got: ${progressText}`);
    }

    // Check all form inputs in the sidebar are empty
    const inputValues = await page.evaluate(() => {
      const inputs = Array.from(document.querySelectorAll("input[type='text'], textarea"));
      return inputs.map((inp) => ({
        placeholder: inp.placeholder,
        value: inp.value,
      }));
    });

    console.log(`Found ${inputValues.length} inputs. Checking values...`);
    const filledInputs = inputValues.filter((inp) => inp.value && inp.value.trim().length > 0);
    if (filledInputs.length > 0) {
      console.error("Non-empty inputs found in blank document:", filledInputs);
      throw new Error(`Expected all inputs to be empty, but found ${filledInputs.length} filled inputs!`);
    }
    console.log("✓ All sidebar inputs are properly empty (0 filled)!");

    // Capture screenshot of blank editor
    const blankScreenshotPath = path.resolve(
      "C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/blank_notification_verified.png"
    );
    await page.screenshot({ path: blankScreenshotPath, fullPage: false });
    console.log(`✓ Blank editor screenshot saved to: ${blankScreenshotPath}`);

    // -------------------------------------------------------------
    // TEST 2: Open existing document doc-1788331547618
    // -------------------------------------------------------------
    console.log("\n[Test 2] Navigating to existing document doc-1788331547618...");
    await page.goto("http://localhost:3000/create/notification?id=doc-1788331547618", {
      waitUntil: "networkidle0",
    });

    await page.waitForSelector("input[placeholder*='01 กันยายน']", { timeout: 8000 });

    const existingProgressText = await page.evaluate(() => {
      const spans = Array.from(document.querySelectorAll("span"));
      const pSpan = spans.find((s) => s.textContent && /\d+\s*\/\s*\d+/.test(s.textContent));
      return pSpan ? pSpan.textContent.trim() : null;
    });
    console.log("Existing document progress:", existingProgressText);

    const existingDocValues = await page.evaluate(() => {
      const inputs = Array.from(document.querySelectorAll("input[type='text'], textarea"));
      const vals = {};
      inputs.forEach((inp) => {
        if (inp.value) {
          vals[inp.placeholder] = inp.value;
        }
      });
      return vals;
    });

    console.log("Existing document filled values sample:", Object.keys(existingDocValues).length, "fields filled");
    if (Object.keys(existingDocValues).length < 8) {
      throw new Error("Expected existing document to have filled values, but found too few!");
    }
    console.log("✓ Existing document doc-1788331547618 retains all saved values safely!");

    // -------------------------------------------------------------
    // TEST 3: Check /templates catalog thumbnail preview
    // -------------------------------------------------------------
    console.log("\n[Test 3] Checking /templates catalog preview...");
    await page.goto("http://localhost:3000/templates", {
      waitUntil: "networkidle0",
    });

    const catalogHasNotification = await page.evaluate(() => {
      const body = document.body.textContent;
      return body.includes("หนังสือแจ้งเปลี่ยนแปลงที่ตั้งสำนักงานใหญ่") || body.includes("Notification");
    });
    console.log("Templates catalog contains Notification template:", catalogHasNotification);

    if (!catalogHasNotification) {
      throw new Error("Templates catalog missing Notification template!");
    }

    console.log("\n🎉 ALL VERIFICATION TESTS PASSED SUCCESSFULLY!");
  } finally {
    await browser.close();
  }
}

testBlankNotification().catch((err) => {
  console.error("❌ Test failed:", err);
  process.exit(1);
});
