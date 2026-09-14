import fs from "node:fs/promises";
import path from "node:path";

const dbPath = path.join(process.cwd(), "data", "db.json");
const originalDb = await fs.readFile(dbPath, "utf8");

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

try {
  const {
    jsonCustomTemplatesRepo,
    jsonDocumentsRepo,
    jsonCustomTokensRepo,
    jsonTemplateVersionsRepo,
  } = await import("../lib/db/adapters/json/index.js");

  const initial = JSON.parse(originalDb);
  const initialTemplates = initial.customTemplates || [];
  const initialTokens = initial.customTokens || [];
  const initialDocuments = initial.documents || [];

  assert((initial.templateVersions || []).length > 0, "templateVersions collection is empty");
  assert(initialDocuments.every((doc) => doc.templateVersionId), "Existing document is missing templateVersionId");
  assert(initialTokens.every((token) => token.dataType && token.scope), "Existing token is missing P2 fields");

  const template = await jsonCustomTemplatesRepo.create({
    name: "P2 Automated Test Template",
    categoryId: "forms",
    blocks: [{ id: "test-block", type: "text_block", settings: { content: "v1" } }],
    pages: [],
  });
  const firstVersions = await jsonTemplateVersionsRepo.getByTemplateId(template.id);
  assert(firstVersions.length === 1 && template.currentVersionId === firstVersions[0].id, "Template initial version was not created");

  await jsonCustomTemplatesRepo.update(template.id, {
    blocks: [{ id: "test-block", type: "text_block", settings: { content: "draft" } }],
    publishSnapshot: false,
  });
  const draftVersions = await jsonTemplateVersionsRepo.getByTemplateId(template.id);
  assert(draftVersions.length === 1, "Draft update unexpectedly created a version");

  await jsonCustomTemplatesRepo.update(template.id, {
    blocks: [{ id: "test-block", type: "text_block", settings: { content: "v2" } }],
    publishSnapshot: true,
  });
  const publishedVersions = await jsonTemplateVersionsRepo.getByTemplateId(template.id);
  const latestTemplate = await jsonCustomTemplatesRepo.getById(template.id);
  assert(publishedVersions.length === 2, "Publish did not create a new version");
  assert(latestTemplate.currentVersionId === publishedVersions[0].id, "Template currentVersionId is not latest");

  const document = await jsonDocumentsRepo.create({
    name: "P2 Automated Test Document",
    templateId: template.id,
    values: {},
  });
  assert(document.templateVersionId === latestTemplate.currentVersionId, "Document did not lock to current template version");

  const token = await jsonCustomTokensRepo.create({
    key: `p2_test_${Date.now()}`,
    label: "P2 Test Currency",
    scope: "template",
    templateId: template.id,
    dataType: "currency",
  });
  assert(token.scope === "template" && token.templateId === template.id && token.dataType === "currency", "Custom token P2 fields were not persisted");

  console.log(JSON.stringify({
    passed: true,
    initialTemplates: initialTemplates.length,
    initialTokens: initialTokens.length,
    initialDocuments: initialDocuments.length,
    publishedVersions: publishedVersions.length,
    lockedVersionId: document.templateVersionId,
    tokenDataType: token.dataType,
  }, null, 2));
} finally {
  await fs.writeFile(dbPath, originalDb, "utf8");
}
