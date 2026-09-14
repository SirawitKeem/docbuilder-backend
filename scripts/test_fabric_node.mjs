import { createRequire } from "module";
const require = createRequire(import.meta.url);
const fabric = require("../node_modules/fabric/dist/index.node.cjs");

console.log("Fabric loaded in Node successfully!");
console.log("fabric.Canvas:", !!fabric.Canvas);
console.log("fabric.Gradient:", !!fabric.Gradient);
console.log("fabric.Textbox:", !!fabric.Textbox);

// 1. Test Font Weight serialization & deserialization
const canvas = new fabric.Canvas(null, { width: 800, height: 600 });
const weights = [300, 400, 500, 600, 700, 800, "300", "600", "bold", "normal"];
const weightResults = [];

for (const w of weights) {
  const tb = new fabric.Textbox("ทดสอบน้ำหนัก", {
    left: 20,
    top: 20,
    fontSize: 20,
    fontFamily: "'Kanit', sans-serif",
    fontWeight: w,
  });
  canvas.add(tb);
  const json = canvas.toJSON();
  const serialized = json.objects[json.objects.length - 1].fontWeight;
  weightResults.push({ input: w, serialized, type: typeof serialized });
  canvas.remove(tb);
}

// 2. Test Gradient serialization & deserialization
const linearGrad = new fabric.Gradient({
  type: "linear",
  coords: { x1: 0, y1: 0, x2: 200, y2: 100 },
  colorStops: [
    { offset: 0, color: "#FF0000" },
    { offset: 0.5, color: "#00FF00" },
    { offset: 1, color: "#0000FF" },
  ],
});

const radialGrad = new fabric.Gradient({
  type: "radial",
  coords: { r1: 0, r2: 80, x1: 50, y1: 50, x2: 50, y2: 50 },
  colorStops: [
    { offset: 0, color: "#FFFFFF" },
    { offset: 1, color: "#4F46E5" },
  ],
});

const rect = new fabric.Rect({
  left: 50,
  top: 50,
  width: 200,
  height: 100,
  fill: linearGrad,
});

const circle = new fabric.Circle({
  left: 300,
  top: 50,
  radius: 50,
  fill: radialGrad,
});

const thaiText = new fabric.Textbox("บริษัท เครสท์ เซนโด จำกัด", {
  left: 50,
  top: 200,
  fontSize: 24,
  fontFamily: "'Noto Sans Thai', sans-serif",
  fontWeight: 600,
});

canvas.add(rect, circle, thaiText);
canvas.renderAll();

const serializedJson = canvas.toJSON();
console.log("\nSerialized Rect fill:", JSON.stringify(serializedJson.objects[0].fill, null, 2));

// Reload into second canvas
const canvas2 = new fabric.Canvas(null, { width: 800, height: 600 });
await canvas2.loadFromJSON(serializedJson);
canvas2.renderAll();

const loadedRect = canvas2.getObjects()[0];
const loadedCircle = canvas2.getObjects()[1];
const loadedText = canvas2.getObjects()[2];

console.log("\nLoaded Rect fill instanceof fabric.Gradient:", loadedRect.fill instanceof fabric.Gradient);
console.log("Loaded Rect fill type:", loadedRect.fill?.type);
console.log("Loaded Rect colorStops count:", loadedRect.fill?.colorStops?.length);
console.log("Loaded Text fontWeight:", loadedText.fontWeight, "type:", typeof loadedText.fontWeight);

// Test toSVG
const svg = canvas2.toSVG();
console.log("\nSVG output contains <linearGradient>:", svg.includes("<linearGradient"));
console.log("SVG output contains <radialGradient>:", svg.includes("<radialGradient"));
console.log("SVG output contains <defs>:", svg.includes("<defs"));
console.log("SVG snippet with defs:\n", svg.match(/<defs>[\s\S]*?<\/defs>/)?.[0]);

console.log("\nWeights Results:", JSON.stringify(weightResults, null, 2));
