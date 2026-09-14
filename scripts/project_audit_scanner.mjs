import fs from "fs";
import path from "path";

const ROOT = process.cwd();

// 1. Load ESLint Report
let eslintData = [];
if (fs.existsSync("eslint_report.json")) {
  eslintData = JSON.parse(fs.readFileSync("eslint_report.json", "utf-8"));
}

// Helper: recursively find files
function getAllFiles(dir, exts = [".js", ".jsx", ".ts", ".tsx", ".mjs", ".json", ".css"]) {
  let results = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.name === "node_modules" || entry.name === ".next" || entry.name === ".git" || entry.name === "public") continue;
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results = results.concat(getAllFiles(fullPath, exts));
    } else {
      if (exts.some((ext) => entry.name.endsWith(ext))) {
        results.push(fullPath);
      }
    }
  }
  return results;
}

const allCodeFiles = getAllFiles(ROOT, [".js", ".jsx", ".ts", ".tsx", ".mjs"]);
console.log(`Found ${allCodeFiles.length} source code files.`);

// Read all code content into memory for fast searching
const fileContents = new Map();
for (const file of allCodeFiles) {
  fileContents.set(file, fs.readFileSync(file, "utf-8"));
}

// -------------------------------------------------------------
// CHECK 1: Files with no import / reference anywhere
// -------------------------------------------------------------
const nextConventions = [
  "page.jsx", "page.tsx", "page.js",
  "layout.jsx", "layout.tsx", "layout.js",
  "route.js", "route.ts",
  "not-found.jsx", "not-found.tsx",
  "loading.jsx", "error.jsx",
  "next.config.ts", "next.config.js", "next.config.mjs",
  "postcss.config.mjs", "postcss.config.js",
  "tailwind.config.ts", "tailwind.config.js",
  "eslint.config.mjs", "package.json", "tsconfig.json"
];

const unreferencedFiles = [];
const uncertainFiles = [];

for (const filePath of allCodeFiles) {
  const relPath = path.relative(ROOT, filePath).replace(/\\/g, "/");
  const baseName = path.basename(filePath);
  const nameWithoutExt = baseName.replace(/\.[^.]+$/, "");

  // Ignore Next.js routing and config files
  if (nextConventions.includes(baseName)) continue;
  if (relPath.startsWith("scripts/")) continue; // scripts are CLI/standalone

  // Look for references in all other files
  let referenced = false;
  let dynamic = false;

  for (const [otherFile, content] of fileContents.entries()) {
    if (otherFile === filePath) continue;

    // Check if filename without extension is mentioned (import ... from './Name')
    if (content.includes(nameWithoutExt)) {
      referenced = true;
      break;
    }
    // Check if relative path or alias is mentioned
    const aliasPath = `@/${relPath.replace(/\.[^.]+$/, "")}`;
    if (content.includes(aliasPath)) {
      referenced = true;
      break;
    }
  }

  if (!referenced) {
    // Check if it might be dynamically used (e.g. database adapters, dynamic components)
    if (relPath.includes("components/document/") || relPath.includes("adapters/")) {
      uncertainFiles.push({
        path: relPath,
        reason: "ไม่มีการ static import โดยตรง แต่อาจถูกโหลดแบบ dynamic component หรือ dynamic adapter ผ่าน registry/category mapping"
      });
    } else {
      unreferencedFiles.push({
        path: relPath,
        reason: "ไม่พบการ import หรือ reference ชื่อไฟล์/path ในโค้ดไฟล์อื่นใดในโปรเจคเลย"
      });
    }
  }
}

// -------------------------------------------------------------
// CHECK 3 & 4: Unused Imports and Unused Variables (From ESLint + AST)
// -------------------------------------------------------------
const unusedImports = [];
const unusedVariables = [];

for (const fileReport of eslintData) {
  const relPath = path.relative(ROOT, fileReport.filePath).replace(/\\/g, "/");
  if (relPath.startsWith("scripts/") || relPath.startsWith("node_modules/")) continue;

  const fileContent = fs.readFileSync(fileReport.filePath, "utf-8");
  const lines = fileContent.split("\n");

  for (const msg of fileReport.messages) {
    if (msg.ruleId === "@typescript-eslint/no-unused-vars" || msg.ruleId === "no-unused-vars") {
      const lineNum = msg.line;
      const lineText = lines[lineNum - 1] || "";
      const varNameMatch = msg.message.match(/'([^']+)'/);
      const varName = varNameMatch ? varNameMatch[1] : "unknown";

      // Check if this line is part of an import statement
      const isImport = lineText.trim().startsWith("import") || lineText.includes("from ") || lineText.trim().startsWith("} from");
      // Check surrounding lines if multi-line import
      let multiLineImport = false;
      for (let i = Math.max(0, lineNum - 10); i < Math.min(lines.length, lineNum + 5); i++) {
        if (lines[i].includes("from ") && (lines[i].includes('"') || lines[i].includes("'"))) {
          if (i >= lineNum - 1) multiLineImport = true;
        }
      }

      if (isImport || (lineText.trim().endsWith(",") && multiLineImport)) {
        unusedImports.push({
          path: relPath,
          line: lineNum,
          name: varName,
          codeSnippet: lineText.trim(),
          reason: `Import '${varName}' เข้ามาในไฟล์แต่ไม่เคยถูกเรียกใช้งานในโค้ด`
        });
      } else {
        unusedVariables.push({
          path: relPath,
          line: lineNum,
          name: varName,
          codeSnippet: lineText.trim(),
          reason: `ประกาศตัวแปร/state/parameter '${varName}' แต่ไม่เคยถูกนำไปใช้งาน`
        });
      }
    }
  }
}

// -------------------------------------------------------------
// CHECK 5: Dependencies in package.json with no import in code
// -------------------------------------------------------------
const pkg = JSON.parse(fs.readFileSync("package.json", "utf-8"));
const deps = Object.keys(pkg.dependencies || {});
const unusedDeps = [];
const uncertainDeps = [];

// Framework runtime dependencies that might not be directly imported in src
const frameworkRuntime = [
  "next", "react", "react-dom", "react-native-web"
];

for (const dep of deps) {
  let found = false;
  for (const [filePath, content] of fileContents.entries()) {
    if (content.includes(`"${dep}"`) || content.includes(`'${dep}'`) || content.includes(`from "${dep}`) || content.includes(`from '${dep}`)) {
      found = true;
      break;
    }
  }

  if (!found) {
    if (frameworkRuntime.includes(dep) || dep.startsWith("@types/")) {
      uncertainDeps.push({
        name: dep,
        reason: "ไม่พบการ import โดยตรงใน application code แต่เป็น Next.js / React peer/runtime dependency หรือ engine requirement"
      });
    } else {
      unusedDeps.push({
        name: dep,
        reason: `มีระบุใน package.json แต่ไม่พบการ import หรือ require ใน source code ใดๆ เลย`
      });
    }
  }
}

// Output Results as JSON for step 2 processing
const auditResult = {
  unreferencedFiles,
  uncertainFiles,
  unusedImports,
  unusedVariables,
  unusedDeps,
  uncertainDeps
};

fs.writeFileSync("audit_scan_result.json", JSON.stringify(auditResult, null, 2), "utf-8");
console.log("Audit Scan Completed:");
console.log(`- Unreferenced Files: ${unreferencedFiles.length} (Uncertain: ${uncertainFiles.length})`);
console.log(`- Unused Imports: ${unusedImports.length}`);
console.log(`- Unused Variables: ${unusedVariables.length}`);
console.log(`- Unused Dependencies: ${unusedDeps.length} (Uncertain: ${uncertainDeps.length})`);
