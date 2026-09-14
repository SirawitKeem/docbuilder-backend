import fs from "fs";
import path from "path";
import { execSync } from "child_process";

async function main() {
  console.log("=== 1. CALLING LIVE /api/export-pptx TO GENERATE PRESENTATION ===");

  const payload = {
    name: "DocBuilder Strategy 2026",
    canvasPreset: "slide-16-9",
    theme: { backgroundColor: "#0F172A" },
    pages: [
      {
        id: "slide_1",
        name: "Slide 1",
        json: {
          version: "5.3.0",
          objects: [
            {
              type: "rect",
              left: 38,
              top: 38,
              width: 1144,
              height: 610,
              fill: "#1E293B",
              rx: 20,
              ry: 20,
            },
            {
              type: "textbox",
              left: 95,
              top: 95,
              width: 600,
              text: "EXECUTIVE STRATEGY • 2026",
              fontSize: 14,
              fontWeight: "bold",
              fontFamily: "'Kanit', sans-serif",
              fill: "#38BDF8",
            },
            {
              type: "textbox",
              left: 95,
              top: 150,
              width: 1000,
              text: "กลยุทธ์การทรานส์ฟอร์มธุรกิจสู่ยุคดิจิทัล 2026",
              fontSize: 32,
              fontWeight: "bold",
              fontFamily: "'Chonburi', cursive",
              fill: "#FFFFFF",
            },
            {
              type: "textbox",
              left: 95,
              top: 240,
              width: 1000,
              text: "สร้างสรรค์เอกสารและงานนำเสนอระดับพรีเมียมด้วยระบบ DocBuilder Platform",
              fontSize: 16,
              fontWeight: "normal",
              fontFamily: "'Prompt', sans-serif",
              fill: "#94A3B8",
            },
            {
              type: "textbox",
              left: 95,
              top: 320,
              width: 1000,
              text: "• ยกระดับการสื่อสารองค์กรด้วยระบบจัดเก็บแบบอักษรส่วนกลาง (Unified Font Registry)\n• รองรับฟอนต์ภาษาไทยแท้ พร้อม OOXML Single Typeface มาตรฐานสากล 100%\n• การประมวลผลความเร็วสูง และไร้รอยต่อระหว่างหน้าเอกสาร (Docs) และสไลด์ (Slides)",
              fontSize: 14,
              fontWeight: "normal",
              fontFamily: "'Noto Sans Thai', sans-serif",
              fill: "#CBD5E1",
              lineHeight: 1.6,
            },
            {
              type: "textbox",
              left: 95,
              top: 550,
              width: 800,
              text: "ผู้นำเสนอ: นายศรายุทธ โกสิยารักษ์ | บริษัท เครสท์ เซนโด จำกัด",
              fontSize: 12,
              fontWeight: "normal",
              fontFamily: "'Sarabun', sans-serif",
              fill: "#64748B",
            },
          ],
        },
      },
      {
        id: "slide_2",
        name: "Slide 2",
        json: {
          version: "5.3.0",
          objects: [
            {
              type: "rect",
              left: 38,
              top: 38,
              width: 1144,
              height: 610,
              fill: "#FFFFFF",
              rx: 16,
              ry: 16,
            },
            {
              type: "textbox",
              left: 80,
              top: 80,
              width: 1000,
              text: "แผนงบประมาณและการจัดสรรทรัพยากร (Budget Summary)",
              fontSize: 24,
              fontWeight: "bold",
              fontFamily: "'Sarabun', sans-serif",
              fill: "#1E293B",
            },
            {
              type: "textbox",
              left: 80,
              top: 130,
              width: 1000,
              text: "ตารางสรุปงบประมาณการดำเนินงานโครงการประจำปี 2569",
              fontSize: 14,
              fontWeight: "normal",
              fontFamily: "'Sarabun', sans-serif",
              fill: "#64748B",
            },
            {
              type: "group",
              isDocTable: true,
              left: 80,
              top: 190,
              docTableData: {
                width: 1000,
                themeColor: "#059669",
                vatRate: 7,
                items: [
                  {
                    id: "it1",
                    title: "ระบบบริหารจัดการเอกสารองค์กร (DocBuilder Enterprise)",
                    qty: 1,
                    unitPrice: 150000,
                  },
                  {
                    id: "it2",
                    title: "บริการคลาวด์เซิร์ฟเวอร์และความปลอดภัยขั้นสูง (Cloud Security)",
                    qty: 12,
                    unitPrice: 18500,
                  },
                  {
                    id: "it3",
                    title: "การฝึกอบรมบุคลากรและการสนับสนุนทางเทคนิค 24/7",
                    qty: 1,
                    unitPrice: 45000,
                  },
                ],
              },
            },
          ],
        },
      },
    ],
  };

  const res = await fetch("http://localhost:3000/api/export-pptx", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (res.status !== 200) {
    const err = await res.text();
    console.error("Export failed:", err);
    process.exit(1);
  }

  const pptxBuf = Buffer.from(await res.arrayBuffer());
  console.log("PPTX Generated. Buffer size:", pptxBuf.length, "bytes");

  const artifactDir = "C:\\Users\\Keem\\.gemini\\antigravity\\brain\\3f255250-aae7-459e-82db-b987663452a8";
  const publicDir = "c:\\Users\\Keem\\Desktop\\docbuilder\\public";
  const projectRootDir = "c:\\Users\\Keem\\Desktop\\docbuilder";

  const targetFilename = "phase_f_verified_presentation.pptx";
  const artifactPptx = path.join(artifactDir, targetFilename);
  const publicPptx = path.join(publicDir, targetFilename);
  const rootPptx = path.join(projectRootDir, targetFilename);

  fs.writeFileSync(artifactPptx, pptxBuf);
  fs.writeFileSync(publicPptx, pptxBuf);
  fs.writeFileSync(rootPptx, pptxBuf);

  console.log("Saved PPTX to all 3 target destinations!");

  console.log("\n=== 2. VERIFYING OOXML TYPEFACE COMPLIANCE (ZERO COMMAS) ===");
  // Unpack PPTX
  const zipPath = path.join(artifactDir, "temp_verify.zip");
  const extractDir = path.join(artifactDir, "pptx_verify_extracted");
  fs.copyFileSync(artifactPptx, zipPath);

  execSync(`powershell -Command "Expand-Archive -Path '${zipPath}' -DestinationPath '${extractDir}' -Force"`);

  const slide1Xml = fs.readFileSync(path.join(extractDir, "ppt", "slides", "slide1.xml"), "utf-8");
  const slide2Xml = fs.readFileSync(path.join(extractDir, "ppt", "slides", "slide2.xml"), "utf-8");

  const typefaceRegex = /typeface="([^"]*)"/g;
  let match;
  const slide1Typefaces = [];
  while ((match = typefaceRegex.exec(slide1Xml)) !== null) {
    slide1Typefaces.push(match[1]);
  }

  const slide2Typefaces = [];
  while ((match = typefaceRegex.exec(slide2Xml)) !== null) {
    slide2Typefaces.push(match[1]);
  }

  console.log("Slide 1 Typefaces found in OOXML:", Array.from(new Set(slide1Typefaces)));
  console.log("Slide 2 Typefaces found in OOXML:", Array.from(new Set(slide2Typefaces)));

  const hasComma1 = slide1Typefaces.some((t) => t.includes(","));
  const hasComma2 = slide2Typefaces.some((t) => t.includes(","));

  if (hasComma1 || hasComma2) {
    console.error("❌ FAILED: Found comma in OOXML typeface attribute!");
    process.exit(1);
  } else {
    console.log("✅ PASSED: 100% compliant single font names in all OOXML typeface attributes! ZERO commas!");
  }

  console.log("\n=== 3. RENDERING SLIDES WITH POWERPOINT COM AUTOMATION ===");
  const psScript = `
    $ppt = New-Object -ComObject PowerPoint.Application
    $pres = $ppt.Presentations.Open('${artifactPptx.replace(/\\/g, "\\\\")}', $true, $false, $false)
    $slideIndex = 1
    foreach ($slide in $pres.Slides) {
      $imgName = "phase_f_slide" + $slideIndex + "_verified.png"
      $outImg = Join-Path '${artifactDir.replace(/\\/g, "\\\\")}' $imgName
      $slide.Export($outImg, "PNG", 1920, 1080)
      $pubImg = Join-Path '${publicDir.replace(/\\/g, "\\\\")}' $imgName
      Copy-Item $outImg $pubImg -Force
      Write-Host "Exported slide $slideIndex to $outImg"
      $slideIndex++
    }
    $pres.Close()
    $ppt.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ppt) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
  `;

  fs.writeFileSync("scripts/render_verified_pptx.ps1", psScript, "utf8");
  execSync("powershell -ExecutionPolicy Bypass -File scripts/render_verified_pptx.ps1", { stdio: "inherit" });

  console.log("\n🎉 ALL VERIFICATION STEPS COMPLETED SUCCESSFULLY!");
}

main().catch((err) => {
  console.error("Verification error:", err);
  process.exit(1);
});
