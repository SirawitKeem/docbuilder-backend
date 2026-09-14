import pptxgen from "pptxgenjs";
import JSZip from "jszip";
import fs from "fs";
import path from "path";
import { DEFAULT_FONTS, CURATED_THAI_FONTS, buildGoogleFontsUrl } from "../lib/fonts/fontRegistry.js";

console.log("=================================================");
console.log("🚀 DOCBUILDER SPIKE 1 & 2: FONT WEIGHT & GRADIENTS");
console.log("=================================================\n");

// ==========================================
// SPIKE 1: FONT WEIGHT & FONT REGISTRY
// ==========================================
console.log("--- 1. FONT REGISTRY WEIGHT AUDIT ---");
const allFonts = [...DEFAULT_FONTS, ...CURATED_THAI_FONTS];
for (const font of allFonts) {
  console.log(`Font: ${font.name} (${font.family})`);
  console.log(`  googleFont: ${font.googleFont}`);
  console.log(`  cssStack: ${font.cssStack}`);
}

// 1.3 PPTXGENJS FONT WEIGHT & OOXML TEST
console.log("\n--- 1.3 PPTXGENJS FONT WEIGHT / OOXML TEST ---");
const pptx = new pptxgen();
const slide = pptx.addSlide();

// Add texts with various weight approaches
slide.addText("Kanit Normal (400)", { x: 0.5, y: 0.5, w: 4, h: 0.5, fontFace: "Kanit", fontSize: 16, bold: false });
slide.addText("Kanit Bold (700)", { x: 0.5, y: 1.2, w: 4, h: 0.5, fontFace: "Kanit", fontSize: 16, bold: true });
slide.addText("Kanit Medium (500 as fontFace)", { x: 0.5, y: 1.9, w: 4, h: 0.5, fontFace: "Kanit Medium", fontSize: 16, bold: false });
slide.addText("Kanit SemiBold (600 as fontFace)", { x: 0.5, y: 2.6, w: 4, h: 0.5, fontFace: "Kanit SemiBold", fontSize: 16, bold: false });
slide.addText("Kanit Light (300 as fontFace)", { x: 0.5, y: 3.3, w: 4, h: 0.5, fontFace: "Kanit Light", fontSize: 16, bold: false });

const pptxBuffer = await pptx.write({ outputType: "nodebuffer" });
const zip = await JSZip.loadAsync(pptxBuffer);
const slideXml = await zip.file("ppt/slides/slide1.xml").async("string");

console.log("Extracted slide1.xml text run properties (<a:rPr>):");
const rPrMatches = slideXml.match(/<a:rPr[^>]*>(?:<a:[^>]*>)*<\/a:rPr>/g) || [];
rPrMatches.forEach((rPr, idx) => console.log(`  Run ${idx + 1}: ${rPr}`));

// Also check fontFace mapping in slide1.xml
const typefaceMatches = slideXml.match(/typeface="[^"]*"/g) || [];
console.log("Typefaces in slide1.xml:", [...new Set(typefaceMatches)]);


// ==========================================
// SPIKE 2: GRADIENT FILL IN PPTX
// ==========================================
console.log("\n=========================================");
console.log("--- 2.3 PPTXGENJS GRADIENT FILL TEST ---");
const pptxGrad = new pptxgen();
const gradSlide = pptxGrad.addSlide();

// Test what pptxgenjs accepts for shape fill
try {
  gradSlide.addShape(pptxGrad.shapes.RECTANGLE, {
    x: 1, y: 1, w: 2, h: 1,
    fill: { color: "FF0000" }
  });
  console.log("pptxgenjs fill: { color: 'FF0000' } -> SUCCESS");
} catch (e) {
  console.log("pptxgenjs fill: { color: 'FF0000' } -> ERROR:", e.message);
}

try {
  gradSlide.addShape(pptxGrad.shapes.RECTANGLE, {
    x: 3.5, y: 1, w: 2, h: 1,
    fill: { type: "gradient", color: "FF0000" }
  });
  console.log("pptxgenjs fill: { type: 'gradient', color: 'FF0000' } -> SUCCESS");
} catch (e) {
  console.log("pptxgenjs fill: { type: 'gradient', color: 'FF0000' } -> ERROR:", e.message);
}

try {
  gradSlide.addShape(pptxGrad.shapes.RECTANGLE, {
    x: 1, y: 2.5, w: 2, h: 1,
    fill: { type: "gradient", stops: [{ color: "FF0000", position: 0 }, { color: "0000FF", position: 1 }] }
  });
  console.log("pptxgenjs fill with stops -> SUCCESS");
} catch (e) {
  console.log("pptxgenjs fill with stops -> ERROR:", e.message);
}

const pptxGradBuffer = await pptxGrad.write({ outputType: "nodebuffer" });
const gradZip = await JSZip.loadAsync(pptxGradBuffer);
const gradSlideXml = await gradZip.file("ppt/slides/slide1.xml").async("string");

console.log("Checking shapes in ppt/slides/slide1.xml:");
const spMatches = gradSlideXml.match(/<p:sp>[\s\S]*?<\/p:sp>/g) || [];
spMatches.forEach((sp, i) => {
  console.log(`Shape ${i + 1}:`);
  const fillMatch = sp.match(/<a:(solidFill|gradFill|noFill)[^>]*>[\s\S]*?<\/a:\1>/);
  if (fillMatch) {
    console.log(`  Fill XML: ${fillMatch[0]}`);
  } else {
    console.log(`  No recognized fill XML match! Full spPr:`, sp.match(/<p:spPr>[\s\S]*?<\/p:spPr>/)?.[0]);
  }
});
