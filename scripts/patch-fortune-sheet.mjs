import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");

const targets = [
  {
    path: "node_modules/@fortune-sheet/react/dist/index.esm.js",
    requiredPatterns: [
      { name: "Border combo text", regex: /\\u8FB9\\u6846\\u8BBE\\u7F6E|边框设置/g, replaceTo: "Border" },
      { name: "Merge combo text", regex: /\\u5408\\u5E76\\u5355\\u5143\\u683C|合并单元格/g, replaceTo: "Merge cells" },
      { name: "Image Crop text", regex: /\\u88C1\\u526A|裁剪/g, replaceTo: "Crop" },
      { name: "Image Restore text", regex: /\\u6062\\u590D\\u539F\\u56FE|恢复原图/g, replaceTo: "Restore" },
      { name: "Image Delete text", regex: /\\u5220\\u9664|删除/g, replaceTo: "Delete" },
    ],
  },
  {
    path: "node_modules/@fortune-sheet/react/dist/index.js",
    requiredPatterns: [
      { name: "Border combo text", regex: /\\u8FB9\\u6846\\u8BBE\\u7F6E|边框设置/g, replaceTo: "Border" },
      { name: "Merge combo text", regex: /\\u5408\\u5E76\\u5355\\u5143\\u683C|合并单元格/g, replaceTo: "Merge cells" },
      { name: "Image Crop text", regex: /\\u88C1\\u526A|裁剪/g, replaceTo: "Crop" },
      { name: "Image Restore text", regex: /\\u6062\\u590D\\u539F\\u56FE|恢复原图/g, replaceTo: "Restore" },
      { name: "Image Delete text", regex: /\\u5220\\u9664|删除/g, replaceTo: "Delete" },
    ],
  },
  {
    path: "node_modules/@fortune-sheet/react/dist/index.umd.js",
    requiredPatterns: [
      { name: "Merge combo text", regex: /合并单元格/g, replaceTo: "Merge cells" },
      { name: "Image Delete text", regex: /删除/g, replaceTo: "Delete" },
    ],
  },
  {
    path: "node_modules/@fortune-sheet/react/dist/index.umd.min.js",
    requiredPatterns: [
      { name: "Border combo text", regex: /边框设置/g, replaceTo: "Border" },
      { name: "Merge combo text", regex: /合并单元格/g, replaceTo: "Merge cells" },
      { name: "Image Crop text", regex: /裁剪/g, replaceTo: "Crop" },
      { name: "Image Restore text", regex: /恢复原图/g, replaceTo: "Restore" },
      { name: "Image Delete text", regex: /删除/g, replaceTo: "Delete" },
    ],
  },
];

console.log("================================================================================");
console.log("🔧 RUNNING FORTUNE-SHEET PATCH WITH STRICT FAIL-LOUD SAFETY NET");
console.log("================================================================================");

let totalModified = 0;

for (const target of targets) {
  const fullPath = path.join(rootDir, target.path);
  if (!fs.existsSync(fullPath)) {
    console.error(`🚨 FATAL ERROR: Expected target file does not exist: "${target.path}"`);
    console.error("The package @fortune-sheet/react may have been removed or restructured.");
    process.exit(1);
  }

  let content = fs.readFileSync(fullPath, "utf-8");
  let fileModified = false;

  for (const rule of target.requiredPatterns) {
    // Check if pattern is present in original form
    if (rule.regex.test(content)) {
      content = content.replace(rule.regex, rule.replaceTo);
      fileModified = true;
      console.log(`  [PATCHED] ${target.path} -> ${rule.name}`);
    } else {
      // If the target pattern was NOT found, verify if it was ALREADY patched with the replacement text
      // If it neither has the pattern NOR the replacement, FAIL LOUD!
      const alreadyPatchedCheck = content.includes(rule.replaceTo);
      if (!alreadyPatchedCheck) {
        console.error(`🚨 FATAL ERROR: Required string "${rule.name}" not found in "${target.path}"!`);
        console.error("The upstream library bundle format has changed. Patch cannot be applied safely.");
        process.exit(1);
      }
      // If already patched, it's safe and idempotent.
    }
  }

  if (fileModified) {
    fs.writeFileSync(fullPath, content, "utf-8");
    totalModified++;
  } else {
    console.log(`  [VERIFIED] ${target.path} is already fully patched and verified.`);
  }
}

console.log(`✅ FortuneSheet patch check completed cleanly. (${totalModified} file(s) patched)`);