import {
  templateBlocksRepo,
  documentsRepo,
  fieldProfilesRepo,
  quotationsRepo,
} from '../lib/db/repositories/index.js';
import { SYSTEM_DEFAULT_TEMPLATES } from '../lib/templates/catalog.js';

async function verifyContractsMigration() {
  console.log('=== VERIFY CONTRACTS TO DATABASE BLOCKS MIGRATION ===\n');

  // 1. Verify Catalog Templates & Blocks
  console.log('1. Checking SYSTEM_DEFAULT_TEMPLATES:');
  const contractTemplateIds = ['tmpl-nda-standard', 'tmpl-partner-standard', 'tmpl-distributor-standard'];
  for (const tid of contractTemplateIds) {
    const tmpl = SYSTEM_DEFAULT_TEMPLATES.find(t => t.id === tid);
    if (!tmpl) throw new Error("Missing template in catalog: " + tid);
    console.log("  ✓ " + tmpl.id + ": " + tmpl.name + " (Blocks count: " + tmpl.blocks.length + ", PageCount: " + tmpl.pageCount + ")");
    
    // Check preamble and section block presence
    const hasPreamble = tmpl.blocks.some(b => b.type === 'contract_preamble');
    const hasSection = tmpl.blocks.some(b => b.type === 'contract_section');
    const hasSignatures = tmpl.blocks.some(b => b.type === 'signatures');
    if (!hasPreamble || !hasSection || !hasSignatures) {
      throw new Error("Template " + tid + " is missing required block types!");
    }
  }

  // 2. Verify Database Normalized Blocks in db.json
  console.log('\n2. Checking Database Normalized Blocks (templateBlocksRepo):');
  const allBlocks = await templateBlocksRepo.getAll();
  console.log("  ✓ Total templateBlocks in DB: " + allBlocks.length);
  
  for (const tid of contractTemplateIds) {
    const dbBlocks = await templateBlocksRepo.getByTemplateId(tid);
    console.log("  ✓ DB blocks for " + tid + ": " + dbBlocks.length);
    if (dbBlocks.length === 0) {
      throw new Error("No blocks found in DB for " + tid);
    }
  }

  console.log('\n✅ ALL CONTRACT BLOCKS VERIFICATION TESTS PASSED SUCCESSFULLY!');
}

verifyContractsMigration().catch(err => {
  console.error('\n❌ VERIFICATION FAILED:', err);
  process.exit(1);
});
