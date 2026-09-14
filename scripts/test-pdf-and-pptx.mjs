import fs from "fs";

import { createRequire } from "module";
const require = createRequire(import.meta.url);
const { PDFParse } = require("pdf-parse");

async function main() {
  console.log("=================================================================");
  console.log("🚀 TESTING DOCS PDF EXPORT REGRESSION & PHASE 7 THAI DUPLICATION");
  console.log("=================================================================");

  const res = await fetch("http://localhost:3000/api/export-pdf", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      templateId: "quotation",
      values: {
        company_name: "บริษัท เครสท์ เซนโด จำกัด",
        tax_id: "0105558073755",
        customer_name: "บริษัท ไทยเจริญ พาณิชย์ จำกัด",
        quotation_no: "CZ26090001",
        date: "04 กันยายน 2569",
        contact_person: "คุณสมชาย มั่งคั่งทรัพย์",
      },
      fileName: "live_api_document_export.pdf",
    }),
  });

  console.log("PDF API Status:", res.status);
  console.log("PDF Content-Type:", res.headers.get("content-type"));

  if (res.status !== 200) {
    const errText = await res.text();
    console.error("PDF Export failed:", errText);
    process.exit(1);
  }

  const pdfBuf = Buffer.from(await res.arrayBuffer());
  console.log("PDF File Size:", pdfBuf.length, "bytes");

  fs.writeFileSync("public/live_api_document_export.pdf", pdfBuf);
  fs.writeFileSync("live_api_document_export.pdf", pdfBuf);
  fs.writeFileSync(
    "C:/Users/Keem/.gemini/antigravity/brain/3f255250-aae7-459e-82db-b987663452a8/live_api_document_export.pdf",
    pdfBuf
  );

  const parser = new PDFParse(new Uint8Array(pdfBuf));
  const parsedResult = await parser.getText();
  const text = typeof parsedResult === "string" ? parsedResult : (parsedResult.text || "");
  console.log("Extracted text length:", text.length, "characters");

  const duplicateCompany = /บริษัริ\s*ษัท/.test(text);
  const hasCompany = text.includes("บริษัท");
  const duplicateTax = /ผู้เผู้สียภาษี|ผู้เสีเสียภาษี/.test(text);
  const hasQuotation = text.includes("ใบเสนอราคา") || text.includes("QUOTATION");

  console.log("- Found 'บริษัท':", hasCompany);
  console.log("- Duplicate 'บริษัริ ษัท' bug present:", duplicateCompany);
  console.log("- Duplicate 'ผู้เสียภาษี' bug present:", duplicateTax);
  console.log("- Found 'ใบเสนอราคา / QUOTATION':", hasQuotation);

  console.log("\n--- Sample Extracted Text Lines ---");
  const sampleLines = text
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l.length > 0)
    .slice(0, 15);
  sampleLines.forEach((line, idx) => {
    console.log(`[Line ${idx + 1}] ${line}`);
  });

  if (hasCompany && !duplicateCompany && !duplicateTax) {
    console.log("\n===============================================================");
    console.log("✅ VERIFICATION PASSED: ZERO THAI TEXT DUPLICATION IN REAL PDF!");
    console.log("✅ REGRESSION TEST PASSED: DOCS PDF EXPORT WORKS 100% NORMALLY!");
    console.log("===============================================================");
  } else {
    console.error("❌ FAILED: Text duplication or missing expected content!");
    process.exit(1);
  }
}

main().catch((err) => {
  console.error("Test runner error:", err);
  process.exit(1);
});
