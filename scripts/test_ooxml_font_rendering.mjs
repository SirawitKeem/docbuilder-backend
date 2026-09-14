import pptxgen from "pptxgenjs";
import path from "path";
import fs from "fs";
import { execSync } from "child_process";

async function main() {
  const pptx = new pptxgen();
  pptx.layout = "LAYOUT_16x9";

  // Slide 1: typeface = "Leelawadee UI" (Single guaranteed system font)
  const slide1 = pptx.addSlide();
  slide1.background = { color: "0F172A" };
  slide1.addShape(pptx.shapes.ROUNDED_RECTANGLE, {
    x: 0.4,
    y: 0.4,
    w: 12.5,
    h: 6.7,
    fill: { color: "1E293B" },
    rectRadius: 0.2,
  });
  slide1.addText("TEST 1: typeface = 'Leelawadee UI' (Guaranteed System Font)", {
    x: 1.0,
    y: 1.0,
    w: 11.0,
    h: 0.6,
    fontSize: 16,
    fontFace: "Leelawadee UI",
    bold: true,
    color: "38BDF8",
    margin: 0,
  });
  slide1.addText("กลยุทธ์การทรานส์ฟอร์มธุรกิจสู่ยุคดิจิทัล 2026", {
    x: 1.0,
    y: 1.8,
    w: 11.0,
    h: 0.8,
    fontSize: 28,
    fontFace: "Leelawadee UI",
    bold: true,
    color: "FFFFFF",
    margin: 0,
  });
  slide1.addText("สร้างสรรค์เอกสารและงานนำเสนอระดับพรีเมียมด้วยระบบ DocBuilder Platform", {
    x: 1.0,
    y: 2.7,
    w: 11.0,
    h: 0.5,
    fontSize: 14,
    fontFace: "Leelawadee UI",
    color: "94A3B8",
    margin: 0,
  });
  slide1.addText("• รองรับฟอนต์ภาษาไทยแท้ 100% ไม่มีปัญหาการซ้อนทับหรือตัดคำผิดพลาด\n• เลขไทยและอารบิก: ๑๒๓๔๕ / 12345 และตัวอักษรภาษาอังกฤษแสดงผลถูกต้อง", {
    x: 1.0,
    y: 3.5,
    w: 11.0,
    h: 1.2,
    fontSize: 14,
    fontFace: "Leelawadee UI",
    color: "CBD5E1",
    lineSpacingMultiple: 1.4,
    margin: 0,
  });

  // Slide 2: typeface = "Chonburi" (Single primary Google font name - not installed on machine)
  const slide2 = pptx.addSlide();
  slide2.background = { color: "0F172A" };
  slide2.addShape(pptx.shapes.ROUNDED_RECTANGLE, {
    x: 0.4,
    y: 0.4,
    w: 12.5,
    h: 6.7,
    fill: { color: "1E293B" },
    rectRadius: 0.2,
  });
  slide2.addText("TEST 2: typeface = 'Chonburi' (Single Primary Font Name - Uninstalled)", {
    x: 1.0,
    y: 1.0,
    w: 11.0,
    h: 0.6,
    fontSize: 16,
    fontFace: "Chonburi",
    bold: true,
    color: "38BDF8",
    margin: 0,
  });
  slide2.addText("กลยุทธ์การทรานส์ฟอร์มธุรกิจสู่ยุคดิจิทัล 2026", {
    x: 1.0,
    y: 1.8,
    w: 11.0,
    h: 0.8,
    fontSize: 28,
    fontFace: "Chonburi",
    bold: true,
    color: "FFFFFF",
    margin: 0,
  });
  slide2.addText("สร้างสรรค์เอกสารและงานนำเสนอระดับพรีเมียมด้วยระบบ DocBuilder Platform", {
    x: 1.0,
    y: 2.7,
    w: 11.0,
    h: 0.5,
    fontSize: 14,
    fontFace: "Chonburi",
    color: "94A3B8",
    margin: 0,
  });

  // Slide 3: typeface = "TH Sarabun New" (Standard Thai Font installed on machine)
  const slide3 = pptx.addSlide();
  slide3.background = { color: "0F172A" };
  slide3.addShape(pptx.shapes.ROUNDED_RECTANGLE, {
    x: 0.4,
    y: 0.4,
    w: 12.5,
    h: 6.7,
    fill: { color: "1E293B" },
    rectRadius: 0.2,
  });
  slide3.addText("TEST 3: typeface = 'TH Sarabun New' (Installed Thai Government Font)", {
    x: 1.0,
    y: 1.0,
    w: 11.0,
    h: 0.6,
    fontSize: 16,
    fontFace: "TH Sarabun New",
    bold: true,
    color: "38BDF8",
    margin: 0,
  });
  slide3.addText("กลยุทธ์การทรานส์ฟอร์มธุรกิจสู่ยุคดิจิทัล 2026", {
    x: 1.0,
    y: 1.8,
    w: 11.0,
    h: 0.8,
    fontSize: 32,
    fontFace: "TH Sarabun New",
    bold: true,
    color: "FFFFFF",
    margin: 0,
  });
  slide3.addText("สร้างสรรค์เอกสารและงานนำเสนอระดับพรีเมียมด้วยระบบ DocBuilder Platform", {
    x: 1.0,
    y: 2.7,
    w: 11.0,
    h: 0.5,
    fontSize: 18,
    fontFace: "TH Sarabun New",
    color: "94A3B8",
    margin: 0,
  });

  const outDir = "C:\\Users\\Keem\\.gemini\\antigravity\\brain\\3f255250-aae7-459e-82db-b987663452a8";
  const pptxPath = path.join(outDir, "ooxml_font_comparison.pptx");
  const publicPptxPath = "c:\\Users\\Keem\\Desktop\\docbuilder\\public\\ooxml_font_comparison.pptx";

  await pptx.writeFile({ fileName: pptxPath });
  fs.copyFileSync(pptxPath, publicPptxPath);
  console.log("PPTX generated:", pptxPath);

  // Render slides with PowerPoint COM automation
  console.log("Rendering slides via PowerPoint COM Automation...");
  const psScript = `
    $ppt = New-Object -ComObject PowerPoint.Application
    $pres = $ppt.Presentations.Open('${pptxPath.replace(/\\/g, "\\\\")}', $true, $false, $false)
    $slideIndex = 1
    foreach ($slide in $pres.Slides) {
      $imgName = "ooxml_slide" + $slideIndex + "_render.png"
      $outImg = Join-Path '${outDir.replace(/\\/g, "\\\\")}' $imgName
      $slide.Export($outImg, "PNG", 1920, 1080)
      $pubImg = Join-Path 'c:\\\\Users\\\\Keem\\\\Desktop\\\\docbuilder\\\\public' $imgName
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

  fs.writeFileSync("scripts/render_ooxml_test.ps1", psScript, "utf8");
  execSync("powershell -ExecutionPolicy Bypass -File scripts/render_ooxml_test.ps1", { stdio: "inherit" });
  console.log("All slides rendered!");
}

main().catch((err) => {
  console.error("Test failed:", err);
  process.exit(1);
});
