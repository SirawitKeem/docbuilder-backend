import {
  fieldProfilesRepo,
  documentsRepo,
  quotationsRepo,
  counterpartiesRepo,
  documentFieldValuesRepo,
  documentTablesRepo,
} from '../lib/db/repositories/index.js';

async function runTests() {
  console.log('🧪 Starting Dual-Write Sync Verification Tests...\n');

  // --- Test 1: Profile Dual-Write ---
  console.log('Test 1: Creating a new field profile...');
  const testProfile = await fieldProfilesRepo.create({
    name: 'บจก. เทสท์ คลาวด์ ซิสเต็มส์',
    values: {
      counterparty_name: 'บจก. เทสท์ คลาวด์ ซิสเต็มส์',
      tax_id: '0105599887766',
      address: '123 อาคารไอทีทาวเวอร์ ถ.แจ้งวัฒนะ กทม. 10210',
      counterparty_signatory_name: 'นายทดสอบ ระบบดี',
      counterparty_signatory_position: 'กรรมการผู้มีอำนาจ',
      phone: '02-999-8888',
      email: 'test@cloudsystems.co.th',
    },
    profileType: 'client',
  });
  console.log(`✓ Profile created: ID = ${testProfile.id}`);

  const counterparties = await counterpartiesRepo.getAll();
  const matchedCp = counterparties.find((c) => c.id === testProfile.id);
  if (!matchedCp) throw new Error('❌ counterparties record was NOT created!');
  if (matchedCp.companyNameTh !== 'บจก. เทสท์ คลาวด์ ซิสเต็มส์') {
    throw new Error(`❌ companyNameTh mismatch: got ${matchedCp.companyNameTh}`);
  }
  if (matchedCp.registrationNumber !== '0105599887766') {
    throw new Error(`❌ registrationNumber mismatch: got ${matchedCp.registrationNumber}`);
  }
  console.log('✓ Counterparty record verified in normalized table!');

  // --- Test 2: Profile Update Dual-Write ---
  console.log('\nTest 2: Updating field profile...');
  await fieldProfilesRepo.update(testProfile.id, {
    name: 'บจก. เทสท์ คลาวด์ ซิสเต็มส์ (สาขา 1)',
    values: {
      counterparty_name: 'บจก. เทสท์ คลาวด์ ซิสเต็มส์ (สาขา 1)',
      branch: 'สาขา 1',
      tax_id: '0105599887766',
      address: '456 ถ.สุขุมวิท กทม.',
      counterparty_signatory_name: 'นายทดสอบ ระบบดี',
      counterparty_signatory_position: 'กรรมการผู้จัดการ',
    },
  });
  const updatedCps = await counterpartiesRepo.getAll();
  const updatedCp = updatedCps.find((c) => c.id === testProfile.id);
  if (updatedCp.companyNameTh !== 'บจก. เทสท์ คลาวด์ ซิสเต็มส์ (สาขา 1)') {
    throw new Error(`❌ Updated companyNameTh mismatch: got ${updatedCp.companyNameTh}`);
  }
  if (updatedCp.branch !== 'สาขา 1') {
    throw new Error(`❌ Updated branch mismatch: got ${updatedCp.branch}`);
  }
  console.log('✓ Profile update successfully synced to counterparties!');

  // --- Test 3: Document Dual-Write (Field Values) ---
  console.log('\nTest 3: Creating document with dynamic fields...');
  const testDocId = `test-doc-${Date.now()}`;
  const testDoc = await documentsRepo.create({
    id: testDocId,
    name: 'สัญญาคู่ค้าทดสอบ Dual-Write',
    templateId: 'partner',
    values: {
      company_name: 'บริษัท เครสท์ เซนโด จำกัด',
      customer_name: 'นายทดสอบ ระบบดี',
      customer_company: 'บจก. เทสท์ คลาวด์ ซิสเต็มส์',
      contract_date: '2026-09-11',
      commission_rate: 15,
      is_active: true,
    },
  });
  console.log(`✓ Document created: ID = ${testDoc.id}`);

  const fvs = await documentFieldValuesRepo.getByDocumentId(testDocId);
  if (fvs.length === 0) throw new Error('❌ documentFieldValues records NOT created!');
  console.log(`✓ Created ${fvs.length} normalized field value rows in documentFieldValues!`);

  const commissionFv = fvs.find((f) => f.fieldKey === 'commission_rate');
  if (!commissionFv || commissionFv.numberValue !== 15) {
    throw new Error(`❌ commission_rate numberValue mismatch: ${JSON.stringify(commissionFv)}`);
  }
  const dateFv = fvs.find((f) => f.fieldKey === 'contract_date');
  if (!dateFv || dateFv.dateValue !== '2026-09-11') {
    throw new Error(`❌ contract_date dateValue mismatch: ${JSON.stringify(dateFv)}`);
  }
  console.log('✓ Typed columns (number, date) correctly handled in EAV model!');

  // --- Test 4: Quotation Dual-Write (Tables & Rows) ---
  console.log('\nTest 4: Creating quotation with table line items...');
  const testQtId = `test-qt-${Date.now()}`;
  const testQt = await quotationsRepo.create({
    id: testQtId,
    name: 'ใบเสนอราคาบริการ Cloud & AI 2026',
    quotationNo: 'CZ26099999',
    subtotal: 100000,
    discount: 5000,
    vatRate: 7,
    vatAmount: 6650,
    grandTotal: 101650,
    lineItems: [
      { desc: 'Cloud Server Enterprise Tier', qty: 2, price: 25000, total: 50000 },
      { desc: 'AI DocBuilder Enterprise License', qty: 1, price: 50000, total: 50000 },
    ],
  });
  console.log(`✓ Quotation created: ID = ${testQt.id}`);

  const tables = await documentTablesRepo.getByDocumentId(testQtId);
  if (tables.length === 0) throw new Error('❌ documentTables record NOT created!');
  const qtTable = tables[0];
  if (Number(qtTable.grandTotal) !== 101650) {
    throw new Error(`❌ grandTotal mismatch: ${qtTable.grandTotal}`);
  }
  if (qtTable.rows.length !== 2) {
    throw new Error(`❌ Expected 2 rows in documentTableRows, got ${qtTable.rows.length}`);
  }
  if (qtTable.rows[0].itemDescription !== 'Cloud Server Enterprise Tier') {
    throw new Error(`❌ First row itemDescription mismatch: ${qtTable.rows[0].itemDescription}`);
  }
  console.log(`✓ Table and ${qtTable.rows.length} rows successfully synced to documentTables & documentTableRows!`);

  // --- Test 5: Cascade Deletion ---
  console.log('\nTest 5: Testing Cascade Delete for cleanup...');
  await documentsRepo.delete(testDocId);
  const remainingDocFvs = await documentFieldValuesRepo.getByDocumentId(testDocId);
  if (remainingDocFvs.length !== 0) {
    throw new Error(`❌ Cascade delete failed: ${remainingDocFvs.length} field values remaining!`);
  }
  console.log('✓ Document field values cascade deleted successfully!');

  await quotationsRepo.delete(testQtId);
  const remainingQtTables = await documentTablesRepo.getByDocumentId(testQtId);
  if (remainingQtTables.length !== 0) {
    throw new Error('❌ Cascade delete failed: quotation table remaining!');
  }
  console.log('✓ Quotation table and table rows cascade deleted successfully!');

  await fieldProfilesRepo.remove(testProfile.id);
  const postRemoveCps = await counterpartiesRepo.getAll();
  if (postRemoveCps.some((c) => c.id === testProfile.id)) {
    throw new Error('❌ Profile removal did not clean up counterparties table!');
  }
  console.log('✓ Counterparty record cleaned up successfully!');

  console.log('\n🎉 ALL 5 DUAL-WRITE SYNC TESTS PASSED 100%!');
}

runTests().catch((err) => {
  console.error('\n❌ Test failed with error:', err);
  process.exit(1);
});
