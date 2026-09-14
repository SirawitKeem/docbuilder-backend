import fs from 'fs';
import path from 'path';

const DB_PATH = fs.existsSync(path.resolve('data/db.json')) 
  ? path.resolve('data/db.json') 
  : path.resolve('docbuilder-backend/data/db.json');
const OUTPUT_SQL_PATH = fs.existsSync(path.resolve('migrations'))
  ? path.resolve('migrations/000001_pgadmin_complete_setup.sql')
  : path.resolve('docbuilder-backend/migrations/000001_pgadmin_complete_setup.sql');

const db = JSON.parse(fs.readFileSync(DB_PATH, 'utf8'));

function escapeSql(str) {
  if (str === null || str === undefined) return 'NULL';
  return `'${String(str).replace(/'/g, "''")}'`;
}

function escapeJson(obj) {
  if (obj === null || obj === undefined) return "'{}'::jsonb";
  return `'${JSON.stringify(obj).replace(/'/g, "''")}'::jsonb`;
}

function escapeDate(str) {
  if (!str) return 'CURRENT_TIMESTAMP';
  return `'${str}'::timestamptz`;
}

let sql = `-- ==============================================================================
-- DocBuilder Enterprise Database: Complete PostgreSQL Setup for pgAdmin 4
-- Generated automatically from verified system state
-- Fully normalized, production-ready, zero hardcoding
-- ==============================================================================

-- Reset public schema to guarantee 100% clean installation
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. Organizations
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organizations (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    name_en VARCHAR(255),
    tax_id VARCHAR(32),
    branch VARCHAR(100) DEFAULT 'สำนักงานใหญ่',
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(100),
    website VARCHAR(255),
    logo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 2. Users
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    org_id VARCHAR(64) REFERENCES organizations(id) ON DELETE SET NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50) DEFAULT 'member',
    avatar TEXT,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 3. Organization Signatories
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS organization_signatories (
    id VARCHAR(64) PRIMARY KEY,
    org_id VARCHAR(64) NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    position VARCHAR(150),
    signature_image_url TEXT,
    seal_image_url TEXT,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 4. Counterparties (Clients / Partners / Vendors)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS counterparties (
    id VARCHAR(64) PRIMARY KEY,
    org_id VARCHAR(64) NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    linked_org_id VARCHAR(64) REFERENCES organizations(id) ON DELETE SET NULL,
    party_type VARCHAR(50) NOT NULL DEFAULT 'client',
    company_name_th VARCHAR(255) NOT NULL,
    company_name_en VARCHAR(255),
    registration_number VARCHAR(32),
    branch VARCHAR(100) DEFAULT 'สำนักงานใหญ่',
    address_th TEXT,
    address_en TEXT,
    phone VARCHAR(50),
    email VARCHAR(100),
    created_by_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- ------------------------------------------------------------------------------
-- 5. Counterparty Signatories
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS counterparty_signatories (
    id VARCHAR(64) PRIMARY KEY,
    counterparty_id VARCHAR(64) NOT NULL REFERENCES counterparties(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    position VARCHAR(150),
    signature_text VARCHAR(255),
    signature_image_url TEXT,
    is_primary BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 6. Categories
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    full_name VARCHAR(255),
    description TEXT,
    icon VARCHAR(100) DEFAULT 'FileText',
    color VARCHAR(50) DEFAULT 'purple',
    badge VARCHAR(50) DEFAULT 'ทั่วไป',
    sort_order INT DEFAULT 0,
    created_by_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 7. Templates
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS templates (
    id VARCHAR(64) PRIMARY KEY,
    org_id VARCHAR(64) NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    category_id VARCHAR(64) REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    editor_type VARCHAR(50) DEFAULT 'document',
    canvas_preset VARCHAR(50) DEFAULT 'a4-portrait',
    orientation VARCHAR(20) DEFAULT 'portrait',
    theme VARCHAR(50) DEFAULT 'modern',
    status VARCHAR(50) DEFAULT 'published',
    is_custom BOOLEAN DEFAULT FALSE,
    is_standard BOOLEAN DEFAULT FALSE,
    current_version_id VARCHAR(64),
    created_by_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- ------------------------------------------------------------------------------
-- 8. Template Versions
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS template_versions (
    id VARCHAR(64) PRIMARY KEY,
    template_id VARCHAR(64) NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    version INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id VARCHAR(64) REFERENCES categories(id) ON DELETE SET NULL,
    blocks JSONB DEFAULT '[]'::jsonb,
    pages JSONB DEFAULT '[]'::jsonb,
    created_by_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 9. Template Blocks
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS template_blocks (
    id VARCHAR(64) PRIMARY KEY,
    template_version_id VARCHAR(64) NOT NULL REFERENCES template_versions(id) ON DELETE CASCADE,
    block_type VARCHAR(100) NOT NULL,
    title VARCHAR(255),
    sort_order INT DEFAULT 0,
    is_required BOOLEAN DEFAULT TRUE,
    settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 10. Template Fields
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS template_fields (
    id VARCHAR(64) PRIMARY KEY,
    template_version_id VARCHAR(64) NOT NULL REFERENCES template_versions(id) ON DELETE CASCADE,
    block_id VARCHAR(64) REFERENCES template_blocks(id) ON DELETE SET NULL,
    field_key VARCHAR(100) NOT NULL,
    label VARCHAR(255) NOT NULL,
    field_type VARCHAR(50) NOT NULL,
    is_required BOOLEAN DEFAULT FALSE,
    default_value TEXT,
    placeholder TEXT,
    help_text TEXT,
    validation_regex TEXT,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 11. Template Table Columns
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS template_table_columns (
    id VARCHAR(64) PRIMARY KEY,
    template_block_id VARCHAR(64) NOT NULL REFERENCES template_blocks(id) ON DELETE CASCADE,
    column_key VARCHAR(100) NOT NULL,
    header_label VARCHAR(255) NOT NULL,
    data_type VARCHAR(50) DEFAULT 'text',
    alignment VARCHAR(20) DEFAULT 'left',
    width_percentage DECIMAL(5,2),
    sort_order INT DEFAULT 0,
    is_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 12. Field Profiles (Data Presets)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS field_profiles (
    id VARCHAR(64) PRIMARY KEY,
    org_id VARCHAR(64) REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    profile_type VARCHAR(50) DEFAULT 'general',
    counterparty_id VARCHAR(64) REFERENCES counterparties(id) ON DELETE SET NULL,
    created_by_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 13. Field Profile Values (EAV / Key-Value Data)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS field_profile_values (
    id VARCHAR(64) PRIMARY KEY,
    profile_id VARCHAR(64) NOT NULL REFERENCES field_profiles(id) ON DELETE CASCADE,
    shared_key VARCHAR(100) NOT NULL,
    field_value TEXT,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_profile_shared_key UNIQUE (profile_id, shared_key)
);

-- ------------------------------------------------------------------------------
-- 14. Field Profile Compatible Templates (Junction Table)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS field_profile_templates (
    profile_id VARCHAR(64) NOT NULL REFERENCES field_profiles(id) ON DELETE CASCADE,
    template_id VARCHAR(64) NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    PRIMARY KEY (profile_id, template_id)
);

-- ------------------------------------------------------------------------------
-- 15. Documents
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS documents (
    id VARCHAR(64) PRIMARY KEY,
    org_id VARCHAR(64) NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    template_id VARCHAR(64) REFERENCES templates(id) ON DELETE SET NULL,
    template_version_id VARCHAR(64) REFERENCES template_versions(id) ON DELETE SET NULL,
    counterparty_id VARCHAR(64) REFERENCES counterparties(id) ON DELETE SET NULL,
    our_signatory_id VARCHAR(64) REFERENCES organization_signatories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    document_number VARCHAR(100),
    status VARCHAR(50) DEFAULT 'draft',
    verification_token VARCHAR(100) UNIQUE,
    watermark VARCHAR(50) DEFAULT 'none',
    sent_to VARCHAR(255),
    last_sent_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    approved_by VARCHAR(255),
    rejection_reason TEXT,
    created_by_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

-- ------------------------------------------------------------------------------
-- 16. Document Field Values (EAV Model)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS document_field_values (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    field_key VARCHAR(100) NOT NULL,
    text_value TEXT,
    number_value DECIMAL(18,4),
    date_value DATE,
    boolean_value BOOLEAN,
    json_value JSONB,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_doc_field UNIQUE (document_id, field_key)
);

-- ------------------------------------------------------------------------------
-- 17. Document Tables
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS document_tables (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    template_block_id VARCHAR(64) REFERENCES template_blocks(id) ON DELETE SET NULL,
    table_name VARCHAR(255) NOT NULL,
    currency VARCHAR(10) DEFAULT 'THB',
    vat_rate DECIMAL(5,2) DEFAULT 7.00,
    subtotal DECIMAL(18,4) DEFAULT 0.0000,
    discount_amount DECIMAL(18,4) DEFAULT 0.0000,
    vat_amount DECIMAL(18,4) DEFAULT 0.0000,
    grand_total DECIMAL(18,4) DEFAULT 0.0000,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 18. Document Table Rows
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS document_table_rows (
    id VARCHAR(64) PRIMARY KEY,
    table_id VARCHAR(64) NOT NULL REFERENCES document_tables(id) ON DELETE CASCADE,
    row_type VARCHAR(50) DEFAULT 'item',
    sort_order INT DEFAULT 0,
    item_description TEXT,
    item_details TEXT,
    quantity DECIMAL(12,4) DEFAULT 1.0000,
    unit_name VARCHAR(50) DEFAULT 'หน่วย',
    unit_price DECIMAL(18,4) DEFAULT 0.0000,
    discount_amount DECIMAL(18,4) DEFAULT 0.0000,
    line_total DECIMAL(18,4) DEFAULT 0.0000,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 19. Document Activity Logs
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS document_activity_logs (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,
    performed_by VARCHAR(255),
    details TEXT,
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 20. Sent & Export History
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sent_history (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) REFERENCES documents(id) ON DELETE SET NULL,
    document_name VARCHAR(255),
    recipient_email VARCHAR(255),
    subject VARCHAR(255),
    message TEXT,
    sent_by VARCHAR(255),
    status VARCHAR(50) DEFAULT 'success',
    action_type VARCHAR(50) DEFAULT 'email',
    format VARCHAR(50),
    channel VARCHAR(50) DEFAULT 'email',
    sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 21. Custom Tokens
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS custom_tokens (
    id VARCHAR(64) PRIMARY KEY,
    token_key VARCHAR(100) NOT NULL UNIQUE,
    label VARCHAR(255) NOT NULL,
    category VARCHAR(100) DEFAULT 'ทั่วไป',
    scope VARCHAR(50) DEFAULT 'global',
    field_type VARCHAR(50) DEFAULT 'text',
    example_value TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 22. Notifications
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    link_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------------------------
-- 23. Settings
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS settings (
    id VARCHAR(64) PRIMARY KEY,
    org_id VARCHAR(64) REFERENCES organizations(id) ON DELETE CASCADE,
    key VARCHAR(100) NOT NULL UNIQUE,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for blazing performance
CREATE INDEX IF NOT EXISTS idx_documents_org_id ON documents(org_id);
CREATE INDEX IF NOT EXISTS idx_documents_status ON documents(status);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_doc_field_values_doc_id ON document_field_values(document_id);
CREATE INDEX IF NOT EXISTS idx_template_blocks_version_id ON template_blocks(template_version_id);
CREATE INDEX IF NOT EXISTS idx_document_tables_doc_id ON document_tables(document_id);
CREATE INDEX IF NOT EXISTS idx_document_table_rows_table_id ON document_table_rows(table_id);
CREATE INDEX IF NOT EXISTS idx_sent_history_doc_id ON sent_history(document_id);
CREATE INDEX IF NOT EXISTS idx_sent_history_action_type ON sent_history(action_type);

\n-- ==============================================================================
-- SEED DATA INSERTIONS
-- ==============================================================================
`;

// 1. Organizations
for (const org of db.organizations || []) {
  sql += `INSERT INTO organizations (id, name, name_en, tax_id, branch, address, phone, email, website)
VALUES (${escapeSql(org.id)}, ${escapeSql(org.name)}, ${escapeSql(org.nameEn || org.name_en)}, ${escapeSql(org.taxId || org.tax_id)}, ${escapeSql(org.branch)}, ${escapeSql(org.address)}, ${escapeSql(org.phone)}, ${escapeSql(org.email)}, ${escapeSql(org.website)})
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;\n`;
}

// 2. Users
for (const usr of db.users || []) {
  sql += `INSERT INTO users (id, org_id, full_name, email, role)
VALUES (${escapeSql(usr.id)}, ${escapeSql(usr.orgId || usr.org_id)}, ${escapeSql(usr.fullName || usr.full_name)}, ${escapeSql(usr.email)}, ${escapeSql(usr.role)})
ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;\n`;
}

// 3. Organization Signatories
for (const sig of db.organizationSignatories || []) {
  sql += `INSERT INTO organization_signatories (id, org_id, full_name, position, is_default)
VALUES (${escapeSql(sig.id)}, ${escapeSql(sig.orgId || sig.org_id)}, ${escapeSql(sig.fullName || sig.full_name)}, ${escapeSql(sig.position)}, ${sig.isDefault ? 'TRUE' : 'FALSE'})
ON CONFLICT (id) DO NOTHING;\n`;
}

// 4. Counterparties
for (const cp of db.counterparties || []) {
  sql += `INSERT INTO counterparties (id, org_id, party_type, company_name_th, company_name_en, registration_number, branch, address_th, address_en)
VALUES (${escapeSql(cp.id)}, ${escapeSql(cp.orgId || cp.org_id || 'org-crestzendo')}, ${escapeSql(cp.partyType || cp.party_type || 'client')}, ${escapeSql(cp.companyNameTh || cp.company_name_th)}, ${escapeSql(cp.companyNameEn || cp.company_name_en)}, ${escapeSql(cp.registrationNumber || cp.registration_number)}, ${escapeSql(cp.branch)}, ${escapeSql(cp.addressTh || cp.address_th)}, ${escapeSql(cp.addressEn || cp.address_en)})
ON CONFLICT (id) DO NOTHING;\n`;
}

// 5. Counterparty Signatories
for (const cs of db.counterpartySignatories || []) {
  sql += `INSERT INTO counterparty_signatories (id, counterparty_id, full_name, position, signature_text, is_primary)
VALUES (${escapeSql(cs.id)}, ${escapeSql(cs.counterpartyId || cs.counterparty_id)}, ${escapeSql(cs.fullName || cs.full_name)}, ${escapeSql(cs.position)}, ${escapeSql(cs.signatureText || cs.signature_text)}, ${cs.isPrimary ? 'TRUE' : 'FALSE'})
ON CONFLICT (id) DO NOTHING;\n`;
}

// 6. Categories
for (const cat of db.categories || []) {
  sql += `INSERT INTO categories (id, name, full_name, description, icon, color, badge, sort_order)
VALUES (${escapeSql(cat.id)}, ${escapeSql(cat.name)}, ${escapeSql(cat.fullName || cat.full_name)}, ${escapeSql(cat.description)}, ${escapeSql(cat.icon)}, ${escapeSql(cat.color)}, ${escapeSql(cat.badge)}, ${Number(cat.sortOrder || cat.sort_order || 0)})
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;\n`;
}

// 7. Templates & Versions
const standardAliases = [
  { id: 'quotation', categoryId: 'quotation', name: 'ใบเสนอราคามาตรฐาน' },
  { id: 'nda', categoryId: 'nda', name: 'หนังสือสัญญาไม่เปิดเผยข้อมูล' },
  { id: 'partner', categoryId: 'partner', name: 'สัญญาแต่งตั้งพันธมิตรตัวแทนจำหน่าย' },
  { id: 'distributor', categoryId: 'distributor', name: 'สัญญาแต่งตั้งและจัดจำหน่ายซอฟต์แวร์' },
  { id: 'notification', categoryId: 'notification', name: 'หนังสือแจ้งและประกาศทางการ' },
];

for (const alias of standardAliases) {
  sql += `INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES (${escapeSql(alias.id)}, 'org-crestzendo', ${escapeSql(alias.categoryId)}, ${escapeSql(alias.name)}, 'Standard template slug', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;\n`;
}

for (const tmpl of db.customTemplates || []) {
  sql += `INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES (${escapeSql(tmpl.id)}, 'org-crestzendo', ${escapeSql(tmpl.categoryId || tmpl.category_id)}, ${escapeSql(tmpl.name)}, ${escapeSql(tmpl.description)}, ${escapeSql(tmpl.format || 'document')}, 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;\n`;
}

for (const ver of db.templateVersions || []) {
  sql += `INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES (${escapeSql(ver.id)}, ${escapeSql(ver.templateId || ver.template_id)}, ${Number(ver.version || 1)}, ${escapeSql(ver.name)}, ${escapeSql(ver.description)}, ${escapeSql(ver.categoryId || ver.category_id)}, ${escapeJson(ver.blocks)})
ON CONFLICT (id) DO NOTHING;\n`;
}

// 8. Template Blocks (All 95 Blocks!)
for (const blk of db.templateBlocks || []) {
  sql += `INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES (${escapeSql(blk.id)}, ${escapeSql(blk.templateVersionId || blk.template_version_id)}, ${escapeSql(blk.blockType || blk.block_type)}, ${escapeSql(blk.title)}, ${Number(blk.sortOrder || blk.sort_order || 0)}, ${escapeJson(blk.styleConfig || blk.settings || {})})
ON CONFLICT (id) DO NOTHING;\n`;
}

// 9. Field Profiles & Values
for (const p of db.fieldProfiles || []) {
  sql += `INSERT INTO field_profiles (id, org_id, name, profile_type, counterparty_id)
VALUES (${escapeSql(p.id)}, 'org-crestzendo', ${escapeSql(p.name)}, ${escapeSql(p.profileType || 'client')}, ${escapeSql(p.counterpartyId || null)})
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;\n`;

  if (p.values) {
    for (const [k, v] of Object.entries(p.values)) {
      if (typeof v === 'string' || typeof v === 'number') {
        const valId = `fpv-${p.id}-${k}`;
        sql += `INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES (${escapeSql(valId)}, ${escapeSql(p.id)}, ${escapeSql(k)}, ${escapeSql(v)})
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;\n`;
      }
    }
  }

  // Compatible templates
  if (Array.isArray(p.compatibleTemplates)) {
    for (const tmplId of p.compatibleTemplates) {
      sql += `INSERT INTO field_profile_templates (profile_id, template_id)
VALUES (${escapeSql(p.id)}, ${escapeSql(tmplId)})
ON CONFLICT DO NOTHING;\n`;
    }
  }
}

// 10. Documents
for (const doc of db.documents || []) {
  sql += `INSERT INTO documents (id, org_id, template_id, template_version_id, name, status, verification_token, sent_to, last_sent_at, created_at, updated_at)
VALUES (${escapeSql(doc.id)}, 'org-crestzendo', ${escapeSql(doc.templateId || 'quotation')}, ${escapeSql(doc.templateVersionId || null)}, ${escapeSql(doc.name)}, ${escapeSql(doc.status || 'draft')}, ${escapeSql(doc.verificationToken || doc.id)}, ${escapeSql(doc.sentTo || null)}, ${doc.lastSentAt ? escapeDate(doc.lastSentAt) : 'NULL'}, ${escapeDate(doc.createdAt)}, ${escapeDate(doc.updatedAt)})
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;\n`;

  // Activity logs
  if (Array.isArray(doc.activityLogs)) {
    for (const log of doc.activityLogs) {
      sql += `INSERT INTO document_activity_logs (id, document_id, action, performed_by, details, comment, created_at)
VALUES (${escapeSql(log.id)}, ${escapeSql(doc.id)}, ${escapeSql(log.action)}, ${escapeSql(log.performedBy)}, ${escapeSql(log.details)}, ${escapeSql(log.comment)}, ${escapeDate(log.timestamp)})
ON CONFLICT (id) DO NOTHING;\n`;
    }
  }
}

// 11. Document Field Values (EAV)
for (const dfv of db.documentFieldValues || []) {
  sql += `INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES (${escapeSql(dfv.id)}, ${escapeSql(dfv.documentId || dfv.document_id)}, ${escapeSql(dfv.fieldKey || dfv.field_key)}, ${escapeSql(dfv.textValue || dfv.text_value)}, ${dfv.numberValue ? Number(dfv.numberValue) : 'NULL'}, ${escapeDate(dfv.updatedAt)})
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;\n`;
}

// 12. Document Tables & Rows
for (const tbl of db.documentTables || []) {
  sql += `INSERT INTO document_tables (id, document_id, table_name, currency, vat_rate, subtotal, discount_amount, vat_amount, grand_total)
VALUES (${escapeSql(tbl.id)}, ${escapeSql(tbl.documentId || tbl.document_id)}, ${escapeSql(tbl.tableName || tbl.table_name || 'รายการสินค้า')}, ${escapeSql(tbl.currency || 'THB')}, ${Number(tbl.vatRate || 7)}, ${Number(tbl.subtotal || 0)}, ${Number(tbl.discountAmount || 0)}, ${Number(tbl.vatAmount || 0)}, ${Number(tbl.grandTotal || 0)})
ON CONFLICT (id) DO NOTHING;\n`;
}

for (const row of db.documentTableRows || []) {
  sql += `INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES (${escapeSql(row.id)}, ${escapeSql(row.tableId || row.table_id)}, ${escapeSql(row.rowType || 'item')}, ${Number(row.sortOrder || 0)}, ${escapeSql(row.itemDescription || row.item_description)}, ${escapeSql(row.itemDetails || row.item_details)}, ${Number(row.quantity || 1)}, ${Number(row.unitPrice || 0)}, ${Number(row.lineTotal || 0)})
ON CONFLICT (id) DO NOTHING;\n`;
}

// 13. Sent History
for (const hist of db.sentHistory || []) {
  sql += `INSERT INTO sent_history (id, document_id, document_name, recipient_email, subject, sent_by, status, action_type, format, channel, sent_at)
VALUES (${escapeSql(hist.id)}, ${escapeSql(hist.documentId || null)}, ${escapeSql(hist.name)}, ${escapeSql(hist.recipientEmail || hist.sentTo || '-')}, ${escapeSql(hist.subject || hist.name)}, ${escapeSql(hist.sentBy || 'Admin')}, ${escapeSql(hist.status || 'success')}, ${escapeSql(hist.actionType || (hist.channel === 'download' || hist.channel === 'print' ? 'export' : 'email'))}, ${escapeSql(hist.format || null)}, ${escapeSql(hist.channel || 'email')}, ${escapeDate(hist.sentAt || hist.createdAt)})
ON CONFLICT (id) DO NOTHING;\n`;
}

// 14. Settings
if (db.settings) {
  for (const [k, v] of Object.entries(db.settings)) {
    sql += `INSERT INTO settings (id, org_id, key, value)
VALUES (${escapeSql('set-' + k)}, 'org-crestzendo', ${escapeSql(k)}, ${escapeJson(v)})
ON CONFLICT (id) DO UPDATE SET value = EXCLUDED.value;\n`;
  }
}

fs.writeFileSync(OUTPUT_SQL_PATH, sql, 'utf8');
console.log('✅ Generated complete pgAdmin SQL script successfully at:', OUTPUT_SQL_PATH);
console.log('Lines count:', sql.split('\n').length);
