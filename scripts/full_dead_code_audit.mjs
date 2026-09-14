import fs from "fs";
import path from "path";
import ts from "typescript";

const ROOT = process.cwd();

// Directories to scan (Application code only)
const APP_DIRS = ["app", "components", "lib", "context", "data"];

function getAppFiles() {
  let results = [];
  function scan(dir) {
    if (!fs.existsSync(dir)) return;
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.name === "node_modules" || entry.name === ".next" || entry.name === ".git") continue;
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        scan(fullPath);
      } else if (/\.(jsx?|tsx?)$/.test(entry.name)) {
        results.push(fullPath);
      }
    }
  }
  for (const d of APP_DIRS) {
    scan(path.join(ROOT, d));
  }
  return results;
}

const appFiles = getAppFiles();
console.log(`Scanning ${appFiles.length} application files...`);

// Parse AST for each file
const fileMap = new Map();

for (const filePath of appFiles) {
  const relPath = path.relative(ROOT, filePath).replace(/\\/g, "/");
  const content = fs.readFileSync(filePath, "utf-8");
  const isJsx = relPath.endsWith(".jsx") || relPath.endsWith(".tsx");

  const sf = ts.createSourceFile(
    filePath,
    content,
    ts.ScriptTarget.Latest,
    true,
    isJsx ? ts.ScriptKind.JSX : ts.ScriptKind.JS
  );

  const imports = []; // { name, isDefault, moduleSpecifier, line, node }
  const exports = []; // { name, isDefault, line, node }
  const declaredVars = []; // { name, line, isState }
  const identifiersUsed = new Set();

  function visit(node) {
    // Collect imports
    if (ts.isImportDeclaration(node)) {
      const moduleSpecifier = node.moduleSpecifier.text;
      const importClause = node.importClause;
      if (importClause) {
        if (importClause.name) {
          const line = sf.getLineAndCharacterOfPosition(importClause.name.getStart()).line + 1;
          imports.push({ name: importClause.name.text, isDefault: true, moduleSpecifier, line });
        }
        if (importClause.namedBindings) {
          if (ts.isNamedImports(importClause.namedBindings)) {
            for (const elem of importClause.namedBindings.elements) {
              const line = sf.getLineAndCharacterOfPosition(elem.name.getStart()).line + 1;
              imports.push({ name: elem.name.text, isDefault: false, moduleSpecifier, line });
            }
          } else if (ts.isNamespaceImport(importClause.namedBindings)) {
            const line = sf.getLineAndCharacterOfPosition(importClause.namedBindings.name.getStart()).line + 1;
            imports.push({ name: importClause.namedBindings.name.text, isDefault: false, moduleSpecifier, line });
          }
        }
      }
    }

    // Collect exports
    const isExported =
      (node.modifiers && node.modifiers.some((m) => m.kind === ts.SyntaxKind.ExportKeyword)) ||
      ts.isExportAssignment(node) ||
      ts.isExportDeclaration(node);

    const isDefault =
      node.modifiers && node.modifiers.some((m) => m.kind === ts.SyntaxKind.DefaultKeyword);

    if (ts.isFunctionDeclaration(node) && node.name && isExported) {
      const line = sf.getLineAndCharacterOfPosition(node.name.getStart()).line + 1;
      exports.push({ name: node.name.text, isDefault: !!isDefault, type: "function", line });
    } else if (ts.isVariableStatement(node) && isExported) {
      for (const decl of node.declarationList.declarations) {
        if (ts.isIdentifier(decl.name)) {
          const line = sf.getLineAndCharacterOfPosition(decl.name.getStart()).line + 1;
          exports.push({ name: decl.name.text, isDefault: !!isDefault, type: "variable", line });
        }
      }
    } else if (ts.isExportAssignment(node)) {
      const line = sf.getLineAndCharacterOfPosition(node.getStart()).line + 1;
      exports.push({ name: "default", isDefault: true, type: "default", line });
    } else if (ts.isExportDeclaration(node)) {
      if (node.exportClause && ts.isNamedExports(node.exportClause)) {
        for (const elem of node.exportClause.elements) {
          const line = sf.getLineAndCharacterOfPosition(elem.name.getStart()).line + 1;
          exports.push({ name: elem.name.text, isDefault: false, type: "named_export", line });
        }
      }
    }

    // Collect identifier usages
    if (ts.isIdentifier(node)) {
      const parent = node.parent;
      let isImportName = false;
      if (
        (ts.isImportSpecifier(parent) && parent.name === node) ||
        (ts.isImportClause(parent) && parent.name === node) ||
        (ts.isNamespaceImport(parent) && parent.name === node)
      ) {
        isImportName = true;
      }
      if (!isImportName) {
        identifiersUsed.add(node.text);
      }
    }

    ts.forEachChild(node, visit);
  }

  visit(sf);

  fileMap.set(relPath, {
    filePath,
    relPath,
    content,
    imports,
    exports,
    identifiersUsed,
  });
}

// -------------------------------------------------------------
// 1. Unreferenced Files
// -------------------------------------------------------------
const nextConventions = [
  "page.jsx", "page.tsx", "page.js",
  "layout.jsx", "layout.tsx", "layout.js",
  "route.js", "route.ts",
  "not-found.jsx", "not-found.tsx",
  "loading.jsx", "error.jsx"
];

const unreferencedFiles = [];
const uncertainFiles = [];

for (const [relPath, data] of fileMap.entries()) {
  const baseName = path.basename(relPath);
  const nameWithoutExt = baseName.replace(/\.[^.]+$/, "");

  if (nextConventions.includes(baseName)) continue;

  let isReferenced = false;
  for (const [otherPath, otherData] of fileMap.entries()) {
    if (otherPath === relPath) continue;
    if (
      otherData.content.includes(nameWithoutExt) ||
      otherData.content.includes(relPath.replace(/\.[^.]+$/, ""))
    ) {
      isReferenced = true;
      break;
    }
  }

  if (!isReferenced) {
    // Dynamic or Category Mapping check
    if (
      relPath.includes("components/document/nda") ||
      relPath.includes("components/document/partner") ||
      relPath.includes("components/document/distributor") ||
      relPath.includes("components/document/quotation") ||
      relPath.includes("lib/db/adapters") ||
      relPath.includes("lib/data/")
    ) {
      uncertainFiles.push({
        path: relPath,
        reason: "ไม่มีการ static import โดยตรง แต่อาจเป็น Legacy Template Page หรือ Adapter/Data Profile ที่เคยผูกกับระบบเดิม"
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
// 2. Unused Exports
// -------------------------------------------------------------
const unusedExports = [];
const uncertainExports = [];
const nextRouteMethods = new Set(["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]);

for (const [relPath, data] of fileMap.entries()) {
  const baseName = path.basename(relPath);

  for (const exp of data.exports) {
    if (baseName.startsWith("route.") && nextRouteMethods.has(exp.name)) continue;
    if ((baseName.startsWith("page.") || baseName.startsWith("layout.") || baseName.startsWith("not-found.")) && exp.isDefault) continue;

    const expName = exp.name;
    if (expName === "default") {
      let isDefaultImported = false;
      const nameWithoutExt = baseName.replace(/\.[^.]+$/, "");
      for (const [otherPath, otherData] of fileMap.entries()) {
        if (otherPath === relPath) continue;
        if (
          otherData.imports.some((imp) => imp.isDefault) &&
          (otherData.content.includes(nameWithoutExt) || otherData.content.includes(relPath.replace(/\.[^.]+$/, "")))
        ) {
          isDefaultImported = true;
          break;
        }
      }
      if (!isDefaultImported && !unreferencedFiles.some(f => f.path === relPath)) {
        unusedExports.push({
          path: relPath,
          line: exp.line,
          name: "default export",
          reason: `Component/Module มีการ export default แต่ไม่พบว่าไฟล์อื่นทำการ import default เข้าไปใช้`
        });
      }
      continue;
    }

    let usedInOtherFile = false;
    for (const [otherPath, otherData] of fileMap.entries()) {
      if (otherPath === relPath) continue;
      if (otherData.imports.some((imp) => imp.name === expName)) {
        usedInOtherFile = true;
        break;
      }
      if (otherData.identifiersUsed.has(expName) && otherData.content.includes(expName)) {
        usedInOtherFile = true;
        break;
      }
    }

    if (!usedInOtherFile) {
      if (relPath.startsWith("lib/fonts/") || relPath.startsWith("lib/export/") || relPath.startsWith("lib/db/")) {
        uncertainExports.push({
          path: relPath,
          line: exp.line,
          name: expName,
          reason: `ฟังก์ชัน Utility/API Interface ในไลบรารีส่วนกลาง ที่อาจเตรียมไว้สำหรับ external caller หรือ public utility`
        });
      } else {
        unusedExports.push({
          path: relPath,
          line: exp.line,
          name: expName,
          reason: `Export '${expName}' แต่ไม่มีไฟล์อื่นในโปรเจค import หรือเรียกใช้งาน`
        });
      }
    }
  }
}

// -------------------------------------------------------------
// 3. Unused Imports (In-File)
// -------------------------------------------------------------
const unusedImports = [];

for (const [relPath, data] of fileMap.entries()) {
  for (const imp of data.imports) {
    const name = imp.name;
    // Special case: React in JSX (React 17+ doesn't require React in scope)
    // If name is 'React' and 'React.' is never used, it is an unused import
    if (!data.identifiersUsed.has(name)) {
      unusedImports.push({
        path: relPath,
        line: imp.line,
        name: name,
        from: imp.moduleSpecifier,
        reason: `Import '${name}' จาก '${imp.moduleSpecifier}' แต่ไม่เคยถูกเรียกใช้ในไฟล์นี้`
      });
    }
  }
}

// -------------------------------------------------------------
// 4. Unused Variables / State (From ESLint)
// -------------------------------------------------------------
let eslintReport = [];
if (fs.existsSync("eslint_report.json")) {
  eslintReport = JSON.parse(fs.readFileSync("eslint_report.json", "utf-8"));
}

const unusedVariables = [];
for (const fileReport of eslintReport) {
  const relPath = path.relative(ROOT, fileReport.filePath).replace(/\\/g, "/");
  if (!APP_DIRS.some((d) => relPath.startsWith(d + "/"))) continue;

  const content = fs.readFileSync(fileReport.filePath, "utf-8");
  const lines = content.split("\n");

  for (const msg of fileReport.messages) {
    if (msg.ruleId === "@typescript-eslint/no-unused-vars" || msg.ruleId === "no-unused-vars") {
      const lineNum = msg.line;
      const lineText = (lines[lineNum - 1] || "").trim();
      const match = msg.message.match(/'([^']+)'/);
      const varName = match ? match[1] : "unknown";

      const isImportLine = lineText.startsWith("import ") || lineText.includes(" from ") || lineText.startsWith("} from");
      if (!isImportLine) {
        unusedVariables.push({
          path: relPath,
          line: lineNum,
          name: varName,
          codeSnippet: lineText,
          reason: `ประกาศตัวแปร/state '${varName}' (${msg.message}) แต่ไม่เคยถูกนำไปใช้งาน`
        });
      }
    }
  }
}

// -------------------------------------------------------------
// 5. Unused Dependencies in package.json
// -------------------------------------------------------------
const pkg = JSON.parse(fs.readFileSync("package.json", "utf-8"));
const deps = Object.keys(pkg.dependencies || {});
const unusedDeps = [];
const uncertainDeps = [];

const frameworkRuntimes = ["next", "react", "react-dom", "react-native-web"];

for (const dep of deps) {
  let isFound = false;
  for (const [relPath, data] of fileMap.entries()) {
    if (
      data.content.includes(`"${dep}"`) ||
      data.content.includes(`'${dep}'`) ||
      data.content.includes(`from "${dep}`) ||
      data.content.includes(`from '${dep}`)
    ) {
      isFound = true;
      break;
    }
  }

  if (!isFound) {
    if (frameworkRuntimes.includes(dep)) {
      uncertainDeps.push({
        name: dep,
        reason: `ไม่พบการ import ตรงในโค้ด แต่เป็น Next.js / React peer runtime core dependency`
      });
    } else {
      unusedDeps.push({
        name: dep,
        reason: `มีระบุใน dependencies ของ package.json แต่ไม่พบการ import หรือ require ใน source code ใดๆ เลย`
      });
    }
  }
}

const finalAudit = {
  unreferencedFiles,
  uncertainFiles,
  unusedExports,
  uncertainExports,
  unusedImports,
  unusedVariables,
  unusedDeps,
  uncertainDeps,
};

fs.writeFileSync("app_audit_result.json", JSON.stringify(finalAudit, null, 2), "utf-8");

console.log("\n=== APPLICATION AUDIT SUMMARY ===");
console.log(`1. Unreferenced Files: ${unreferencedFiles.length} (Uncertain: ${uncertainFiles.length})`);
console.log(`2. Unused Exports: ${unusedExports.length} (Uncertain: ${uncertainExports.length})`);
console.log(`3. Unused Imports: ${unusedImports.length}`);
console.log(`4. Unused Variables/State: ${unusedVariables.length}`);
console.log(`5. Unused Dependencies: ${unusedDeps.length} (Uncertain: ${uncertainDeps.length})`);
