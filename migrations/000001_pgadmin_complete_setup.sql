-- ==============================================================================
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


-- ==============================================================================
-- SEED DATA INSERTIONS
-- ==============================================================================
INSERT INTO organizations (id, name, name_en, tax_id, branch, address, phone, email, website)
VALUES ('org-crestzendo', 'บริษัท เครสท์ เซนโด จำกัด', 'Crest Zendo Co., Ltd.', '0105558073755', 'สำนักงานใหญ่', '8/40 The Connect 37, ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210', '02-123-4567', 'contact@crestzendo.com', 'https://crestzendo.com')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO users (id, org_id, full_name, email, role)
VALUES ('usr-admin', 'org-crestzendo', 'สิรวิทย์ เพชรจำรัส', 'keem@crestzendo.com', 'Owner / Admin')
ON CONFLICT (id) DO UPDATE SET full_name = EXCLUDED.full_name;
INSERT INTO organization_signatories (id, org_id, full_name, position, is_default)
VALUES ('sign-crestzendo-ceo', 'org-crestzendo', 'นายศรายุทธ โกสิยารักษ์', 'กรรมการผู้จัดการ / CEO', TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO counterparties (id, org_id, party_type, company_name_th, company_name_en, registration_number, branch, address_th, address_en)
VALUES ('profile-1787103435257', 'org-crestzendo', 'client', 'บริษัท เน็กซ์เจน เทคโนโลยี แอนด์ ดิจิทัล โซลูชันส์ จำกัด', NULL, '0107544000108', 'สำนักงานใหญ่', '888 อาคารเอ็มไพร์ ทาวเวอร์ ชั้น 21 ถนนสาทรใต้ แขวงยานนาวา เขตสาทร กรุงเทพมหานคร 10120', NULL)
ON CONFLICT (id) DO NOTHING;
INSERT INTO counterparties (id, org_id, party_type, company_name_th, company_name_en, registration_number, branch, address_th, address_en)
VALUES ('profile-1787103657141', 'org-crestzendo', 'client', 'บริษัท เดอะ รีโคฟเวอรี่ แอดไวเซอร์ จำกัด', NULL, NULL, 'สำนักงานใหญ่', '45 ซอย โกสุมรวมใจ 37 แขวงดอนเมือง ดอนเมือง กรุงเทพมหานคร 10210', NULL)
ON CONFLICT (id) DO NOTHING;
INSERT INTO counterparties (id, org_id, party_type, company_name_th, company_name_en, registration_number, branch, address_th, address_en)
VALUES ('profile-1787275130685', 'org-crestzendo', 'customer', 'CS LoxInfo Public Company Limited.', 'CS LoxInfo Public Company Limited.', NULL, 'สำนักงานใหญ่', 'กรุงเทพมหานคร', NULL)
ON CONFLICT (id) DO NOTHING;
INSERT INTO counterparties (id, org_id, party_type, company_name_th, company_name_en, registration_number, branch, address_th, address_en)
VALUES ('profile-1789096120166', 'org-crestzendo', 'client', 'บจก. เทสท์ คลาวด์ ซิสเต็มส์ (สาขา 1)', NULL, '0105599887766', 'สาขา 1', '456 ถ.สุขุมวิท กทม.', NULL)
ON CONFLICT (id) DO NOTHING;
INSERT INTO counterparty_signatories (id, counterparty_id, full_name, position, signature_text, is_primary)
VALUES ('sign-profile-1787103435257', 'profile-1787103435257', 'นายวิทวัส อัครเดชากุล', 'กรรมการผู้มีอำนาจลงนามผูกพันบริษัท', 'นายวิทวัส อัครเดชากุล', TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO counterparty_signatories (id, counterparty_id, full_name, position, signature_text, is_primary)
VALUES ('sign-profile-1787103657141', 'profile-1787103657141', 'นายศรายุทธ โกสิยารักษ์', 'CEO/Founder', 'นายศรายุทธ โกสิยารักษ์', TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO counterparty_signatories (id, counterparty_id, full_name, position, signature_text, is_primary)
VALUES ('sign-profile-1789096120166', 'profile-1789096120166', 'นายทดสอบ ระบบดี', 'กรรมการผู้จัดการ', 'นายทดสอบ ระบบดี', TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO categories (id, name, full_name, description, icon, color, badge, sort_order)
VALUES ('quotation', 'Quotation', 'ใบเสนอราคา', 'ใบเสนอราคาพร้อมรายการสินค้า/บริการ คำนวณภาษี VAT 7% และยอดรวมอัตโนมัติ', 'Receipt', 'purple', 'มาตรฐาน', 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO categories (id, name, full_name, description, icon, color, badge, sort_order)
VALUES ('nda', 'NDA', 'หนังสือสัญญาไม่เปิดเผยข้อมูล', 'Non-Disclosure Agreement สัญญามาตรฐานสำหรับการรักษาความลับทางการค้า', 'FileSignature', 'blue', 'มาตรฐาน', 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO categories (id, name, full_name, description, icon, color, badge, sort_order)
VALUES ('partner', 'Partner Agreement', 'สัญญาแต่งตั้งพันธมิตรตัวแทนจำหน่าย', 'สัญญาแต่งตั้งพันธมิตร พร้อมเงื่อนไข Deal Registration และอัตราแลกเปลี่ยน', 'Handshake', 'emerald', 'มาตรฐาน', 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO categories (id, name, full_name, description, icon, color, badge, sort_order)
VALUES ('distributor', 'Distributor Agreement', 'สัญญาแต่งตั้งและจัดจำหน่ายซอฟต์แวร์', 'สัญญาแต่งตั้งตัวแทนจำหน่ายและจัดจำหน่ายซอฟต์แวร์', 'Building2', 'indigo', 'มาตรฐาน', 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO categories (id, name, full_name, description, icon, color, badge, sort_order)
VALUES ('notification', 'Notification Letter', 'หนังสือแจ้งและประกาศทางการ', 'หนังสือแจ้งการ, จดหมายแจ้งเปลี่ยนแปลงข้อมูลองค์กร และประกาศทางการ', 'Megaphone', 'rose', 'มาตรฐาน', 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO categories (id, name, full_name, description, icon, color, badge, sort_order)
VALUES ('5616', '5616', '56184', 'ๆ5ก6ๆห', 'Handshake', 'cyan', 'หมวดใหม่', 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO categories (id, name, full_name, description, icon, color, badge, sort_order)
VALUES ('cat-1788946775522', 'ประกาศบริษัท', 'ประกาศบริษัท', '', 'FileText', 'amber', 'หมวดใหม่', 0)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES ('quotation', 'org-crestzendo', 'quotation', 'ใบเสนอราคามาตรฐาน', 'Standard template slug', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES ('nda', 'org-crestzendo', 'nda', 'หนังสือสัญญาไม่เปิดเผยข้อมูล', 'Standard template slug', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES ('partner', 'org-crestzendo', 'partner', 'สัญญาแต่งตั้งพันธมิตรตัวแทนจำหน่าย', 'Standard template slug', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES ('distributor', 'org-crestzendo', 'distributor', 'สัญญาแต่งตั้งและจัดจำหน่ายซอฟต์แวร์', 'Standard template slug', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES ('notification', 'org-crestzendo', 'notification', 'หนังสือแจ้งและประกาศทางการ', 'Standard template slug', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES ('tmpl-quotation-standard', 'org-crestzendo', 'quotation', 'ใบเสนอราคามาตรฐาน', 'โครงสร้างเทมเพลตใบเสนอราคามาตรฐาน พร้อมระบบคำนวณภาษี VAT 7% และส่วนลด', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES ('tmpl-nda-standard', 'org-crestzendo', 'nda', 'หนังสือสัญญาไม่เปิดเผยข้อมูล', 'โครงสร้างสัญญามาตรฐานสำหรับการรักษาความลับทางการค้าและทรัพย์สินทางปัญญา', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES ('tmpl-partner-standard', 'org-crestzendo', 'partner', 'สัญญาแต่งตั้งพันธมิตรตัวแทนจำหน่าย', 'โครงสร้างสัญญาแต่งตั้งพันธมิตรทางธุรกิจ พร้อมเงื่อนไข Deal Registration', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES ('tmpl-distributor-standard', 'org-crestzendo', 'distributor', 'สัญญาแต่งตั้งและจัดจำหน่ายซอฟต์แวร์', 'โครงสร้างสัญญาแต่งตั้งตัวแทนจำหน่ายและจัดจำหน่ายซอฟต์แวร์', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO templates (id, org_id, category_id, name, description, editor_type, canvas_preset, status, is_standard)
VALUES ('tmpl-notification-standard', 'org-crestzendo', 'notification', 'หนังสือแจ้งเปลี่ยนแปลงที่ตั้งสำนักงานใหญ่', 'หนังสือแจ้งการเปลี่ยนแปลงที่อยู่และสถานที่ตั้งสำนักงานใหญ่ทางการ (ไทย-อังกฤษ)', 'document', 'a4-portrait', 'published', TRUE)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES ('tv-tmpl-quotation-standard-v1', 'tmpl-quotation-standard', 1, 'ใบเสนอราคามาตรฐาน', 'โครงสร้างเทมเพลตใบเสนอราคามาตรฐาน พร้อมระบบคำนวณภาษี VAT 7% และส่วนลด', 'quotation', '[{"id":"b_header","type":"header","title":"หัวกระดาษบริษัท","settings":{"hasLogo":true,"logoUrl":"/quotation.png","companyName":"[ ชื่อบริษัท / ผู้เสนอราคา ]","companyNameEn":"[ Company Name (EN) ]","taxId":"0-0000-00000-00-0","address":"[ ที่อยู่สำนักงานใหญ่ / สถานประกอบการ ]","phone":"02-XXX-XXXX","email":"contact@company.com","align":"split"}},{"id":"b_title","type":"doc_title","title":"หัวเรื่องเอกสาร","settings":{"titleText":"ใบเสนอราคา (QUOTATION)","subtitleText":"ต้นฉบับ / Original","align":"center"}},{"id":"b_info","type":"info_grid","title":"ข้อมูลลูกค้าและเอกสาร","settings":{"billToTitle":"Bill To:","billToCompany":"[ ชื่อบริษัทลูกค้า / ผู้รับบริการ ]","attnName":"[ ชื่อผู้ติดต่อ ]","subject":"[ ระบุเรื่อง / โครงการ ]","quotationNo":"QT-YYYYMM-XXXX","date":"[ ว/ด/ป ที่ออกเอกสาร ]","validity":"30 วัน","amName":"[ ชื่อผู้จัดทำ / Account Manager ]"}},{"id":"b_table","type":"quotation_table","title":"ตารางรายการสินค้า/บริการ","settings":{"vatRate":7,"items":[]}},{"id":"b_terms","type":"terms","title":"เงื่อนไขและข้อกำหนด","settings":{"heading":"เงื่อนไขการชำระเงินและส่งมอบ:","bullets":["ราคานี้ยังไม่รวมภาษีมูลค่าเพิ่ม (VAT 7%)","กำหนดยืนราคา 30 วันนับจากวันที่ในเอกสาร","เงื่อนไขการชำระเงิน: ภายใน 30 วันนับจากวันส่งมอบงาน"]}},{"id":"b_signatures","type":"signatures","title":"ส่วนลงนามอนุมัติ","settings":{"slots":[{"id":"s1","name":"[ ผู้มีอำนาจลงนาม / ผู้เสนอราคา ]","role":"ผู้เสนอราคา"},{"id":"s2","name":"............................................","role":"ผู้อนุมัติสั่งซื้อ / ลูกค้า"}]}}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES ('tv-tmpl-nda-standard-v1', 'tmpl-nda-standard', 1, 'หนังสือสัญญาไม่เปิดเผยข้อมูล', 'โครงสร้างสัญญามาตรฐานสำหรับการรักษาความลับทางการค้าและทรัพย์สินทางปัญญา', 'nda', '[{"id":"b_header","type":"header","title":"หัวกระดาษ","settings":{"hasLogo":true,"logoUrl":"/quotation.png","companyName":"[ ชื่อบริษัท / องค์กร ]","companyNameEn":"[ Company Name (EN) ]","taxId":"0-0000-00000-00-0","address":"[ ที่อยู่สำนักงานใหญ่ ]","phone":"02-XXX-XXXX","email":"legal@company.com","align":"split"}},{"id":"b_title","type":"doc_title","title":"หัวเรื่อง","settings":{"titleText":"หนังสือสัญญาไม่เปิดเผยข้อมูล","subtitleText":"Non-Disclosure Agreement (NDA)","align":"center"}},{"id":"b_text","type":"text_block","title":"โครงสร้างข้อสัญญา","settings":{"content":"สัญญาฉบับนี้ทำขึ้นระหว่าง [ ชื่อคู่สัญญาฝ่ายเปิดเผยข้อมูล ] และ [ ชื่อคู่สัญญาฝ่ายรับข้อมูล ] โดยทั้งสองฝ่ายตกลงรักษาความลับของข้อมูลตามขอบเขตและระยะเวลาที่ระบุในสัญญานี้"}},{"id":"b_terms","type":"terms","title":"ข้อกำหนดความลับ","settings":{"heading":"ข้อกำหนดและขอบเขตความลับ:","bullets":["ห้ามเปิดเผยข้อมูลความลับแก่บุคคลภายนอกโดยไม่ได้รับความยินยอมเป็นลายลักษณ์อักษร","ใช้ข้อมูลความลับเพื่อวัตถุประสงค์ตามที่ตกลงกันไว้เท่านั้น","สัญญานี้มีผลบังคับใช้ตามระยะเวลาที่กำหนดในสัญญา"]}},{"id":"b_signatures","type":"signatures","title":"ลงนามทั้งสองฝ่าย","settings":{"slots":[{"id":"s1","name":"[ ผู้มีอำนาจลงนามฝ่ายเปิดเผยข้อมูล ]","role":"ฝ่ายเปิดเผยข้อมูล"},{"id":"s2","name":"............................................","role":"ฝ่ายรับข้อมูล"}]}}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES ('tv-tmpl-partner-standard-v1', 'tmpl-partner-standard', 1, 'สัญญาแต่งตั้งพันธมิตรตัวแทนจำหน่าย', 'โครงสร้างสัญญาแต่งตั้งพันธมิตรทางธุรกิจ พร้อมเงื่อนไข Deal Registration', 'partner', '[{"id":"b_header","type":"header","title":"หัวกระดาษ","settings":{"hasLogo":true,"logoUrl":"/quotation.png","companyName":"[ ชื่อบริษัทผู้แต่งตั้ง ]","companyNameEn":"[ Company Name (EN) ]","taxId":"0-0000-00000-00-0","address":"[ ที่อยู่สำนักงานใหญ่ ]","phone":"02-XXX-XXXX","email":"partner@company.com","align":"split"}},{"id":"b_title","type":"doc_title","title":"หัวเรื่อง","settings":{"titleText":"สัญญาแต่งตั้งพันธมิตรตัวแทนจำหน่าย","subtitleText":"Partner Agreement","align":"center"}},{"id":"b_text","type":"text_block","title":"รายละเอียดข้อตกลง","settings":{"content":"สัญญานี้จัดทำขึ้นระหว่าง [ ชื่อบริษัทผู้แต่งตั้ง ] และ [ ชื่อตัวแทนพันธมิตร ] เพื่อแต่งตั้งให้เป็นตัวแทนพันธมิตรในการจำหน่ายและให้บริการผลิตภัณฑ์ตามเงื่อนไขที่ตกลงกัน"}},{"id":"b_terms","type":"terms","title":"เงื่อนไขพันธมิตร","settings":{"heading":"เงื่อนไขและสิทธิประโยชน์พันธมิตร:","bullets":["ส่วนแบ่งผลประโยชน์ทางการค้าตามระดับพันธมิตรที่กำหนด","การลงทะเบียนโครงการผ่านระบบ Deal Registration","ระยะเวลาสัญญาและเงื่อนไขการต่ออายุสัญญา"]}},{"id":"b_signatures","type":"signatures","title":"ลงนามแต่งตั้ง","settings":{"slots":[{"id":"s1","name":"[ ผู้มีอำนาจลงนามผู้แต่งตั้ง ]","role":"ผู้แต่งตั้ง"},{"id":"s2","name":"............................................","role":"ผู้รับการแต่งตั้ง (พันธมิตร)"}]}}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES ('tv-tmpl-distributor-standard-v1', 'tmpl-distributor-standard', 1, 'สัญญาแต่งตั้งและจัดจำหน่ายซอฟต์แวร์', 'โครงสร้างสัญญาแต่งตั้งตัวแทนจำหน่ายและจัดจำหน่ายซอฟต์แวร์', 'distributor', '[{"id":"b_header","type":"header","title":"หัวกระดาษ","settings":{"hasLogo":true,"logoUrl":"/quotation.png","companyName":"[ ชื่อบริษัทผู้จัดจำหน่ายหลัก ]","companyNameEn":"[ Principal Company (EN) ]","taxId":"0-0000-00000-00-0","address":"[ ที่อยู่สำนักงานใหญ่ ]","phone":"02-XXX-XXXX","email":"distributor@company.com","align":"split"}},{"id":"b_title","type":"doc_title","title":"หัวเรื่อง","settings":{"titleText":"สัญญาแต่งตั้งและจัดจำหน่ายซอฟต์แวร์","subtitleText":"Distributor Agreement","align":"center"}},{"id":"b_text","type":"text_block","title":"รายละเอียดข้อสัญญา","settings":{"content":"สัญญานี้จัดทำขึ้นระหว่าง [ ชื่อบริษัทผู้จัดจำหน่ายหลัก ] และ [ ชื่อบริษัทตัวแทนจำหน่าย ] เพื่อกำหนดสิทธิและหน้าที่ในการจำหน่ายผลิตภัณฑ์ซอฟต์แวร์ในเขตพื้นที่ที่กำหนด"}},{"id":"b_terms","type":"terms","title":"ข้อกำหนดการจำหน่าย","settings":{"heading":"เงื่อนไขการจำหน่ายและเป้าหมาย:","bullets":["กำหนดเป้าหมายยอดจำหน่ายและอัตราส่วนลดตามระดับตัวแทน","ขอบเขตพื้นที่และสิทธิการจัดจำหน่ายในอาณาเขตที่ตกลง","การสนับสนุนด้านการตลาดและการฝึกอบรมผลิตภัณฑ์"]}},{"id":"b_signatures","type":"signatures","title":"ลงนามคู่สัญญา","settings":{"slots":[{"id":"s1","name":"[ ผู้มีอำนาจลงนามผู้จัดจำหน่ายหลัก ]","role":"ผู้จัดจำหน่ายหลัก"},{"id":"s2","name":"............................................","role":"ตัวแทนจำหน่าย"}]}}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES ('tv-tmpl-notification-standard-v1', 'tmpl-notification-standard', 1, 'หนังสือแจ้งเปลี่ยนแปลงที่ตั้งสำนักงานใหญ่', 'หนังสือแจ้งการเปลี่ยนแปลงที่อยู่และสถานที่ตั้งสำนักงานใหญ่ทางการ (ไทย-อังกฤษ)', 'notification', '[{"id":"b_header","type":"header","title":"หัวกระดาษ","settings":{"hasLogo":true,"logoUrl":"/quotation.png","companyName":"บริษัท เครสท์ เซนโด จำกัด","companyNameEn":"CREST ZENDO CO., LTD.","taxId":"0105558073755","address":"8/40 The Connect 37, ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210","phone":"02-123-4567","email":"contact@crestzendo.com","align":"split"}},{"id":"b_title","type":"doc_title","title":"หัวเรื่อง","settings":{"titleText":"หนังสือแจ้งเปลี่ยนแปลงที่ตั้งสำนักงานใหญ่","subtitleText":"NOTICE OF HEAD OFFICE RELOCATION","align":"center"}},{"id":"b_info","type":"info_grid","title":"ข้อมูลหนังสือ","settings":{"billToTitle":"เรียน:","billToCompany":"ท่านคู่ค้า ลูกค้า และพันธมิตรทางธุรกิจทุกท่าน","attnName":"ผู้มีอุปการคุณทุกท่าน","subject":"แจ้งเปลี่ยนแปลงสถานที่ตั้งสำนักงานใหญ่แห่งใหม่","quotationNo":"TRAC-2609001","date":"01 กันยายน 2569","validity":"มีผล 16 กันยายน 2569","amName":"ฝ่ายบริหารจัดการทั่วไป"}},{"id":"b_text","type":"text_block","title":"ข้อความหนังสือแจ้ง","settings":{"content":"บริษัท เครสท์ เซนโด จำกัด ขอเรียนแจ้งให้ท่านทราบว่า บริษัทฯ ได้ดำเนินการย้ายสถานที่ตั้งสำนักงานใหญ่แห่งใหม่ เพื่อรองรับการขยายตัวทางธุรกิจและการให้บริการที่มีประสิทธิภาพยิ่งขึ้น โดยมีผลบังคับใช้ตั้งแต่วันที่ 16 กันยายน 2569 เป็นต้นไป"}},{"id":"b_terms","type":"terms","title":"เปรียบเทียบที่อยู่เดิมและใหม่","settings":{"heading":"รายละเอียดสถานที่ตั้งสำนักงานใหญ่:","bullets":["ที่อยู่เดิม: 45 ซอยโกสุมรวมใจ 37 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210","ที่อยู่ใหม่ (มีผล 16 ก.ย. 2569): 8/40 The Connect 37, ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210","หมายเลขโทรศัพท์และช่องทางการติดต่อทางอิเล็กทรอนิกส์ยังคงใช้งานได้ตามปกติ"]}},{"id":"b_signatures","type":"signatures","title":"ผู้มีอำนาจลงนาม","settings":{"slots":[{"id":"s1","name":"นายศรายุทธ โกสิยารักษ์","role":"กรรมการผู้จัดการ / CEO"}]}}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES ('tmpl-quotation-standard-v1', 'tmpl-quotation-standard', 1, 'ใบเสนอราคามาตรฐาน', 'โครงสร้างเทมเพลตใบเสนอราคามาตรฐาน พร้อมระบบคำนวณภาษี VAT 7% และส่วนลด', 'quotation', '[{"id":"b_header","type":"header","title":"หัวกระดาษบริษัท","settings":{"hasLogo":true,"logoUrl":"/quotation.png","companyName":"[ ชื่อบริษัท / ผู้เสนอราคา ]","companyNameEn":"[ Company Name (EN) ]","taxId":"0-0000-00000-00-0","address":"[ ที่อยู่สำนักงานใหญ่ / สถานประกอบการ ]","phone":"02-XXX-XXXX","email":"contact@company.com","align":"split"}},{"id":"b_title","type":"doc_title","title":"หัวเรื่องเอกสาร","settings":{"titleText":"ใบเสนอราคา (QUOTATION)","subtitleText":"ต้นฉบับ / Original","align":"center"}},{"id":"b_info","type":"info_grid","title":"ข้อมูลลูกค้าและเอกสาร","settings":{"billToTitle":"Bill To:","billToCompany":"[ ชื่อบริษัทลูกค้า / ผู้รับบริการ ]","attnName":"[ ชื่อผู้ติดต่อ ]","subject":"[ ระบุเรื่อง / โครงการ ]","quotationNo":"QT-YYYYMM-XXXX","date":"[ ว/ด/ป ที่ออกเอกสาร ]","validity":"30 วัน","amName":"[ ชื่อผู้จัดทำ / Account Manager ]"}},{"id":"b_table","type":"quotation_table","title":"ตารางรายการสินค้า/บริการ","settings":{"vatRate":7,"items":[]}},{"id":"b_terms","type":"terms","title":"เงื่อนไขและข้อกำหนด","settings":{"heading":"เงื่อนไขการชำระเงินและส่งมอบ:","bullets":["ราคานี้ยังไม่รวมภาษีมูลค่าเพิ่ม (VAT 7%)","กำหนดยืนราคา 30 วันนับจากวันที่ในเอกสาร","เงื่อนไขการชำระเงิน: ภายใน 30 วันนับจากวันส่งมอบงาน"]}},{"id":"b_signatures","type":"signatures","title":"ส่วนลงนามอนุมัติ","settings":{"slots":[{"id":"s1","name":"[ ผู้มีอำนาจลงนาม / ผู้เสนอราคา ]","role":"ผู้เสนอราคา"},{"id":"s2","name":"............................................","role":"ผู้อนุมัติสั่งซื้อ / ลูกค้า"}]}}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES ('tmpl-nda-standard-v1', 'tmpl-nda-standard', 1, 'หนังสือสัญญาไม่เปิดเผยข้อมูล', 'โครงสร้างสัญญามาตรฐานสำหรับการรักษาความลับทางการค้าและทรัพย์สินทางปัญญา', 'nda', '[{"id":"b_nda_header","type":"header","title":"หัวกระดาษ","settings":{"hasLogo":true,"logoUrl":"/preview.webp","companyName":"{{company_name}}","companyNameEn":"{{company_name_en}}","taxId":"{{company_tax_id}}","address":"{{company_address}}","phone":"{{company_phone}}","email":"{{company_email}}","align":"split"}},{"id":"b_nda_title","type":"doc_title","title":"หัวเรื่อง","settings":{"titleText":"หนังสือสัญญาไม่เปิดเผยข้อมูล","subtitleText":"(NON-DISCLOSURE AGREEMENT - NDA)","align":"center"}},{"id":"b_nda_preamble","type":"contract_preamble","title":"คำนำสัญญาและคู่สัญญา","settings":{"locationPrefix":"สัญญาฉบับนี้ทำขึ้น ณ","locationText":"{{contract_location}}","datePrefix":"เมื่อวันที่","dateText":"{{contract_date}}","betweenLabel":"ระหว่าง:","party1Text":"{{company_name}} สำนักงานใหญ่ ตั้งอยู่เลขที่ 8/40 เดอะ คอนเนค 37 ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210 ประเทศไทย ซึ่งต่อไปในสัญญานี้จะเรียกว่า “ผู้เปิดเผยข้อมูล” (Disclosing Party) ฝ่ายหนึ่ง","andLabel":"และ","party2Text":"{{customer_company}} สำนักงานใหญ่ ตั้งอยู่เลขที่ {{customer_address}} ซึ่งต่อไปในสัญญานี้จะเรียกว่า “ผู้รับข้อมูล” (Receiving Party) อีกฝ่ายหนึ่ง","partiesSummary":"(รวมเรียกว่า “คู่สัญญาทั้งสองฝ่าย” หรือเรียกว่า “ฝ่าย” หากหมายถึงฝ่ายใดฝ่ายหนึ่ง)","recital":"โดยที่ ผู้เปิดเผยข้อมูล เป็นผู้ประกอบธุรกิจจัดจำหน่ายและให้บริการด้านซอฟต์แวร์ ไอทีโซลูชัน และเทคโนโลยีดิจิทัล และมีความประสงค์จะเปิดเผยข้อมูลที่มีลักษณะเป็นความลับของตนให้แก่ ผู้รับข้อมูล เพื่อวัตถุประสงค์ในการประเมิน ความร่วมมือ หรือการทำธุรกิจร่วมกัน และผู้รับข้อมูลตกลงที่จะรับและรักษาข้อมูลความลับดังกล่าวตามข้อกำหนดและเงื่อนไขในสัญญานี้ คู่สัญญาจึงตกลงทำสัญญามีข้อความดังต่อไปนี้:"}},{"id":"b_nda_sec_1","type":"contract_section","title":"1. คำนิยามข้อมูลที่เป็นความลับ (Definition of Confidential Information)","settings":{"intro":"1.1. “ข้อมูลที่เป็นความลับ” (Confidential Information) หมายถึง ข้อมูล เอกสาร สารสนเทศ เทคโนโลยี และความรู้ความชำนาญ (Know-how) ทั้งหมด ไม่ว่าจะอยู่ในรูปแบบใด (ลายลักษณ์อักษร, วาจา, อิเล็กทรอนิกส์, รหัสคอมพิวเตอร์, หรือสื่อบันทึกข้อมูลอื่นใด) ที่ผู้เปิดเผยข้อมูลส่งมอบ เปิดเผย หรือให้เข้าถึงแก่ผู้รับข้อมูล ทั้งก่อนและหลังวันทำสัญญาฉบับนี้ ซึ่งรวมถึงแต่ไม่จำกัดเพียง:","content":null,"bullets":["ข้อมูลด้านเทคนิคและซอฟต์แวร์: ซอร์ซโค้ด (Source Code), ออบเจกต์โค้ด (Object Code), อัลกอริทึม (Algorithms), สถาปัตยกรรมระบบ (System Architecture), โครงสร้างฐานข้อมูล, เอกสาร API, คู่มือเทคนิค, ผลการทดสอบ, บัก (Bugs), Credential, Log, API Token, User Experience (UX), User Interface (UI), Credential ต่างๆ, Knowledge Base และข้อผิดพลาดของระบบ","ข้อมูลทางการค้าและธุรกิจ: ข้อมูลราคาต้นทุน (Cost Structure), โครงสร้างส่วนลด (Discount Schemes), อัตราค่าคอมมิชชั่น, บันทึกการประชุม, แผนกลยุทธ์การตลาด, แผนการขาย, รายชื่อและข้อมูลลูกค้าปลายทาง (End-customers), รายชื่อผู้จัดจำหน่าย และประมาณการทางการเงิน","ข้อมูลส่วนบุคคล (Personal Data): ข้อมูลส่วนบุคคลของพนักงาน ลูกค้า หรือผู้ใช้งานระบบตามกฎหมายว่าด้วยการคุ้มครองข้อมูลส่วนบุคคล (PDPA) ที่ผู้รับข้อมูลเข้าถึงได้ระหว่างการทำระบบ การทดสอบ (PoC) หรือการสนับสนุนทางเทคนิค (Technical Support)","ความคิดสร้างสรรค์และทรัพย์สินทางปัญญา: แบบระเบียบ ขั้นตอนการทำงาน ต้นแบบ (Prototypes) สิทธิบัตร เครื่องหมายการค้า หรือความลับทางการค้าที่ยังไม่ได้เปิดเผยต่อสาธารณะ"],"subClauses":null,"closing":null}},{"id":"b_nda_sec_2","type":"contract_section","title":"2. ข้อยกเว้นข้อมูลที่เป็นความลับ (Exclusions from Confidential Information)","settings":{"intro":"ข้อมูลความลับตามข้อ 1 ให้ไม่รวมถึงข้อมูลใดๆ ที่ผู้รับข้อมูลสามารถพิสูจน์ได้ด้วยหลักฐานเป็นลายลักษณ์อักษรว่า:","content":null,"bullets":null,"subClauses":["2.1. เป็นข้อมูลที่ตกเป็นของสาธารณะหรือเปิดเผยทั่วไปอยู่แล้วก่อน หรือในเวลาที่เปิดเผย โดยไม่ได้เกิดจากการกระทำผิดสัญญาหรือการละเมิดของผู้รับข้อมูล หรือบุคคลในสังกัด","2.2. เป็นข้อมูลที่ผู้รับข้อมูลมีอยู่แล้วโดยชอบด้วยกฎหมายก่อนที่จะได้รับจากผู้เปิดเผยข้อมูล โดยไม่มีข้อผูกมัดเรื่องการรักษาความลับใดๆ","2.3. เป็นข้อมูลที่ผู้รับข้อมูลได้รับมาจากบุคคลที่สามโดยชอบธรรม โดยบุคคลที่สามดังกล่าวมีสิทธิ์เปิดเผยได้และไม่มีข้อผูกมัดเรื่องการรักษาความลับกับผู้เปิดเผยข้อมูล","2.4. เป็นข้อมูลที่ผู้รับข้อมูลพัฒนาขึ้นมาเองโดยอิสระ (Independently Developed) โดยไม่ได้อ้างอิงหรือใช้ข้อมูลความลับของผู้เปิดเผยข้อมูลเลย","2.5. ข้อมูลที่ต้องเปิดเผยตามคำสั่งศาล หน่วยงานราชการ หรือองค์กรกำกับดูแลตามกฎหมาย โดยผู้รับข้อมูลต้องแจ้งให้ผู้เปิดเผยข้อมูลทราบทันทีล่วงหน้าเป็นลายลักษณ์อักษร (หากไม่ขัดต่อกฎหมาย) เพื่อให้ผู้เปิดเผยข้อมูลมีโอกาสคัดค้านหรือร้องขอมาตรการคุ้มครอง"],"closing":null}},{"id":"b_nda_sec_3","type":"contract_section","title":"3. วัตถุประสงค์ในการเปิดเผยข้อมูล (Purpose of Disclosure)","settings":{"intro":"3.1. ผู้เปิดเผยข้อมูลเปิดเผยข้อมูลความลับแก่ผู้รับข้อมูล เพื่อวัตถุประสงค์เฉพาะเจาะจงดังต่อไปนี้เท่านั้น (“วัตถุประสงค์”):","content":null,"bullets":["เพื่อการประเมินความเป็นไปได้ในการเข้าทำสัญญาความร่วมมือทางธุรกิจ การเป็นพันธมิตร (Partner), ผู้จัดจำหน่าย (Distributor) หรือตัวแทนจำหน่าย (Reseller)","เพื่อการทดสอบระบบ การสาธิต หรือการทำระบบทดลองใช้ (Proof of Concept - PoC) ให้แก่คู่สัญญาหรือลูกค้าเป้าหมาย","เพื่อการบูรณาการระบบ (System Integration), การติดตั้ง, การพัฒนาต่อเติมตามคำขอ หรือการให้บริการสนับสนุนทางเทคนิค (Technical Support)","เพื่อสนับสนุนการขาย หรือการให้บริการที่เกี่ยวข้องกับข้อมูลนั้น"],"subClauses":null,"closing":"3.2. ผู้รับข้อมูลตกลงอย่างเคร่งครัดว่าจะไม่นำข้อมูลความลับไปใช้เพื่อวัตถุประสงค์อื่นใด นอกเหนือจากที่ระบุในข้อ 3.1 โดยเฉพาะอย่างยิ่ง ห้ามนำไปใช้เพื่อประโยชน์ทางการค้าของตนเองหรือบุคคลภายนอก หรือนำไปใช้ในลักษณะที่เป็นแข่งขันกับผู้เปิดเผยข้อมูล"}},{"id":"b_nda_sec_4","type":"contract_section","title":"4. หน้าที่และความรับผิดชอบของผู้รับข้อมูล (Obligations of Receiving Party)","settings":{"intro":"ผู้รับข้อมูลตกลงและรับรองที่จะปฏิบัติตามหน้าที่ดังต่อไปนี้:","content":null,"bullets":null,"subClauses":["4.1. การเก็บรักษาความลับ: ต้องระมัดระวังและรักษาข้อมูลความลับด้วยมาตรฐานความปลอดภัยที่ไม่น้อยกว่าระดับที่ตนใช้รักษาข้อมูลความลับของตนเอง และต้องไม่ต่ำกว่ามาตรฐานระมัดระวังตามวิญญูชน","4.2. ข้อจำกัดในการเข้าถึง (Need-to-Know Basis): จำกัดการเปิดเผยข้อมูลความลับเฉพาะแก่กรรมการ พนักงาน ลูกจ้าง หรือที่ปรึกษาทางกฎหมาย/การเงินของผู้รับข้อมูลที่มีความจำเป็นต้องทราบข้อมูลดังกล่าวเพื่อวัตถุประสงค์ข้างต้นเท่านั้น และบุคคลดังกล่าวต้องมีพันธะผูกพันในการรักษาความลับไม่ต่ำกว่าข้อกำหนดในสัญญานี้","4.3. มาตรการความมั่นคงปลอดภัยทางไซเบอร์: จัดให้มีมาตรการรักษาความปลอดภัยทางเทคนิคและการบริหารจัดการ (Technical and Organizational Security Measures) ที่เหมาะสม เช่น การเข้ารหัสข้อมูล (Encryption), การกำหนดสิทธิ์เข้าถึง (Access Control), การป้องกันไวรัสและมัลแวร์เพื่อป้องกันการเข้าถึง การสูญหาย หรือการรั่วไหลโดยไม่ได้รับอนุญาต","4.4. การแจ้งเหตุละเมิด: หากพบหรือสงสัยว่ามีการรั่วไหล การเข้าถึงโดยมิชอบ หรือการละเมิดข้อมูลความลับ ผู้รับข้อมูลต้องแจ้งให้ผู้เปิดเผยข้อมูลทราบทันทีภายใน 24 ชั่วโมงนับแต่พบเหตุ พร้อมทั้งร่วมมือในการระงับและแก้ไขเหตุการณ์ดังกล่าว"],"closing":null}},{"id":"b_nda_sec_5","type":"contract_section","title":"5. ข้อจำกัดเรื่องวิศวกรรมย้อนกลับ (Strict No Reverse Engineering/Decompilation)","settings":{"intro":null,"content":"ผู้รับข้อมูลตกลงและรับรองว่าจะไม่ทำการ (และจะไม่ยินยอมหรือมอบหมายให้บุคคลภายนอกทำการ) ถอดรหัส (Decompile), ทำวิศวกรรมย้อนกลับ (Reverse Engineer), ถอดประกอบ (Disassemble), แปลงรหัส (Translate) หรือพยายามแกะรหัสเพื่อเข้าถึงซอร์ซโค้ด (Source Code), อัลกอริทึม หรือสถาปัตยกรรมภายในของซอฟต์แวร์ ระบบ หรือเทคโนโลยีของผู้เปิดเผยข้อมูล ไม่ว่าด้วยวิธีใดๆ เว้นแต่จะได้รับความยินยอมเป็นลายลักษณ์อักษรจากผู้เปิดเผยข้อมูลก่อนเท่านั้น","bullets":null,"subClauses":null,"closing":null}},{"id":"b_nda_sec_6","type":"contract_section","title":"6. ระยะเวลาของสัญญาและการมีผลต่อเนื่อง (Term and Survival)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["6.1. สัญญาฉบับนี้มีผลบังคับใช้นับแต่วันที่ระบุในตอนต้นของสัญญา และจะมีผลบังคับเป็นระยะเวลา 3 ปี นับจากวันทำสัญญา (“ระยะเวลาสัญญา”)","6.2. แม้ว่าสัญญานี้จะสิ้นสุดลงหรือระงับไปไม่ว่าด้วยเหตุใดก็ตาม ข้อผูกพันในการรักษาความลับตามสัญญานี้ยังคงมีผลบังคับต่อเนื่องไปอีกเป็นระยะเวลา 3 ปีนับแต่วันที่สัญญานี้สิ้นสุดลง หรือจนกว่าข้อมูลความลับนั้นจะตกเป็นของสาธารณะโดยมิใช่ความผิดของผู้รับข้อมูล (แล้วแต่วาระใดจะถึงก่อน)","6.3. สำหรับข้อมูลความลับที่เป็นความลับทางการค้า (Trade Secrets) หรือซอร์ซโค้ด (Source Code) ภาระผูกพันในการรักษาความลับจะมีผลบังคับอย่างถาวรโดยไม่มีกำหนดระยะเวลาสิ้นสุด"],"closing":null}},{"id":"b_nda_sec_7","type":"contract_section","title":"7. การจัดการข้อมูลเมื่อสัญญาสินสุด (Return or Destruction of Information)","settings":{"intro":"7.1. เมื่อสัญญานี้สิ้นสุดลง หรือเมื่อได้รับการร้องขอเป็นลายลักษณ์อักษรจากผู้เปิดเผยข้อมูล ผู้รับข้อมูลต้องดำเนินการทันทีภายในระยะเวลา 14 วัน ดังนี้:","content":null,"bullets":["คืนเอกสาร สื่อบันทึกข้อมูล และสำเนาข้อมูลความลับทั้งหมดให้แก่ผู้เปิดเผยข้อมูล หรือ","ทำลายข้อมูลความลับรวมถึงไฟล์อิเล็กทรอนิกส์ สำเนา สรุป หรือเอกสารดัดแปลงที่เกี่ยวข้องทั้งหมดอย่างถาวร ไม่สามารถกู้คืนได้"],"subClauses":null,"closing":"7.2. ผู้รับข้อมูลต้องจัดทำหนังสือรับรองเป็นลายลักษณ์อักษร ลงนามโดยกรรมการผู้มีอำนาจเพื่อยืนยันว่าได้ส่งคืนหรือทำลายข้อมูลความลับทั้งหมดเรียบร้อยแล้วส่งมอบให้แก่ผู้เปิดเผยข้อมูล (เว้นแต่ข้อมูลที่จำเป็นต้องจัดเก็บตามข้อกำหนดทางกฎหมาย หรือระบบสำรองข้อมูลอัตโนมัติ (Automated Backup) ซึ่งต้องได้รับการรักษาความลับตามสัญญานี้ต่อไป)"}},{"id":"b_nda_sec_8","type":"contract_section","title":"8. การเยียวยาเมื่อผิดสัญญาและค่าเสียหาย (Remedies for Breach)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["8.1. คู่สัญญาตกลงว่าการเปิดเผยหรือใช้ข้อมูลความลับโดยขัดต่อสัญญานี้ จะก่อให้เกิดความเสียหายอย่างร้ายแรงแก่ผู้เปิดเผยข้อมูล ซึ่งไม่สามารถชดเชยด้วยเยียวยาทางการเงิน หรือค่าเสียหายเพียงอย่างเดียวได้","8.2. ในกรณีที่มีการฝ่าฝืนหรือมีแนวโน้มว่าจะฝ่าฝืนสัญญานี้ ผู้เปิดเผยข้อมูลมีสิทธิร้องขอต่อศาลที่มีเขตอำนาจเพื่อให้ออกคำสั่งคุ้มครองชั่วคราว คำสั่งห้ามกระทำการ (Injunctive Relief) หรือมาตรการบรรเทาทุกข์ตามกฎหมายอื่นใด โดยไม่จำเป็นต้องพิสูจน์ความเสียหายเป็นตัวเงินจริง","8.3. สิทธิตามข้อ 8.2 ไม่ตัดสิทธิผู้เปิดเผยข้อมูลในการเรียกร้องค่าเสียหายที่เกิดขึ้นจริง (Actual Damages) ค่าขาดประโยชน์ และค่าใช้จ่ายทางกฎหมายรวมถึงค่าทนายความตามสมควรจากผู้รับข้อมูล"],"closing":null}},{"id":"b_nda_sec_9","type":"contract_section","title":"9. กฎหมายที่ใช้บังคับและเขตอำนาจศาล (Governing Law and Jurisdiction)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["9.1. สัญญาฉบับนี้ให้ตีความและบังคับใช้ตามกฎหมายแห่งราชอาณาจักรไทย","9.2. หากเกิดข้อพิพาท ข้อขัดแย้ง หรือการเรียกร้องใดๆ ที่เกิดขึ้นจากหรือเกี่ยวเนื่องกับสัญญานี้รวมทั้งการผิดสัญญา คู่สัญญาทั้งสองฝ่ายตกลงจะพยายามระงับข้อพิพาทโดยการเจรจาด้วยความซื่อสัตย์สุจริตก่อน หากไม่สามารถตกลงกันได้ภายใน 30 วัน ให้ส่งเรื่องให้ศาลในประเทศไทยที่มีเขตอำนาจ เป็นผู้พิจารณาชี้ขาด"],"closing":null}},{"id":"b_nda_sec_10","type":"contract_section","title":"10. บททั่วไป (General Provisions)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["10.1. ไม่มีการโอนสิทธิในทรัพย์สินทางปัญญา: การเปิดเผยข้อมูลความลับตามสัญญานี้ไม่ถือเป็นการโอนสิทธิ์ มอบสิทธิ์ (License) หรือให้สิทธิใดๆ ในสิทธิบัตร ลิขสิทธิ์ เครื่องหมายการค้า หรือทรัพย์สินทางปัญญาของผู้เปิดเผยข้อมูลแก่ผู้รับข้อมูล","10.2. การแก้ไขเพิ่มเติม: การแก้ไขหรือเปลี่ยนแปลงสัญญานี้จะทำได้ต่อเมื่อทำเป็นหนังสือและลงนามโดยผู้มีอำนาจของทั้งสองฝ่ายเท่านั้น","10.3. การแยกออกจากกันได้ (Severability): หากข้อกำหนดใดในสัญญานี้ตกเป็นโมฆะ หรือไม่สามารถบังคับใช้ได้ตามกฎหมาย ให้ข้อกำหนดส่วนที่เหลือยังคงมีผลบังคับใช้ได้โดยสมบูรณ์"],"closing":null}},{"id":"b_nda_witness","type":"text_block","title":"พยานหลักฐาน","settings":{"content":"เพื่อเป็นหลักฐานแห่งการนี้ คู่สัญญาโดยผู้มีอำนาจลงนามได้อ่านและเข้าใจข้อความในสัญญานี้โดยละเอียดตลอดแล้ว เห็นว่าถูกต้องตรงตามเจตนา จึงได้ลงลายมือชื่อและประทับตราสำคัญ (ถ้ามี) ไว้เป็นสำคัญต่อหน้าพยาน ณ วัน เดือน ปี ที่ระบุไว้ข้างต้น"}},{"id":"b_nda_signatures","type":"signatures","title":"ลงนามทั้งสองฝ่าย","settings":{"slots":[{"id":"s1","name":"{{authorized_signatory_name}}","role":"ผู้เปิดเผยข้อมูล (Disclosing Party)"},{"id":"s2","name":"{{customer_signatory_name}}","role":"ผู้รับข้อมูล (Receiving Party)"}]}}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES ('tmpl-partner-standard-v1', 'tmpl-partner-standard', 1, 'สัญญาแต่งตั้งพันธมิตรตัวแทนจำหน่าย', 'โครงสร้างสัญญาแต่งตั้งพันธมิตรทางธุรกิจ พร้อมเงื่อนไข Deal Registration', 'partner', '[{"id":"b_partner_header","type":"header","title":"หัวกระดาษ","settings":{"hasLogo":true,"logoUrl":"/Partner-logo.webp","companyName":"{{company_name}}","companyNameEn":"{{company_name_en}}","taxId":"{{company_tax_id}}","address":"{{company_address}}","phone":"{{company_phone}}","email":"{{company_email}}","align":"split"}},{"id":"b_partner_title","type":"doc_title","title":"หัวเรื่อง","settings":{"titleText":"สัญญาแต่งตั้งพันธมิตรตัวแทนจำหน่าย","subtitleText":"(Partner Agreement)","align":"center"}},{"id":"b_partner_preamble","type":"contract_preamble","title":"คำนำสัญญาและคู่สัญญา","settings":{"locationPrefix":"สัญญาฉบับนี้ทำขึ้น ณ","locationText":"{{contract_location}}","datePrefix":"สัญญาฉบับนี้ทำขึ้น ณ วันที่","dateText":"{{contract_date}}","betweenLabel":"ระหว่าง:","party1Text":"{{company_name}} เลขทะเบียนนิติบุคคล {{company_tax_id}} {{company_address}} (ซึ่งต่อไปในสัญญานี้จะเรียกว่า “Distributor” หรือ “ผู้จัดจำหน่ายหลัก”) ฝ่ายหนึ่ง","andLabel":"กับ","party2Text":"{{customer_company}} เลขทะเบียนนิติบุคคล {{customer_tax_id}} สำนักงานใหญ่ ตั้งอยู่เลขที่ {{customer_address}} (ซึ่งต่อไปในสัญญานี้จะเรียกว่า “Reseller” หรือ “ตัวแทนจำหน่าย”) อีกฝ่ายหนึ่ง","recital":"คู่สัญญาทั้งสองฝ่ายตกลงทำสัญญาแต่งตั้งตัวแทนจำหน่าย เพื่อทำการตลาด นำเสนอ และจัดจำหน่ายผลิตภัณฑ์ ซอฟต์แวร์ และเครื่องมือทางไอที (ซึ่งต่อไปนี้เรียกว่า “ผลิตภัณฑ์”) โดยมีข้อกำหนดและเงื่อนไขดังต่อไปนี้:"}},{"id":"b_partner_sec_1","type":"contract_section","title":"ข้อ 1. นิยามศัพท์ (Definitions)","settings":{"intro":"ในสัญญานี้ คำหรือข้อความดังต่อไปนี้ให้มีความหมายตามที่กำหนดไว้ เว้นแต่บริบทจะกำหนดเป็นอย่างอื่น:","content":null,"bullets":null,"subClauses":["1.1 “เจ้าของผลิตภัณฑ์” (Vendor) หมายถึง บุคคล นิติบุคคล หรือผู้พัฒนาซอฟต์แวร์ ซึ่งเป็นผู้ถือครองลิขสิทธิ์ ทรัพย์สินทางปัญญา และสิทธิ์โดยชอบด้วยกฎหมายในตัวผลิตภัณฑ์ซอฟต์แวร์แต่เพียงผู้เดียว (หรือตามสิทธิ์ที่ได้รับอนุญาต)","1.2 “ผู้ใช้ปลายทาง” (End User) หมายถึง บุคคล นิติบุคคล หรือองค์กรที่เป็นผู้ซื้อ ได้รับสิทธิ์ หรือจัดหาผลิตภัณฑ์ซอฟต์แวร์ไปเพื่อวัตถุประสงค์ในการใช้งานจริงภายในองค์กรของตนเอง ไม่ใช่เพื่อวัตถุประสงค์ในการนำไปจำหน่ายหรือให้เช่าช่วง","1.3 “ผลิตภัณฑ์” (Product) หมายถึง ซอฟต์แวร์ ระบบปฏิบัติการ หรือเครื่องมือทางไอที รวมถึง “สิทธิ์การใช้งาน” เอกสารคู่มือ การอัปเดต และแพตช์แก้ไขความปลอดภัย ซึ่ง “ผู้จัดจำหน่ายหลัก” ได้รับสิทธิ์จัดจำหน่ายจาก “เจ้าของผลิตภัณฑ์”","1.4 “สิทธิ์การใช้งาน” (License/Subscription) หมายถึง สิทธิ์ทางกฎหมายที่ “เจ้าของผลิตภัณฑ์” หรือ “ผู้จัดจำหน่ายหลัก” อนุญาตให้ “ตัวแทนจำหน่าย” นำไปจัดจำหน่ายแก่ “ผู้ใช้ปลายทาง” เพื่อเข้าใช้ “ผลิตภัณฑ์” ตามข้อกำหนดและเงื่อนไขที่กำหนดไว้ในข้อตกลงสิทธิ์การใช้งานสำหรับ “ผู้ใช้ปลายทาง” (EULA)","1.5 “การลงทะเบียนสิทธิ์ในข้อตกลงทางการค้า” (Deal Registration) หมายถึง กระบวนการที่ “ตัวแทนจำหน่าย” แจ้งข้อมูลรายละเอียดของ “ผู้ใช้ปลายทาง” ขอบเขตงาน หรือโอกาสทางการค้า ผ่านระบบหรือช่องทางที่ “ผู้จัดจำหน่ายหลัก” กำหนดไว้ เพื่อขอรับสิทธิ์ในการเสนอขายและสิทธิประโยชน์อื่นใดตามเงื่อนไขของสัญญานั้น ๆ"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_partner_sec_2","type":"contract_section","title":"ข้อ 2. ขอบเขตการแต่งตั้งและอาณาเขต (Scope of Appointment & Territory)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["2.1 การแต่งตั้งและบทบาทของ “ผู้จัดจำหน่ายหลัก”: “ผู้จัดจำหน่ายหลัก” ในฐานะผู้ได้รับสิทธิ์อย่างถูกต้องจาก “เจ้าของผลิตภัณฑ์” แต่งตั้งตัวแทนจำหน่ายให้เป็น “ตัวแทนจำหน่าย” ประเภทแบบไม่ผูกขาด (Non-exclusive) โดย “ผู้จัดจำหน่ายหลัก” มีหน้าที่ในการจัดหา จัดส่ง และประสานงานเรื่องการออก “สิทธิ์การใช้งาน” ของ “ผลิตภัณฑ์” ให้แก่ “ตัวแทนจำหน่าย” เพื่อนำไปจำหน่ายให้แก่ “ผู้ใช้ปลายทาง”","2.2 สิทธิ์การจำหน่ายของ “ตัวแทนจำหน่าย”: “ตัวแทนจำหน่าย” สามารถจัดจำหน่าย “สิทธิ์การใช้งาน” ของ “ผลิตภัณฑ์” ให้กับ “ผู้ใช้ปลายทาง” เท่านั้น ไม่สามารถโอนสิทธิ์การใช้งาน หรือแสดงความเป็นเจ้าของในตัว “ผลิตภัณฑ์”","2.3 อาณาเขตทางภูมิศาสตร์ (Territory): “ตัวแทนจำหน่าย” มีสิทธิดำเนินกิจกรรมการขาย การส่งเสริมการขาย และทำตลาด “ผลิตภัณฑ์” ได้ภายในพื้นที่ ประเทศไทย เท่านั้น"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_partner_sec_3","type":"contract_section","title":"ข้อ 3. สิทธิ หน้าที่ และความรับผิดชอบของคู่สัญญา (Obligations of the Parties)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":null,"distributorObligations":["การสนับสนุนด้านการขายและสื่อการตลาด: “ผู้จัดจำหน่ายหลัก” มีหน้าที่จัดหาเอกสาร ข้อมูลทางเทคนิค คู่มือการใช้งาน สื่อส่งเสริมการขาย และรายละเอียดราคาที่เป็นปัจจุบันให้แก่ “ตัวแทนจำหน่าย”","การอบรมบุคลากร (Training): “ผู้จัดจำหน่ายหลัก” ตกลงจะจัดให้มีการอบรมด้านผลิตภัณฑ์ (Product Training) และการใช้งานเบื้องต้นให้แก่ทีมงานของ “ตัวแทนจำหน่าย” ตามรอบเวลาที่ตกลงกัน","การประสานงานกับ “เจ้าของผลิตภัณฑ์”: “ผู้จัดจำหน่ายหลัก” จะทำหน้าที่เป็นตัวกลางในการประสานงาน แก้ไขปัญหา และติดตามข้อเรียกร้องต่าง ๆ ระหว่าง “ตัวแทนจำหน่าย” หรือ “ผู้ใช้ปลายทาง” กับ “เจ้าของผลิตภัณฑ์”","การไม่แข่งขันทางธุรกิจและการไม่ใช้ข้อมูลในทางที่ไม่เหมาะสม (Non-competition & Data Misuse): “ผู้จัดจำหน่ายหลัก” ตกลงจะไม่ดำเนินกิจกรรมทางธุรกิจ การส่งเสริมการขาย หรือติดต่อเสนอขาย “ผลิตภัณฑ์” โดยตรงแก่ “ผู้ใช้ปลายทาง” ของ “ตัวแทนจำหน่าย” ในลักษณะที่เป็นการแข่งขันทางธุรกิจกับ “ตัวแทนจำหน่าย” ในอาณาเขตที่กำหนด และจะไม่นำข้อมูลรายชื่อ “ผู้ใช้ปลายทาง” ข้อมูลการเสนอราคา หรือข้อมูลทางการค้าใด ๆ ที่ได้รับจาก “ตัวแทนจำหน่าย” ไปใช้ประโยชน์เพื่อตนเอง หรือบุคคลภายนอก หรือนำไปใช้ในลักษณะที่ส่งผลกระทบ ก่อให้เกิดความเสียหาย หรือทำให้ “ตัวแทนจำหน่าย” เสียประโยชน์ทางธุรกิจ ไม่ว่าโดยทางตรง หรือทางอ้อม"],"resellerObligations":["การทำตลาดและการรักษามาตรฐาน: “ตัวแทนจำหน่าย” ต้องทำการตลาด ถ่ายทอดข้อมูลอย่างถูกต้อง ปฏิบัติตามจรรยาบรรณทางธุรกิจ และรักษาสภาพแวดล้อมทางธุรกิจเพื่อส่งเสริมภาพลักษณ์ของ “ผลิตภัณฑ์” และ “ผู้จัดจำหน่ายหลัก”","การปฏิเสธการทำตลาดทับซ้อน (Non-poaching / Territory Limit): “ตัวแทนจำหน่าย” ต้องไม่แสวงหา “ผู้ใช้ปลายทาง” ส่งเสริมการขาย หรือเสนอขาย “ผลิตภัณฑ์” นอกอาณาเขตหรือกลุ่ม “ผู้ใช้ปลายทาง” ที่ได้รับการสงวนสิทธิ์ไว้ให้แก่คู่ค้ารายอื่นโดยชัดแจ้ง เว้นแต่ได้รับความยินยอมเป็นลายลักษณ์อักษรจาก “ผู้จัดจำหน่ายหลัก”"],"closing":null}},{"id":"b_partner_sec_4","type":"contract_section","title":"ข้อ 4. ลิขสิทธิ์ซอฟต์แวร์ รูปแบบการใช้งาน และการปฏิบัติตามกฎหมาย (Software Licensing & Compliance)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["4.1 การรับประกันสิทธิโดย “ผู้จัดจำหน่ายหลัก”: “ผู้จัดจำหน่ายหลัก” รับประกันว่าตนมีสิทธิทางกฎหมายอย่างถูกต้องในการนำเสนอ และจัดจำหน่าย “สิทธิการใช้งาน” ของ “ผลิตภัณฑ์” ดังกล่าวให้แก่ “ตัวแทนจำหน่าย”","4.2 ข้อตกลงกับ “ผู้ใช้ปลายทาง”: “ตัวแทนจำหน่าย” มีหน้าที่ต้องแจ้ง ส่งมอบ และดูแลให้ “ผู้ใช้ปลายทาง” ยินยอมปฏิบัติตามข้อตกลงสิทธิการใช้งานสำหรับ “ผู้ใช้ปลายทาง” (End User License Agreement: EULA) ของ “เจ้าของผลิตภัณฑ์” ทุกครั้งก่อนเริ่มใช้งาน","4.3 การต่อต้านการละเมิดลิขสิทธิ์ (Anti-Piracy & Compliance): “ตัวแทนจำหน่าย” ตกลงจะไม่ทำการคัดลอก ดัดแปลง ทำวิศวกรรมย้อนกลับ (Reverse Engineering) หรือสนับสนุนให้เกิดการละเมิดลิขสิทธิ์ซอฟต์แวร์ และต้องให้ความร่วมมือในการตรวจสอบการใช้งานของ “ผู้ใช้ปลายทาง” เมื่อได้รับการร้องขอ"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_partner_sec_5","type":"contract_section","title":"ข้อ 5. การกำหนดราคา ส่วนลด และเงื่อนไขการชำระเงิน (Pricing, Discounts, and Payment Terms)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["5.1 โครงสร้างราคา: “ผู้จัดจำหน่ายหลัก” จะกำหนด และจัดส่งราคาต้นทุน (Cost Price) สำหรับ “ตัวแทนจำหน่าย” และระบุราคาแนะนำสำหรับ “ผู้ใช้ปลายทาง” (End User Price)","5.2 ส่วนลดพิเศษ (Special Discounts): การอนุมัติส่วนลดพิเศษให้อยู่ในวิจารณญาณของ “ผู้จัดจำหน่ายหลัก” โดย “ผู้จัดจำหน่ายหลัก” จะแจ้งยืนยันเป็นลายลักษณ์อักษร (หรือผ่านระบบอิเล็กทรอนิกส์) พร้อมกำหนดระยะเวลาความคุ้มครองของราคานั้น ๆ (Price Validity Period)","5.3 เงื่อนไขการส่งใบแจ้งหนี้ กำหนดระยะเวลาชำระเงิน (Credit Term) และการชำระเงิน: “ผู้จัดจำหน่ายหลัก” จะออกใบแจ้งหนี้เมื่อได้รับใบสั่งซื้อ (Purchase Order) และดำเนินการออก “สิทธิการใช้งาน” เรียบร้อยแล้ว โดยกำหนดระยะเวลาชำระเงิน (Credit Term) ภายใน 30 (สามสิบ) วัน นับแต่วันที่ออกใบแจ้งหนี้ให้กับ “ตัวแทนจำหน่าย” หากชำระล่าช้าต้องเสียดอกเบี้ยร้อยละ 1.5 ต่อเดือน สกุลเงินที่ใช้คือ บาทไทย","5.4 เงื่อนไขอัตราแลกเปลี่ยน (Exchange Rate Condition): การคำนวณราคาเป็นสกุลเงินบาทไทยจะอ้างอิงอัตราแลกเปลี่ยน ณ วันที่ออกใบเสนอราคา โดยตรึงไว้ 30 วัน"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_partner_sec_6","type":"contract_section","title":"ข้อ 6. การบริการหลังการขายและการสนับสนุนทางเทคนิค (Technical Support and Maintenance & SLA)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["6.1 ระดับการบริการขั้นแรกของ Reseller (Tier 1 Support): แบ่งตามความพร้อมของตัวแทนจำหน่าย (กรณีมีทีมงาน Tier 1 หรือกรณีส่งต่อ Pass-through ให้ผู้จัดจำหน่ายหลัก)","6.2 ระดับการบริการของ “ผู้จัดจำหน่ายหลัก” และการส่งต่อปัญหา (Tier 2/3 Escalation Path & SLA): อ้างอิง Back-to-Back SLA ของเจ้าของผลิตภัณฑ์","6.3 การต่ออายุสัญญาบริการ (Renewals): “ผู้จัดจำหน่ายหลัก” มีหน้าที่แจ้งเตือนรอบการต่ออายุ “สิทธิการใช้งาน” รายปีล่วงหน้าแก่ “ตัวแทนจำหน่าย” ไม่น้อยกว่า 60 วัน ก่อนวันหมดอายุ"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_partner_sec_7","type":"contract_section","title":"ข้อ 7. การจัดการทรัพย์สินทางปัญญาและการจำกัดความรับผิด (Intellectual Property & Limitation of Liability)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["7.1 การชดใช้ค่าเสียหายจากข้อพิพาทลิขสิทธิ์ (Indemnification): “ผู้จัดจำหน่ายหลัก” รับประกันว่า “ผลิตภัณฑ์” ไม่มีการละเมิดทรัพย์สินทางปัญญาของบุคคลภายนอก","7.2 การจำกัดความรับผิด (Limitation of Liability): ความรับผิดชอบสูงสุดทางการเงินจำกัดไว้ไม่เกินยอดเงินรวมที่ชำระให้แก่ผู้จัดจำหน่ายหลักที่ผ่านมาก่อนเกิดเหตุ"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_partner_sec_8","type":"contract_section","title":"ข้อ 8. การรับประกัน (Warranty)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["8.1 การรับประกันการทำงานของซอฟต์แวร์: รับประกันว่าทำงานตรงตามคุณลักษณะทางเทคนิคที่ระบุในคู่มือ","8.2 ข้อยกเว้นการรับประกัน: ไม่ครอบคลุมความเสียหายจากการดัดแปลงโดยไม่ได้รับอนุญาต"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_partner_sec_9","type":"contract_section","title":"ข้อ 9. การรักษาความลับข้อมูลและการคุ้มครองข้อมูลส่วนบุคคล (Confidentiality & Data Protection)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["9.1 การรักษาความลับทางธุรกิจและการใช้ข้อมูล: รักษาความลับตลอดอายุสัญญาและต่อเนื่อง 2 ปีหลังสิ้นสุดสัญญา","9.2 การคุ้มครองข้อมูลส่วนบุคคล (PDPA): ปฏิบัติตามกฎหมายคุ้มครองข้อมูลส่วนบุคคลอย่างเคร่งครัด"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_partner_sec_10","type":"contract_section","title":"ข้อ 10. ระยะเวลาและการบอกเลิกสัญญา (Term and Termination)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["10.1 ระยะเวลาสัญญา: 1 ปี นับแต่วันที่ลงนาม และต่ออายุอัตโนมัติคราวละ 1 ปี","10.2 การบอกเลิกสัญญาแบบมีเหตุผล: บอกเลิกได้ทันทีหากผิดสัญญาและไม่แก้ไขใน 30 วัน หรือล้มละลาย","10.3 การบอกเลิกสัญญาโดยไม่มีเหตุผล: แจ้งล่วงหน้าเป็นลายลักษณ์อักษรไม่น้อยกว่า 60 วัน","10.4 ภาระผูกพันหลังสิ้นสุดสัญญา: ยังคงต้องชำระค่าบริการที่ค้างชำระทั้งหมด และดูแลสิทธิการใช้งานที่มีผลอยู่"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_partner_sec_11","type":"contract_section","title":"ข้อ 11. กฎหมายที่ใช้บังคับและกระบวนการระงับข้อพิพาท (Governing Law & Dispute Resolution)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["11.1 กฎหมายที่ใช้บังคับ: อยู่ภายใต้กฎหมายแห่งราชอาณาจักรไทย","11.2 กระบวนการระงับข้อพิพาท: เจรจาด้วยมิตรภาพภายใน 30 วัน หากไม่ยุติให้ส่งเรื่องสู่ศาลไทย"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_partner_witness","type":"text_block","title":"พยานหลักฐาน","settings":{"content":"สัญญานี้ทำขึ้นเป็นสองฉบับมีข้อความถูกต้องตรงกัน คู่สัญญาได้อ่านและเข้าใจข้อความโดยรายละเอียดตลอดแล้ว จึงได้ลงลายมือชื่อและประทับตรา (ถ้ามี) ไว้เป็นสำคัญต่อหน้าพยาน"}},{"id":"b_partner_signatures","type":"signatures","title":"ลงนามแต่งตั้ง","settings":{"slots":[{"id":"s1","name":"{{authorized_signatory_name}}","role":"ผู้จัดจำหน่ายหลัก (Distributor)"},{"id":"s2","name":"{{customer_signatory_name}}","role":"ตัวแทนจำหน่าย (Reseller)"}]}}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES ('tmpl-distributor-standard-v1', 'tmpl-distributor-standard', 1, 'สัญญาแต่งตั้งและจัดจำหน่ายซอฟต์แวร์', 'โครงสร้างสัญญาแต่งตั้งตัวแทนจำหน่ายและจัดจำหน่ายซอฟต์แวร์', 'distributor', '[{"id":"b_dist_header","type":"header","title":"หัวกระดาษ","settings":{"hasLogo":true,"logoUrl":"/preview.webp","companyName":"{{company_name}}","companyNameEn":"{{company_name_en}}","taxId":"{{company_tax_id}}","address":"{{company_address}}","phone":"{{company_phone}}","email":"{{company_email}}","align":"split"}},{"id":"b_dist_title","type":"doc_title","title":"หัวเรื่อง","settings":{"titleText":"สัญญาแต่งตั้งและจัดจำหน่ายซอฟต์แวร์","subtitleText":"(Distributor and Reseller Master Agreement)","align":"center"}},{"id":"b_dist_preamble","type":"contract_preamble","title":"คำนำสัญญาและคู่สัญญา","settings":{"locationPrefix":"สัญญาฉบับนี้ทำขึ้น ณ","locationText":"{{contract_location}}","datePrefix":"เมื่อวันที่","dateText":"{{contract_date}}","betweenLabel":"ระหว่าง:","party1Text":"{{company_name}} {{company_address}} ซึ่งต่อไปในสัญญานี้จะเรียกว่า “ผู้จัดจำหน่ายหลัก” (Distributor) ฝ่ายหนึ่ง","andLabel":"กับ","party2Text":"{{customer_company}} สำนักงานใหญ่ ตั้งอยู่เลขที่ {{customer_address}} (ซึ่งต่อไปในสัญญานี้จะเรียกว่า “Reseller” หรือ “ตัวแทนจำหน่ายต่อ”) อีกฝ่ายหนึ่ง","recital":"คู่สัญญาทั้งสองฝ่ายตกลงเข้าทำสัญญาแต่งตั้งตัวแทนจำหน่ายต่อ เพื่อทำการตลาด นำเสนอ และจัดจำหน่ายผลิตภัณฑ์ซอฟต์แวร์ และเครื่องมือทางไอที (ซึ่งต่อไปนี้เรียกว่า “ผลิตภัณฑ์”) โดยมีข้อกำหนดและเงื่อนไขดังต่อไปนี้:"}},{"id":"b_dist_sec_1","type":"contract_section","title":"1. นิยามศัพท์ (Definitions)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["1.1. “เจ้าของผลิตภัณฑ์” (Vendor) หมายถึง บุคคล นิติบุคคล หรือผู้พัฒนาซอฟต์แวร์ ซึ่งเป็นผู้ถือครองลิขสิทธิ์ ทรัพย์สินทางปัญญา และสิทธิ์โดยชอบด้วยกฎหมายในตัวผลิตภัณฑ์ซอฟต์แวร์แต่เพียงผู้เดียว (หรือตามสิทธิ์ที่ได้รับอนุญาต)","1.2. “ผู้ใช้ปลายทาง” (End User) หมายถึง บุคคล นิติบุคคล หรือองค์กรที่เป็นผู้ซื้อ ได้รับสิทธิ์ หรือจัดหาผลิตภัณฑ์ซอฟต์แวร์ไปเพื่อวัตถุประสงค์ในการใช้งานจริงภายในองค์กรของตนเอง ไม่ใช่เพื่อวัตถุประสงค์ในการนำไปจำหน่ายต่อหรือให้เช่าช่วง","1.3. “ผลิตภัณฑ์” (Product) หมายถึง ซอฟต์แวร์ ระบบปฏิบัติการ หรือเครื่องมือทางไอที รวมถึง “สิทธิ์การใช้งาน” เอกสารคู่มือ การอัปเดต และแพตช์แก้ไขความปลอดภัย ซึ่ง “ผู้จัดจำหน่ายหลัก” ได้รับสิทธิ์จัดจำหน่ายจาก “เจ้าของผลิตภัณฑ์”","1.4. “สิทธิ์การใช้งาน” (License/Subscription) หมายถึง สิทธิ์ทางกฎหมายที่ “เจ้าของผลิตภัณฑ์” หรือ “ผู้จัดจำหน่ายหลัก” อนุญาตให้ “ตัวแทนจำหน่ายต่อ” นำไปจัดจำหน่ายแก่ “ผู้ใช้ปลายทาง” เพื่อเข้าใช้ “ผลิตภัณฑ์” ตามข้อกำหนดและเงื่อนไขที่กำหนดไว้ในข้อตกลงสิทธิ์การใช้งานสำหรับ “ผู้ใช้ปลายทาง” (EULA)"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_dist_sec_2","type":"contract_section","title":"2. ขอบเขตการแต่งตั้งและอาณาเขต (Scope of Appointment & Territory)","settings":{"intro":null,"content":null,"bullets":null,"subClauses":["2.1. การแต่งตั้งและบทบาทของ “ผู้จัดจำหน่ายหลัก”: “ผู้จัดจำหน่ายหลัก” แต่งตั้งตัวแทนจำหน่ายต่อให้เป็น “ตัวแทนจำหน่ายต่อ” ประเภทแบบไม่ผูกขาด (Non-exclusive)","2.2. สิทธิ์การจำหน่ายของ “ตัวแทนจำหน่ายต่อ”: สามารถจัดจำหน่าย “สิทธิ์การใช้งาน” ของ “ผลิตภัณฑ์” ให้กับ “ผู้ใช้ปลายทาง” เท่านั้น","2.3. อาณาเขตทางภูมิศาสตร์ (Territory): มีสิทธิ์ดำเนินกิจกรรมการขาย การส่งเสริมการขาย และทำการตลาด “ผลิตภัณฑ์” ได้ภายในพื้นที่ ประเทศไทย เท่านั้น"],"distributorObligations":null,"resellerObligations":null,"closing":null}},{"id":"b_dist_witness","type":"text_block","title":"พยานหลักฐาน","settings":{"content":"เพื่อเป็นหลักฐานแห่งการนี้ คู่สัญญาโดยผู้มีอำนาจลงนามได้อ่านและเข้าใจข้อความในสัญญานี้โดยละเอียดตลอดแล้ว เห็นว่าถูกต้องตรงตามเจตนา จึงได้ลงลายมือชื่อและประทับตราสำคัญ (ถ้ามี) ไว้เป็นสำคัญต่อหน้าพยาน"}},{"id":"b_dist_signatures","type":"signatures","title":"ลงนามคู่สัญญา","settings":{"slots":[{"id":"s1","name":"{{authorized_signatory_name}}","role":"ผู้จัดจำหน่ายหลัก (Distributor)"},{"id":"s2","name":"{{customer_signatory_name}}","role":"ตัวแทนจำหน่ายต่อ (Reseller)"}]}}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks)
VALUES ('tmpl-notification-standard-v1', 'tmpl-notification-standard', 1, 'หนังสือแจ้งเปลี่ยนแปลงที่ตั้งสำนักงานใหญ่', 'หนังสือแจ้งการเปลี่ยนแปลงที่อยู่และสถานที่ตั้งสำนักงานใหญ่ทางการ (ไทย-อังกฤษ)', 'notification', '[{"id":"b_header","type":"header","title":"หัวกระดาษ","settings":{"hasLogo":true,"logoUrl":"/quotation.png","companyName":"บริษัท เครสท์ เซนโด จำกัด","companyNameEn":"CREST ZENDO CO., LTD.","taxId":"0105558073755","address":"8/40 The Connect 37, ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210","phone":"02-123-4567","email":"contact@crestzendo.com","align":"split"}},{"id":"b_title","type":"doc_title","title":"หัวเรื่อง","settings":{"titleText":"หนังสือแจ้งเปลี่ยนแปลงที่ตั้งสำนักงานใหญ่","subtitleText":"NOTICE OF HEAD OFFICE RELOCATION","align":"center"}},{"id":"b_info","type":"info_grid","title":"ข้อมูลหนังสือ","settings":{"billToTitle":"เรียน:","billToCompany":"ท่านคู่ค้า ลูกค้า และพันธมิตรทางธุรกิจทุกท่าน","attnName":"ผู้มีอุปการคุณทุกท่าน","subject":"แจ้งเปลี่ยนแปลงสถานที่ตั้งสำนักงานใหญ่แห่งใหม่","quotationNo":"TRAC-2609001","date":"01 กันยายน 2569","validity":"มีผล 16 กันยายน 2569","amName":"ฝ่ายบริหารจัดการทั่วไป"}},{"id":"b_text","type":"text_block","title":"ข้อความหนังสือแจ้ง","settings":{"content":"บริษัท เครสท์ เซนโด จำกัด ขอเรียนแจ้งให้ท่านทราบว่า บริษัทฯ ได้ดำเนินการย้ายสถานที่ตั้งสำนักงานใหญ่แห่งใหม่ เพื่อรองรับการขยายตัวทางธุรกิจและการให้บริการที่มีประสิทธิภาพยิ่งขึ้น โดยมีผลบังคับใช้ตั้งแต่วันที่ 16 กันยายน 2569 เป็นต้นไป"}},{"id":"b_terms","type":"terms","title":"เปรียบเทียบที่อยู่เดิมและใหม่","settings":{"heading":"รายละเอียดสถานที่ตั้งสำนักงานใหญ่:","bullets":["ที่อยู่เดิม: 45 ซอยโกสุมรวมใจ 37 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210","ที่อยู่ใหม่ (มีผล 16 ก.ย. 2569): 8/40 The Connect 37, ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210","หมายเลขโทรศัพท์และช่องทางการติดต่อทางอิเล็กทรอนิกส์ยังคงใช้งานได้ตามปกติ"]}},{"id":"b_signatures","type":"signatures","title":"ผู้มีอำนาจลงนาม","settings":{"slots":[{"id":"s1","name":"นายศรายุทธ โกสิยารักษ์","role":"กรรมการผู้จัดการ / CEO"}]}}]'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_header', 'tv-tmpl-quotation-standard-v1', 'header', 'หัวกระดาษบริษัท', 0, '{"hasLogo":true,"logoUrl":"/quotation.png","companyName":"[ ชื่อบริษัท / ผู้เสนอราคา ]","companyNameEn":"[ Company Name (EN) ]","taxId":"0-0000-00000-00-0","address":"[ ที่อยู่สำนักงานใหญ่ / สถานประกอบการ ]","phone":"02-XXX-XXXX","email":"contact@company.com","align":"split"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_title', 'tv-tmpl-quotation-standard-v1', 'doc_title', 'หัวเรื่องเอกสาร', 1, '{"titleText":"ใบเสนอราคา (QUOTATION)","subtitleText":"ต้นฉบับ / Original","align":"center"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_info', 'tv-tmpl-quotation-standard-v1', 'info_grid', 'ข้อมูลลูกค้าและเอกสาร', 2, '{"billToTitle":"Bill To:","billToCompany":"[ ชื่อบริษัทลูกค้า / ผู้รับบริการ ]","attnName":"[ ชื่อผู้ติดต่อ ]","subject":"[ ระบุเรื่อง / โครงการ ]","quotationNo":"QT-YYYYMM-XXXX","date":"[ ว/ด/ป ที่ออกเอกสาร ]","validity":"30 วัน","amName":"[ ชื่อผู้จัดทำ / Account Manager ]"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_table', 'tv-tmpl-quotation-standard-v1', 'quotation_table', 'ตารางรายการสินค้า/บริการ', 3, '{"vatRate":7,"items":[]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_terms', 'tv-tmpl-quotation-standard-v1', 'terms', 'เงื่อนไขและข้อกำหนด', 4, '{"heading":"เงื่อนไขการชำระเงินและส่งมอบ:","bullets":["ราคานี้ยังไม่รวมภาษีมูลค่าเพิ่ม (VAT 7%)","กำหนดยืนราคา 30 วันนับจากวันที่ในเอกสาร","เงื่อนไขการชำระเงิน: ภายใน 30 วันนับจากวันส่งมอบงาน"]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_signatures', 'tv-tmpl-quotation-standard-v1', 'signatures', 'ส่วนลงนามอนุมัติ', 5, '{"slots":[{"id":"s1","name":"[ ผู้มีอำนาจลงนาม / ผู้เสนอราคา ]","role":"ผู้เสนอราคา"},{"id":"s2","name":"............................................","role":"ผู้อนุมัติสั่งซื้อ / ลูกค้า"}]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_text', 'tv-tmpl-nda-standard-v1', 'text_block', 'โครงสร้างข้อสัญญา', 2, '{"content":"สัญญาฉบับนี้ทำขึ้นระหว่าง [ ชื่อคู่สัญญาฝ่ายเปิดเผยข้อมูล ] และ [ ชื่อคู่สัญญาฝ่ายรับข้อมูล ] โดยทั้งสองฝ่ายตกลงรักษาความลับของข้อมูลตามขอบเขตและระยะเวลาที่ระบุในสัญญานี้"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-quotation-standard-v1-b_header', 'tmpl-quotation-standard-v1', 'header', 'หัวกระดาษบริษัท', 1, '{"hasLogo":true,"logoUrl":"/quotation.png","companyName":"[ ชื่อบริษัท / ผู้เสนอราคา ]","companyNameEn":"[ Company Name (EN) ]","taxId":"0-0000-00000-00-0","address":"[ ที่อยู่สำนักงานใหญ่ / สถานประกอบการ ]","phone":"02-XXX-XXXX","email":"contact@company.com","align":"split"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-quotation-standard-v1-b_title', 'tmpl-quotation-standard-v1', 'doc_title', 'หัวเรื่องเอกสาร', 2, '{"titleText":"ใบเสนอราคา (QUOTATION)","subtitleText":"ต้นฉบับ / Original","align":"center"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-quotation-standard-v1-b_info', 'tmpl-quotation-standard-v1', 'info_grid', 'ข้อมูลลูกค้าและเอกสาร', 3, '{"billToTitle":"Bill To:","billToCompany":"[ ชื่อบริษัทลูกค้า / ผู้รับบริการ ]","attnName":"[ ชื่อผู้ติดต่อ ]","subject":"[ ระบุเรื่อง / โครงการ ]","quotationNo":"QT-YYYYMM-XXXX","date":"[ ว/ด/ป ที่ออกเอกสาร ]","validity":"30 วัน","amName":"[ ชื่อผู้จัดทำ / Account Manager ]"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-quotation-standard-v1-b_table', 'tmpl-quotation-standard-v1', 'quotation_table', 'ตารางรายการสินค้า/บริการ', 4, '{"vatRate":7,"items":[]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-quotation-standard-v1-b_terms', 'tmpl-quotation-standard-v1', 'terms', 'เงื่อนไขและข้อกำหนด', 5, '{"heading":"เงื่อนไขการชำระเงินและส่งมอบ:","bullets":["ราคานี้ยังไม่รวมภาษีมูลค่าเพิ่ม (VAT 7%)","กำหนดยืนราคา 30 วันนับจากวันที่ในเอกสาร","เงื่อนไขการชำระเงิน: ภายใน 30 วันนับจากวันส่งมอบงาน"]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-quotation-standard-v1-b_signatures', 'tmpl-quotation-standard-v1', 'signatures', 'ส่วนลงนามอนุมัติ', 6, '{"slots":[{"id":"s1","name":"[ ผู้มีอำนาจลงนาม / ผู้เสนอราคา ]","role":"ผู้เสนอราคา"},{"id":"s2","name":"............................................","role":"ผู้อนุมัติสั่งซื้อ / ลูกค้า"}]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_header', 'tmpl-nda-standard-v1', 'header', 'หัวกระดาษ', 1, '{"hasLogo":true,"logoUrl":"/preview.webp","companyName":"{{company_name}}","companyNameEn":"{{company_name_en}}","taxId":"{{company_tax_id}}","address":"{{company_address}}","phone":"{{company_phone}}","email":"{{company_email}}","align":"split"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_title', 'tmpl-nda-standard-v1', 'doc_title', 'หัวเรื่อง', 2, '{"titleText":"หนังสือสัญญาไม่เปิดเผยข้อมูล","subtitleText":"(NON-DISCLOSURE AGREEMENT - NDA)","align":"center"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_preamble', 'tmpl-nda-standard-v1', 'contract_preamble', 'คำนำสัญญาและคู่สัญญา', 3, '{"locationPrefix":"สัญญาฉบับนี้ทำขึ้น ณ","locationText":"{{contract_location}}","datePrefix":"เมื่อวันที่","dateText":"{{contract_date}}","betweenLabel":"ระหว่าง:","party1Text":"{{company_name}} สำนักงานใหญ่ ตั้งอยู่เลขที่ 8/40 เดอะ คอนเนค 37 ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210 ประเทศไทย ซึ่งต่อไปในสัญญานี้จะเรียกว่า “ผู้เปิดเผยข้อมูล” (Disclosing Party) ฝ่ายหนึ่ง","andLabel":"และ","party2Text":"{{customer_company}} สำนักงานใหญ่ ตั้งอยู่เลขที่ {{customer_address}} ซึ่งต่อไปในสัญญานี้จะเรียกว่า “ผู้รับข้อมูล” (Receiving Party) อีกฝ่ายหนึ่ง","partiesSummary":"(รวมเรียกว่า “คู่สัญญาทั้งสองฝ่าย” หรือเรียกว่า “ฝ่าย” หากหมายถึงฝ่ายใดฝ่ายหนึ่ง)","recital":"โดยที่ ผู้เปิดเผยข้อมูล เป็นผู้ประกอบธุรกิจจัดจำหน่ายและให้บริการด้านซอฟต์แวร์ ไอทีโซลูชัน และเทคโนโลยีดิจิทัล และมีความประสงค์จะเปิดเผยข้อมูลที่มีลักษณะเป็นความลับของตนให้แก่ ผู้รับข้อมูล เพื่อวัตถุประสงค์ในการประเมิน ความร่วมมือ หรือการทำธุรกิจร่วมกัน และผู้รับข้อมูลตกลงที่จะรับและรักษาข้อมูลความลับดังกล่าวตามข้อกำหนดและเงื่อนไขในสัญญานี้ คู่สัญญาจึงตกลงทำสัญญามีข้อความดังต่อไปนี้:"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_sec_1', 'tmpl-nda-standard-v1', 'contract_section', '1. คำนิยามข้อมูลที่เป็นความลับ (Definition of Confidential Information)', 4, '{"intro":"1.1. “ข้อมูลที่เป็นความลับ” (Confidential Information) หมายถึง ข้อมูล เอกสาร สารสนเทศ เทคโนโลยี และความรู้ความชำนาญ (Know-how) ทั้งหมด ไม่ว่าจะอยู่ในรูปแบบใด (ลายลักษณ์อักษร, วาจา, อิเล็กทรอนิกส์, รหัสคอมพิวเตอร์, หรือสื่อบันทึกข้อมูลอื่นใด) ที่ผู้เปิดเผยข้อมูลส่งมอบ เปิดเผย หรือให้เข้าถึงแก่ผู้รับข้อมูล ทั้งก่อนและหลังวันทำสัญญาฉบับนี้ ซึ่งรวมถึงแต่ไม่จำกัดเพียง:","content":null,"bullets":["ข้อมูลด้านเทคนิคและซอฟต์แวร์: ซอร์ซโค้ด (Source Code), ออบเจกต์โค้ด (Object Code), อัลกอริทึม (Algorithms), สถาปัตยกรรมระบบ (System Architecture), โครงสร้างฐานข้อมูล, เอกสาร API, คู่มือเทคนิค, ผลการทดสอบ, บัก (Bugs), Credential, Log, API Token, User Experience (UX), User Interface (UI), Credential ต่างๆ, Knowledge Base และข้อผิดพลาดของระบบ","ข้อมูลทางการค้าและธุรกิจ: ข้อมูลราคาต้นทุน (Cost Structure), โครงสร้างส่วนลด (Discount Schemes), อัตราค่าคอมมิชชั่น, บันทึกการประชุม, แผนกลยุทธ์การตลาด, แผนการขาย, รายชื่อและข้อมูลลูกค้าปลายทาง (End-customers), รายชื่อผู้จัดจำหน่าย และประมาณการทางการเงิน","ข้อมูลส่วนบุคคล (Personal Data): ข้อมูลส่วนบุคคลของพนักงาน ลูกค้า หรือผู้ใช้งานระบบตามกฎหมายว่าด้วยการคุ้มครองข้อมูลส่วนบุคคล (PDPA) ที่ผู้รับข้อมูลเข้าถึงได้ระหว่างการทำระบบ การทดสอบ (PoC) หรือการสนับสนุนทางเทคนิค (Technical Support)","ความคิดสร้างสรรค์และทรัพย์สินทางปัญญา: แบบระเบียบ ขั้นตอนการทำงาน ต้นแบบ (Prototypes) สิทธิบัตร เครื่องหมายการค้า หรือความลับทางการค้าที่ยังไม่ได้เปิดเผยต่อสาธารณะ"],"subClauses":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_sec_2', 'tmpl-nda-standard-v1', 'contract_section', '2. ข้อยกเว้นข้อมูลที่เป็นความลับ (Exclusions from Confidential Information)', 5, '{"intro":"ข้อมูลความลับตามข้อ 1 ให้ไม่รวมถึงข้อมูลใดๆ ที่ผู้รับข้อมูลสามารถพิสูจน์ได้ด้วยหลักฐานเป็นลายลักษณ์อักษรว่า:","content":null,"bullets":null,"subClauses":["2.1. เป็นข้อมูลที่ตกเป็นของสาธารณะหรือเปิดเผยทั่วไปอยู่แล้วก่อน หรือในเวลาที่เปิดเผย โดยไม่ได้เกิดจากการกระทำผิดสัญญาหรือการละเมิดของผู้รับข้อมูล หรือบุคคลในสังกัด","2.2. เป็นข้อมูลที่ผู้รับข้อมูลมีอยู่แล้วโดยชอบด้วยกฎหมายก่อนที่จะได้รับจากผู้เปิดเผยข้อมูล โดยไม่มีข้อผูกมัดเรื่องการรักษาความลับใดๆ","2.3. เป็นข้อมูลที่ผู้รับข้อมูลได้รับมาจากบุคคลที่สามโดยชอบธรรม โดยบุคคลที่สามดังกล่าวมีสิทธิ์เปิดเผยได้และไม่มีข้อผูกมัดเรื่องการรักษาความลับกับผู้เปิดเผยข้อมูล","2.4. เป็นข้อมูลที่ผู้รับข้อมูลพัฒนาขึ้นมาเองโดยอิสระ (Independently Developed) โดยไม่ได้อ้างอิงหรือใช้ข้อมูลความลับของผู้เปิดเผยข้อมูลเลย","2.5. ข้อมูลที่ต้องเปิดเผยตามคำสั่งศาล หน่วยงานราชการ หรือองค์กรกำกับดูแลตามกฎหมาย โดยผู้รับข้อมูลต้องแจ้งให้ผู้เปิดเผยข้อมูลทราบทันทีล่วงหน้าเป็นลายลักษณ์อักษร (หากไม่ขัดต่อกฎหมาย) เพื่อให้ผู้เปิดเผยข้อมูลมีโอกาสคัดค้านหรือร้องขอมาตรการคุ้มครอง"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_sec_3', 'tmpl-nda-standard-v1', 'contract_section', '3. วัตถุประสงค์ในการเปิดเผยข้อมูล (Purpose of Disclosure)', 6, '{"intro":"3.1. ผู้เปิดเผยข้อมูลเปิดเผยข้อมูลความลับแก่ผู้รับข้อมูล เพื่อวัตถุประสงค์เฉพาะเจาะจงดังต่อไปนี้เท่านั้น (“วัตถุประสงค์”):","content":null,"bullets":["เพื่อการประเมินความเป็นไปได้ในการเข้าทำสัญญาความร่วมมือทางธุรกิจ การเป็นพันธมิตร (Partner), ผู้จัดจำหน่าย (Distributor) หรือตัวแทนจำหน่าย (Reseller)","เพื่อการทดสอบระบบ การสาธิต หรือการทำระบบทดลองใช้ (Proof of Concept - PoC) ให้แก่คู่สัญญาหรือลูกค้าเป้าหมาย","เพื่อการบูรณาการระบบ (System Integration), การติดตั้ง, การพัฒนาต่อเติมตามคำขอ หรือการให้บริการสนับสนุนทางเทคนิค (Technical Support)","เพื่อสนับสนุนการขาย หรือการให้บริการที่เกี่ยวข้องกับข้อมูลนั้น"],"subClauses":null,"closing":"3.2. ผู้รับข้อมูลตกลงอย่างเคร่งครัดว่าจะไม่นำข้อมูลความลับไปใช้เพื่อวัตถุประสงค์อื่นใด นอกเหนือจากที่ระบุในข้อ 3.1 โดยเฉพาะอย่างยิ่ง ห้ามนำไปใช้เพื่อประโยชน์ทางการค้าของตนเองหรือบุคคลภายนอก หรือนำไปใช้ในลักษณะที่เป็นแข่งขันกับผู้เปิดเผยข้อมูล"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_sec_4', 'tmpl-nda-standard-v1', 'contract_section', '4. หน้าที่และความรับผิดชอบของผู้รับข้อมูล (Obligations of Receiving Party)', 7, '{"intro":"ผู้รับข้อมูลตกลงและรับรองที่จะปฏิบัติตามหน้าที่ดังต่อไปนี้:","content":null,"bullets":null,"subClauses":["4.1. การเก็บรักษาความลับ: ต้องระมัดระวังและรักษาข้อมูลความลับด้วยมาตรฐานความปลอดภัยที่ไม่น้อยกว่าระดับที่ตนใช้รักษาข้อมูลความลับของตนเอง และต้องไม่ต่ำกว่ามาตรฐานระมัดระวังตามวิญญูชน","4.2. ข้อจำกัดในการเข้าถึง (Need-to-Know Basis): จำกัดการเปิดเผยข้อมูลความลับเฉพาะแก่กรรมการ พนักงาน ลูกจ้าง หรือที่ปรึกษาทางกฎหมาย/การเงินของผู้รับข้อมูลที่มีความจำเป็นต้องทราบข้อมูลดังกล่าวเพื่อวัตถุประสงค์ข้างต้นเท่านั้น และบุคคลดังกล่าวต้องมีพันธะผูกพันในการรักษาความลับไม่ต่ำกว่าข้อกำหนดในสัญญานี้","4.3. มาตรการความมั่นคงปลอดภัยทางไซเบอร์: จัดให้มีมาตรการรักษาความปลอดภัยทางเทคนิคและการบริหารจัดการ (Technical and Organizational Security Measures) ที่เหมาะสม เช่น การเข้ารหัสข้อมูล (Encryption), การกำหนดสิทธิ์เข้าถึง (Access Control), การป้องกันไวรัสและมัลแวร์เพื่อป้องกันการเข้าถึง การสูญหาย หรือการรั่วไหลโดยไม่ได้รับอนุญาต","4.4. การแจ้งเหตุละเมิด: หากพบหรือสงสัยว่ามีการรั่วไหล การเข้าถึงโดยมิชอบ หรือการละเมิดข้อมูลความลับ ผู้รับข้อมูลต้องแจ้งให้ผู้เปิดเผยข้อมูลทราบทันทีภายใน 24 ชั่วโมงนับแต่พบเหตุ พร้อมทั้งร่วมมือในการระงับและแก้ไขเหตุการณ์ดังกล่าว"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_sec_5', 'tmpl-nda-standard-v1', 'contract_section', '5. ข้อจำกัดเรื่องวิศวกรรมย้อนกลับ (Strict No Reverse Engineering/Decompilation)', 8, '{"intro":null,"content":"ผู้รับข้อมูลตกลงและรับรองว่าจะไม่ทำการ (และจะไม่ยินยอมหรือมอบหมายให้บุคคลภายนอกทำการ) ถอดรหัส (Decompile), ทำวิศวกรรมย้อนกลับ (Reverse Engineer), ถอดประกอบ (Disassemble), แปลงรหัส (Translate) หรือพยายามแกะรหัสเพื่อเข้าถึงซอร์ซโค้ด (Source Code), อัลกอริทึม หรือสถาปัตยกรรมภายในของซอฟต์แวร์ ระบบ หรือเทคโนโลยีของผู้เปิดเผยข้อมูล ไม่ว่าด้วยวิธีใดๆ เว้นแต่จะได้รับความยินยอมเป็นลายลักษณ์อักษรจากผู้เปิดเผยข้อมูลก่อนเท่านั้น","bullets":null,"subClauses":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_sec_6', 'tmpl-nda-standard-v1', 'contract_section', '6. ระยะเวลาของสัญญาและการมีผลต่อเนื่อง (Term and Survival)', 9, '{"intro":null,"content":null,"bullets":null,"subClauses":["6.1. สัญญาฉบับนี้มีผลบังคับใช้นับแต่วันที่ระบุในตอนต้นของสัญญา และจะมีผลบังคับเป็นระยะเวลา 3 ปี นับจากวันทำสัญญา (“ระยะเวลาสัญญา”)","6.2. แม้ว่าสัญญานี้จะสิ้นสุดลงหรือระงับไปไม่ว่าด้วยเหตุใดก็ตาม ข้อผูกพันในการรักษาความลับตามสัญญานี้ยังคงมีผลบังคับต่อเนื่องไปอีกเป็นระยะเวลา 3 ปีนับแต่วันที่สัญญานี้สิ้นสุดลง หรือจนกว่าข้อมูลความลับนั้นจะตกเป็นของสาธารณะโดยมิใช่ความผิดของผู้รับข้อมูล (แล้วแต่วาระใดจะถึงก่อน)","6.3. สำหรับข้อมูลความลับที่เป็นความลับทางการค้า (Trade Secrets) หรือซอร์ซโค้ด (Source Code) ภาระผูกพันในการรักษาความลับจะมีผลบังคับอย่างถาวรโดยไม่มีกำหนดระยะเวลาสิ้นสุด"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_sec_7', 'tmpl-nda-standard-v1', 'contract_section', '7. การจัดการข้อมูลเมื่อสัญญาสินสุด (Return or Destruction of Information)', 10, '{"intro":"7.1. เมื่อสัญญานี้สิ้นสุดลง หรือเมื่อได้รับการร้องขอเป็นลายลักษณ์อักษรจากผู้เปิดเผยข้อมูล ผู้รับข้อมูลต้องดำเนินการทันทีภายในระยะเวลา 14 วัน ดังนี้:","content":null,"bullets":["คืนเอกสาร สื่อบันทึกข้อมูล และสำเนาข้อมูลความลับทั้งหมดให้แก่ผู้เปิดเผยข้อมูล หรือ","ทำลายข้อมูลความลับรวมถึงไฟล์อิเล็กทรอนิกส์ สำเนา สรุป หรือเอกสารดัดแปลงที่เกี่ยวข้องทั้งหมดอย่างถาวร ไม่สามารถกู้คืนได้"],"subClauses":null,"closing":"7.2. ผู้รับข้อมูลต้องจัดทำหนังสือรับรองเป็นลายลักษณ์อักษร ลงนามโดยกรรมการผู้มีอำนาจเพื่อยืนยันว่าได้ส่งคืนหรือทำลายข้อมูลความลับทั้งหมดเรียบร้อยแล้วส่งมอบให้แก่ผู้เปิดเผยข้อมูล (เว้นแต่ข้อมูลที่จำเป็นต้องจัดเก็บตามข้อกำหนดทางกฎหมาย หรือระบบสำรองข้อมูลอัตโนมัติ (Automated Backup) ซึ่งต้องได้รับการรักษาความลับตามสัญญานี้ต่อไป)"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_sec_8', 'tmpl-nda-standard-v1', 'contract_section', '8. การเยียวยาเมื่อผิดสัญญาและค่าเสียหาย (Remedies for Breach)', 11, '{"intro":null,"content":null,"bullets":null,"subClauses":["8.1. คู่สัญญาตกลงว่าการเปิดเผยหรือใช้ข้อมูลความลับโดยขัดต่อสัญญานี้ จะก่อให้เกิดความเสียหายอย่างร้ายแรงแก่ผู้เปิดเผยข้อมูล ซึ่งไม่สามารถชดเชยด้วยเยียวยาทางการเงิน หรือค่าเสียหายเพียงอย่างเดียวได้","8.2. ในกรณีที่มีการฝ่าฝืนหรือมีแนวโน้มว่าจะฝ่าฝืนสัญญานี้ ผู้เปิดเผยข้อมูลมีสิทธิร้องขอต่อศาลที่มีเขตอำนาจเพื่อให้ออกคำสั่งคุ้มครองชั่วคราว คำสั่งห้ามกระทำการ (Injunctive Relief) หรือมาตรการบรรเทาทุกข์ตามกฎหมายอื่นใด โดยไม่จำเป็นต้องพิสูจน์ความเสียหายเป็นตัวเงินจริง","8.3. สิทธิตามข้อ 8.2 ไม่ตัดสิทธิผู้เปิดเผยข้อมูลในการเรียกร้องค่าเสียหายที่เกิดขึ้นจริง (Actual Damages) ค่าขาดประโยชน์ และค่าใช้จ่ายทางกฎหมายรวมถึงค่าทนายความตามสมควรจากผู้รับข้อมูล"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_sec_9', 'tmpl-nda-standard-v1', 'contract_section', '9. กฎหมายที่ใช้บังคับและเขตอำนาจศาล (Governing Law and Jurisdiction)', 12, '{"intro":null,"content":null,"bullets":null,"subClauses":["9.1. สัญญาฉบับนี้ให้ตีความและบังคับใช้ตามกฎหมายแห่งราชอาณาจักรไทย","9.2. หากเกิดข้อพิพาท ข้อขัดแย้ง หรือการเรียกร้องใดๆ ที่เกิดขึ้นจากหรือเกี่ยวเนื่องกับสัญญานี้รวมทั้งการผิดสัญญา คู่สัญญาทั้งสองฝ่ายตกลงจะพยายามระงับข้อพิพาทโดยการเจรจาด้วยความซื่อสัตย์สุจริตก่อน หากไม่สามารถตกลงกันได้ภายใน 30 วัน ให้ส่งเรื่องให้ศาลในประเทศไทยที่มีเขตอำนาจ เป็นผู้พิจารณาชี้ขาด"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_sec_10', 'tmpl-nda-standard-v1', 'contract_section', '10. บททั่วไป (General Provisions)', 13, '{"intro":null,"content":null,"bullets":null,"subClauses":["10.1. ไม่มีการโอนสิทธิในทรัพย์สินทางปัญญา: การเปิดเผยข้อมูลความลับตามสัญญานี้ไม่ถือเป็นการโอนสิทธิ์ มอบสิทธิ์ (License) หรือให้สิทธิใดๆ ในสิทธิบัตร ลิขสิทธิ์ เครื่องหมายการค้า หรือทรัพย์สินทางปัญญาของผู้เปิดเผยข้อมูลแก่ผู้รับข้อมูล","10.2. การแก้ไขเพิ่มเติม: การแก้ไขหรือเปลี่ยนแปลงสัญญานี้จะทำได้ต่อเมื่อทำเป็นหนังสือและลงนามโดยผู้มีอำนาจของทั้งสองฝ่ายเท่านั้น","10.3. การแยกออกจากกันได้ (Severability): หากข้อกำหนดใดในสัญญานี้ตกเป็นโมฆะ หรือไม่สามารถบังคับใช้ได้ตามกฎหมาย ให้ข้อกำหนดส่วนที่เหลือยังคงมีผลบังคับใช้ได้โดยสมบูรณ์"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_witness', 'tmpl-nda-standard-v1', 'text_block', 'พยานหลักฐาน', 14, '{"content":"เพื่อเป็นหลักฐานแห่งการนี้ คู่สัญญาโดยผู้มีอำนาจลงนามได้อ่านและเข้าใจข้อความในสัญญานี้โดยละเอียดตลอดแล้ว เห็นว่าถูกต้องตรงตามเจตนา จึงได้ลงลายมือชื่อและประทับตราสำคัญ (ถ้ามี) ไว้เป็นสำคัญต่อหน้าพยาน ณ วัน เดือน ปี ที่ระบุไว้ข้างต้น"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-nda-standard-v1-b_nda_signatures', 'tmpl-nda-standard-v1', 'signatures', 'ลงนามทั้งสองฝ่าย', 15, '{"slots":[{"id":"s1","name":"{{authorized_signatory_name}}","role":"ผู้เปิดเผยข้อมูล (Disclosing Party)"},{"id":"s2","name":"{{customer_signatory_name}}","role":"ผู้รับข้อมูล (Receiving Party)"}]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_header', 'tmpl-partner-standard-v1', 'header', 'หัวกระดาษ', 1, '{"hasLogo":true,"logoUrl":"/Partner-logo.webp","companyName":"{{company_name}}","companyNameEn":"{{company_name_en}}","taxId":"{{company_tax_id}}","address":"{{company_address}}","phone":"{{company_phone}}","email":"{{company_email}}","align":"split"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_title', 'tmpl-partner-standard-v1', 'doc_title', 'หัวเรื่อง', 2, '{"titleText":"สัญญาแต่งตั้งพันธมิตรตัวแทนจำหน่าย","subtitleText":"(Partner Agreement)","align":"center"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_preamble', 'tmpl-partner-standard-v1', 'contract_preamble', 'คำนำสัญญาและคู่สัญญา', 3, '{"locationPrefix":"สัญญาฉบับนี้ทำขึ้น ณ","locationText":"{{contract_location}}","datePrefix":"สัญญาฉบับนี้ทำขึ้น ณ วันที่","dateText":"{{contract_date}}","betweenLabel":"ระหว่าง:","party1Text":"{{company_name}} เลขทะเบียนนิติบุคคล {{company_tax_id}} {{company_address}} (ซึ่งต่อไปในสัญญานี้จะเรียกว่า “Distributor” หรือ “ผู้จัดจำหน่ายหลัก”) ฝ่ายหนึ่ง","andLabel":"กับ","party2Text":"{{customer_company}} เลขทะเบียนนิติบุคคล {{customer_tax_id}} สำนักงานใหญ่ ตั้งอยู่เลขที่ {{customer_address}} (ซึ่งต่อไปในสัญญานี้จะเรียกว่า “Reseller” หรือ “ตัวแทนจำหน่าย”) อีกฝ่ายหนึ่ง","recital":"คู่สัญญาทั้งสองฝ่ายตกลงทำสัญญาแต่งตั้งตัวแทนจำหน่าย เพื่อทำการตลาด นำเสนอ และจัดจำหน่ายผลิตภัณฑ์ ซอฟต์แวร์ และเครื่องมือทางไอที (ซึ่งต่อไปนี้เรียกว่า “ผลิตภัณฑ์”) โดยมีข้อกำหนดและเงื่อนไขดังต่อไปนี้:"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_1', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 1. นิยามศัพท์ (Definitions)', 4, '{"intro":"ในสัญญานี้ คำหรือข้อความดังต่อไปนี้ให้มีความหมายตามที่กำหนดไว้ เว้นแต่บริบทจะกำหนดเป็นอย่างอื่น:","content":null,"bullets":null,"subClauses":["1.1 “เจ้าของผลิตภัณฑ์” (Vendor) หมายถึง บุคคล นิติบุคคล หรือผู้พัฒนาซอฟต์แวร์ ซึ่งเป็นผู้ถือครองลิขสิทธิ์ ทรัพย์สินทางปัญญา และสิทธิ์โดยชอบด้วยกฎหมายในตัวผลิตภัณฑ์ซอฟต์แวร์แต่เพียงผู้เดียว (หรือตามสิทธิ์ที่ได้รับอนุญาต)","1.2 “ผู้ใช้ปลายทาง” (End User) หมายถึง บุคคล นิติบุคคล หรือองค์กรที่เป็นผู้ซื้อ ได้รับสิทธิ์ หรือจัดหาผลิตภัณฑ์ซอฟต์แวร์ไปเพื่อวัตถุประสงค์ในการใช้งานจริงภายในองค์กรของตนเอง ไม่ใช่เพื่อวัตถุประสงค์ในการนำไปจำหน่ายหรือให้เช่าช่วง","1.3 “ผลิตภัณฑ์” (Product) หมายถึง ซอฟต์แวร์ ระบบปฏิบัติการ หรือเครื่องมือทางไอที รวมถึง “สิทธิ์การใช้งาน” เอกสารคู่มือ การอัปเดต และแพตช์แก้ไขความปลอดภัย ซึ่ง “ผู้จัดจำหน่ายหลัก” ได้รับสิทธิ์จัดจำหน่ายจาก “เจ้าของผลิตภัณฑ์”","1.4 “สิทธิ์การใช้งาน” (License/Subscription) หมายถึง สิทธิ์ทางกฎหมายที่ “เจ้าของผลิตภัณฑ์” หรือ “ผู้จัดจำหน่ายหลัก” อนุญาตให้ “ตัวแทนจำหน่าย” นำไปจัดจำหน่ายแก่ “ผู้ใช้ปลายทาง” เพื่อเข้าใช้ “ผลิตภัณฑ์” ตามข้อกำหนดและเงื่อนไขที่กำหนดไว้ในข้อตกลงสิทธิ์การใช้งานสำหรับ “ผู้ใช้ปลายทาง” (EULA)","1.5 “การลงทะเบียนสิทธิ์ในข้อตกลงทางการค้า” (Deal Registration) หมายถึง กระบวนการที่ “ตัวแทนจำหน่าย” แจ้งข้อมูลรายละเอียดของ “ผู้ใช้ปลายทาง” ขอบเขตงาน หรือโอกาสทางการค้า ผ่านระบบหรือช่องทางที่ “ผู้จัดจำหน่ายหลัก” กำหนดไว้ เพื่อขอรับสิทธิ์ในการเสนอขายและสิทธิประโยชน์อื่นใดตามเงื่อนไขของสัญญานั้น ๆ"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_2', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 2. ขอบเขตการแต่งตั้งและอาณาเขต (Scope of Appointment & Territory)', 5, '{"intro":null,"content":null,"bullets":null,"subClauses":["2.1 การแต่งตั้งและบทบาทของ “ผู้จัดจำหน่ายหลัก”: “ผู้จัดจำหน่ายหลัก” ในฐานะผู้ได้รับสิทธิ์อย่างถูกต้องจาก “เจ้าของผลิตภัณฑ์” แต่งตั้งตัวแทนจำหน่ายให้เป็น “ตัวแทนจำหน่าย” ประเภทแบบไม่ผูกขาด (Non-exclusive) โดย “ผู้จัดจำหน่ายหลัก” มีหน้าที่ในการจัดหา จัดส่ง และประสานงานเรื่องการออก “สิทธิ์การใช้งาน” ของ “ผลิตภัณฑ์” ให้แก่ “ตัวแทนจำหน่าย” เพื่อนำไปจำหน่ายให้แก่ “ผู้ใช้ปลายทาง”","2.2 สิทธิ์การจำหน่ายของ “ตัวแทนจำหน่าย”: “ตัวแทนจำหน่าย” สามารถจัดจำหน่าย “สิทธิ์การใช้งาน” ของ “ผลิตภัณฑ์” ให้กับ “ผู้ใช้ปลายทาง” เท่านั้น ไม่สามารถโอนสิทธิ์การใช้งาน หรือแสดงความเป็นเจ้าของในตัว “ผลิตภัณฑ์”","2.3 อาณาเขตทางภูมิศาสตร์ (Territory): “ตัวแทนจำหน่าย” มีสิทธิดำเนินกิจกรรมการขาย การส่งเสริมการขาย และทำตลาด “ผลิตภัณฑ์” ได้ภายในพื้นที่ ประเทศไทย เท่านั้น"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_3', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 3. สิทธิ หน้าที่ และความรับผิดชอบของคู่สัญญา (Obligations of the Parties)', 6, '{"intro":null,"content":null,"bullets":null,"subClauses":null,"distributorObligations":["การสนับสนุนด้านการขายและสื่อการตลาด: “ผู้จัดจำหน่ายหลัก” มีหน้าที่จัดหาเอกสาร ข้อมูลทางเทคนิค คู่มือการใช้งาน สื่อส่งเสริมการขาย และรายละเอียดราคาที่เป็นปัจจุบันให้แก่ “ตัวแทนจำหน่าย”","การอบรมบุคลากร (Training): “ผู้จัดจำหน่ายหลัก” ตกลงจะจัดให้มีการอบรมด้านผลิตภัณฑ์ (Product Training) และการใช้งานเบื้องต้นให้แก่ทีมงานของ “ตัวแทนจำหน่าย” ตามรอบเวลาที่ตกลงกัน","การประสานงานกับ “เจ้าของผลิตภัณฑ์”: “ผู้จัดจำหน่ายหลัก” จะทำหน้าที่เป็นตัวกลางในการประสานงาน แก้ไขปัญหา และติดตามข้อเรียกร้องต่าง ๆ ระหว่าง “ตัวแทนจำหน่าย” หรือ “ผู้ใช้ปลายทาง” กับ “เจ้าของผลิตภัณฑ์”","การไม่แข่งขันทางธุรกิจและการไม่ใช้ข้อมูลในทางที่ไม่เหมาะสม (Non-competition & Data Misuse): “ผู้จัดจำหน่ายหลัก” ตกลงจะไม่ดำเนินกิจกรรมทางธุรกิจ การส่งเสริมการขาย หรือติดต่อเสนอขาย “ผลิตภัณฑ์” โดยตรงแก่ “ผู้ใช้ปลายทาง” ของ “ตัวแทนจำหน่าย” ในลักษณะที่เป็นการแข่งขันทางธุรกิจกับ “ตัวแทนจำหน่าย” ในอาณาเขตที่กำหนด และจะไม่นำข้อมูลรายชื่อ “ผู้ใช้ปลายทาง” ข้อมูลการเสนอราคา หรือข้อมูลทางการค้าใด ๆ ที่ได้รับจาก “ตัวแทนจำหน่าย” ไปใช้ประโยชน์เพื่อตนเอง หรือบุคคลภายนอก หรือนำไปใช้ในลักษณะที่ส่งผลกระทบ ก่อให้เกิดความเสียหาย หรือทำให้ “ตัวแทนจำหน่าย” เสียประโยชน์ทางธุรกิจ ไม่ว่าโดยทางตรง หรือทางอ้อม"],"resellerObligations":["การทำตลาดและการรักษามาตรฐาน: “ตัวแทนจำหน่าย” ต้องทำการตลาด ถ่ายทอดข้อมูลอย่างถูกต้อง ปฏิบัติตามจรรยาบรรณทางธุรกิจ และรักษาสภาพแวดล้อมทางธุรกิจเพื่อส่งเสริมภาพลักษณ์ของ “ผลิตภัณฑ์” และ “ผู้จัดจำหน่ายหลัก”","การปฏิเสธการทำตลาดทับซ้อน (Non-poaching / Territory Limit): “ตัวแทนจำหน่าย” ต้องไม่แสวงหา “ผู้ใช้ปลายทาง” ส่งเสริมการขาย หรือเสนอขาย “ผลิตภัณฑ์” นอกอาณาเขตหรือกลุ่ม “ผู้ใช้ปลายทาง” ที่ได้รับการสงวนสิทธิ์ไว้ให้แก่คู่ค้ารายอื่นโดยชัดแจ้ง เว้นแต่ได้รับความยินยอมเป็นลายลักษณ์อักษรจาก “ผู้จัดจำหน่ายหลัก”"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_4', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 4. ลิขสิทธิ์ซอฟต์แวร์ รูปแบบการใช้งาน และการปฏิบัติตามกฎหมาย (Software Licensing & Compliance)', 7, '{"intro":null,"content":null,"bullets":null,"subClauses":["4.1 การรับประกันสิทธิโดย “ผู้จัดจำหน่ายหลัก”: “ผู้จัดจำหน่ายหลัก” รับประกันว่าตนมีสิทธิทางกฎหมายอย่างถูกต้องในการนำเสนอ และจัดจำหน่าย “สิทธิการใช้งาน” ของ “ผลิตภัณฑ์” ดังกล่าวให้แก่ “ตัวแทนจำหน่าย”","4.2 ข้อตกลงกับ “ผู้ใช้ปลายทาง”: “ตัวแทนจำหน่าย” มีหน้าที่ต้องแจ้ง ส่งมอบ และดูแลให้ “ผู้ใช้ปลายทาง” ยินยอมปฏิบัติตามข้อตกลงสิทธิการใช้งานสำหรับ “ผู้ใช้ปลายทาง” (End User License Agreement: EULA) ของ “เจ้าของผลิตภัณฑ์” ทุกครั้งก่อนเริ่มใช้งาน","4.3 การต่อต้านการละเมิดลิขสิทธิ์ (Anti-Piracy & Compliance): “ตัวแทนจำหน่าย” ตกลงจะไม่ทำการคัดลอก ดัดแปลง ทำวิศวกรรมย้อนกลับ (Reverse Engineering) หรือสนับสนุนให้เกิดการละเมิดลิขสิทธิ์ซอฟต์แวร์ และต้องให้ความร่วมมือในการตรวจสอบการใช้งานของ “ผู้ใช้ปลายทาง” เมื่อได้รับการร้องขอ"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_5', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 5. การกำหนดราคา ส่วนลด และเงื่อนไขการชำระเงิน (Pricing, Discounts, and Payment Terms)', 8, '{"intro":null,"content":null,"bullets":null,"subClauses":["5.1 โครงสร้างราคา: “ผู้จัดจำหน่ายหลัก” จะกำหนด และจัดส่งราคาต้นทุน (Cost Price) สำหรับ “ตัวแทนจำหน่าย” และระบุราคาแนะนำสำหรับ “ผู้ใช้ปลายทาง” (End User Price)","5.2 ส่วนลดพิเศษ (Special Discounts): การอนุมัติส่วนลดพิเศษให้อยู่ในวิจารณญาณของ “ผู้จัดจำหน่ายหลัก” โดย “ผู้จัดจำหน่ายหลัก” จะแจ้งยืนยันเป็นลายลักษณ์อักษร (หรือผ่านระบบอิเล็กทรอนิกส์) พร้อมกำหนดระยะเวลาความคุ้มครองของราคานั้น ๆ (Price Validity Period)","5.3 เงื่อนไขการส่งใบแจ้งหนี้ กำหนดระยะเวลาชำระเงิน (Credit Term) และการชำระเงิน: “ผู้จัดจำหน่ายหลัก” จะออกใบแจ้งหนี้เมื่อได้รับใบสั่งซื้อ (Purchase Order) และดำเนินการออก “สิทธิการใช้งาน” เรียบร้อยแล้ว โดยกำหนดระยะเวลาชำระเงิน (Credit Term) ภายใน 30 (สามสิบ) วัน นับแต่วันที่ออกใบแจ้งหนี้ให้กับ “ตัวแทนจำหน่าย” หากชำระล่าช้าต้องเสียดอกเบี้ยร้อยละ 1.5 ต่อเดือน สกุลเงินที่ใช้คือ บาทไทย","5.4 เงื่อนไขอัตราแลกเปลี่ยน (Exchange Rate Condition): การคำนวณราคาเป็นสกุลเงินบาทไทยจะอ้างอิงอัตราแลกเปลี่ยน ณ วันที่ออกใบเสนอราคา โดยตรึงไว้ 30 วัน"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_6', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 6. การบริการหลังการขายและการสนับสนุนทางเทคนิค (Technical Support and Maintenance & SLA)', 9, '{"intro":null,"content":null,"bullets":null,"subClauses":["6.1 ระดับการบริการขั้นแรกของ Reseller (Tier 1 Support): แบ่งตามความพร้อมของตัวแทนจำหน่าย (กรณีมีทีมงาน Tier 1 หรือกรณีส่งต่อ Pass-through ให้ผู้จัดจำหน่ายหลัก)","6.2 ระดับการบริการของ “ผู้จัดจำหน่ายหลัก” และการส่งต่อปัญหา (Tier 2/3 Escalation Path & SLA): อ้างอิง Back-to-Back SLA ของเจ้าของผลิตภัณฑ์","6.3 การต่ออายุสัญญาบริการ (Renewals): “ผู้จัดจำหน่ายหลัก” มีหน้าที่แจ้งเตือนรอบการต่ออายุ “สิทธิการใช้งาน” รายปีล่วงหน้าแก่ “ตัวแทนจำหน่าย” ไม่น้อยกว่า 60 วัน ก่อนวันหมดอายุ"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_7', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 7. การจัดการทรัพย์สินทางปัญญาและการจำกัดความรับผิด (Intellectual Property & Limitation of Liability)', 10, '{"intro":null,"content":null,"bullets":null,"subClauses":["7.1 การชดใช้ค่าเสียหายจากข้อพิพาทลิขสิทธิ์ (Indemnification): “ผู้จัดจำหน่ายหลัก” รับประกันว่า “ผลิตภัณฑ์” ไม่มีการละเมิดทรัพย์สินทางปัญญาของบุคคลภายนอก","7.2 การจำกัดความรับผิด (Limitation of Liability): ความรับผิดชอบสูงสุดทางการเงินจำกัดไว้ไม่เกินยอดเงินรวมที่ชำระให้แก่ผู้จัดจำหน่ายหลักที่ผ่านมาก่อนเกิดเหตุ"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_8', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 8. การรับประกัน (Warranty)', 11, '{"intro":null,"content":null,"bullets":null,"subClauses":["8.1 การรับประกันการทำงานของซอฟต์แวร์: รับประกันว่าทำงานตรงตามคุณลักษณะทางเทคนิคที่ระบุในคู่มือ","8.2 ข้อยกเว้นการรับประกัน: ไม่ครอบคลุมความเสียหายจากการดัดแปลงโดยไม่ได้รับอนุญาต"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_9', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 9. การรักษาความลับข้อมูลและการคุ้มครองข้อมูลส่วนบุคคล (Confidentiality & Data Protection)', 12, '{"intro":null,"content":null,"bullets":null,"subClauses":["9.1 การรักษาความลับทางธุรกิจและการใช้ข้อมูล: รักษาความลับตลอดอายุสัญญาและต่อเนื่อง 2 ปีหลังสิ้นสุดสัญญา","9.2 การคุ้มครองข้อมูลส่วนบุคคล (PDPA): ปฏิบัติตามกฎหมายคุ้มครองข้อมูลส่วนบุคคลอย่างเคร่งครัด"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_10', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 10. ระยะเวลาและการบอกเลิกสัญญา (Term and Termination)', 13, '{"intro":null,"content":null,"bullets":null,"subClauses":["10.1 ระยะเวลาสัญญา: 1 ปี นับแต่วันที่ลงนาม และต่ออายุอัตโนมัติคราวละ 1 ปี","10.2 การบอกเลิกสัญญาแบบมีเหตุผล: บอกเลิกได้ทันทีหากผิดสัญญาและไม่แก้ไขใน 30 วัน หรือล้มละลาย","10.3 การบอกเลิกสัญญาโดยไม่มีเหตุผล: แจ้งล่วงหน้าเป็นลายลักษณ์อักษรไม่น้อยกว่า 60 วัน","10.4 ภาระผูกพันหลังสิ้นสุดสัญญา: ยังคงต้องชำระค่าบริการที่ค้างชำระทั้งหมด และดูแลสิทธิการใช้งานที่มีผลอยู่"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_sec_11', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 11. กฎหมายที่ใช้บังคับและกระบวนการระงับข้อพิพาท (Governing Law & Dispute Resolution)', 14, '{"intro":null,"content":null,"bullets":null,"subClauses":["11.1 กฎหมายที่ใช้บังคับ: อยู่ภายใต้กฎหมายแห่งราชอาณาจักรไทย","11.2 กระบวนการระงับข้อพิพาท: เจรจาด้วยมิตรภาพภายใน 30 วัน หากไม่ยุติให้ส่งเรื่องสู่ศาลไทย"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_witness', 'tmpl-partner-standard-v1', 'text_block', 'พยานหลักฐาน', 15, '{"content":"สัญญานี้ทำขึ้นเป็นสองฉบับมีข้อความถูกต้องตรงกัน คู่สัญญาได้อ่านและเข้าใจข้อความโดยรายละเอียดตลอดแล้ว จึงได้ลงลายมือชื่อและประทับตรา (ถ้ามี) ไว้เป็นสำคัญต่อหน้าพยาน"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-partner-standard-v1-b_partner_signatures', 'tmpl-partner-standard-v1', 'signatures', 'ลงนามแต่งตั้ง', 16, '{"slots":[{"id":"s1","name":"{{authorized_signatory_name}}","role":"ผู้จัดจำหน่ายหลัก (Distributor)"},{"id":"s2","name":"{{customer_signatory_name}}","role":"ตัวแทนจำหน่าย (Reseller)"}]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-distributor-standard-v1-b_dist_header', 'tmpl-distributor-standard-v1', 'header', 'หัวกระดาษ', 1, '{"hasLogo":true,"logoUrl":"/preview.webp","companyName":"{{company_name}}","companyNameEn":"{{company_name_en}}","taxId":"{{company_tax_id}}","address":"{{company_address}}","phone":"{{company_phone}}","email":"{{company_email}}","align":"split"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-distributor-standard-v1-b_dist_title', 'tmpl-distributor-standard-v1', 'doc_title', 'หัวเรื่อง', 2, '{"titleText":"สัญญาแต่งตั้งและจัดจำหน่ายซอฟต์แวร์","subtitleText":"(Distributor and Reseller Master Agreement)","align":"center"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-distributor-standard-v1-b_dist_preamble', 'tmpl-distributor-standard-v1', 'contract_preamble', 'คำนำสัญญาและคู่สัญญา', 3, '{"locationPrefix":"สัญญาฉบับนี้ทำขึ้น ณ","locationText":"{{contract_location}}","datePrefix":"เมื่อวันที่","dateText":"{{contract_date}}","betweenLabel":"ระหว่าง:","party1Text":"{{company_name}} {{company_address}} ซึ่งต่อไปในสัญญานี้จะเรียกว่า “ผู้จัดจำหน่ายหลัก” (Distributor) ฝ่ายหนึ่ง","andLabel":"กับ","party2Text":"{{customer_company}} สำนักงานใหญ่ ตั้งอยู่เลขที่ {{customer_address}} (ซึ่งต่อไปในสัญญานี้จะเรียกว่า “Reseller” หรือ “ตัวแทนจำหน่ายต่อ”) อีกฝ่ายหนึ่ง","recital":"คู่สัญญาทั้งสองฝ่ายตกลงเข้าทำสัญญาแต่งตั้งตัวแทนจำหน่ายต่อ เพื่อทำการตลาด นำเสนอ และจัดจำหน่ายผลิตภัณฑ์ซอฟต์แวร์ และเครื่องมือทางไอที (ซึ่งต่อไปนี้เรียกว่า “ผลิตภัณฑ์”) โดยมีข้อกำหนดและเงื่อนไขดังต่อไปนี้:"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-distributor-standard-v1-b_dist_sec_1', 'tmpl-distributor-standard-v1', 'contract_section', '1. นิยามศัพท์ (Definitions)', 4, '{"intro":null,"content":null,"bullets":null,"subClauses":["1.1. “เจ้าของผลิตภัณฑ์” (Vendor) หมายถึง บุคคล นิติบุคคล หรือผู้พัฒนาซอฟต์แวร์ ซึ่งเป็นผู้ถือครองลิขสิทธิ์ ทรัพย์สินทางปัญญา และสิทธิ์โดยชอบด้วยกฎหมายในตัวผลิตภัณฑ์ซอฟต์แวร์แต่เพียงผู้เดียว (หรือตามสิทธิ์ที่ได้รับอนุญาต)","1.2. “ผู้ใช้ปลายทาง” (End User) หมายถึง บุคคล นิติบุคคล หรือองค์กรที่เป็นผู้ซื้อ ได้รับสิทธิ์ หรือจัดหาผลิตภัณฑ์ซอฟต์แวร์ไปเพื่อวัตถุประสงค์ในการใช้งานจริงภายในองค์กรของตนเอง ไม่ใช่เพื่อวัตถุประสงค์ในการนำไปจำหน่ายต่อหรือให้เช่าช่วง","1.3. “ผลิตภัณฑ์” (Product) หมายถึง ซอฟต์แวร์ ระบบปฏิบัติการ หรือเครื่องมือทางไอที รวมถึง “สิทธิ์การใช้งาน” เอกสารคู่มือ การอัปเดต และแพตช์แก้ไขความปลอดภัย ซึ่ง “ผู้จัดจำหน่ายหลัก” ได้รับสิทธิ์จัดจำหน่ายจาก “เจ้าของผลิตภัณฑ์”","1.4. “สิทธิ์การใช้งาน” (License/Subscription) หมายถึง สิทธิ์ทางกฎหมายที่ “เจ้าของผลิตภัณฑ์” หรือ “ผู้จัดจำหน่ายหลัก” อนุญาตให้ “ตัวแทนจำหน่ายต่อ” นำไปจัดจำหน่ายแก่ “ผู้ใช้ปลายทาง” เพื่อเข้าใช้ “ผลิตภัณฑ์” ตามข้อกำหนดและเงื่อนไขที่กำหนดไว้ในข้อตกลงสิทธิ์การใช้งานสำหรับ “ผู้ใช้ปลายทาง” (EULA)"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-distributor-standard-v1-b_dist_sec_2', 'tmpl-distributor-standard-v1', 'contract_section', '2. ขอบเขตการแต่งตั้งและอาณาเขต (Scope of Appointment & Territory)', 5, '{"intro":null,"content":null,"bullets":null,"subClauses":["2.1. การแต่งตั้งและบทบาทของ “ผู้จัดจำหน่ายหลัก”: “ผู้จัดจำหน่ายหลัก” แต่งตั้งตัวแทนจำหน่ายต่อให้เป็น “ตัวแทนจำหน่ายต่อ” ประเภทแบบไม่ผูกขาด (Non-exclusive)","2.2. สิทธิ์การจำหน่ายของ “ตัวแทนจำหน่ายต่อ”: สามารถจัดจำหน่าย “สิทธิ์การใช้งาน” ของ “ผลิตภัณฑ์” ให้กับ “ผู้ใช้ปลายทาง” เท่านั้น","2.3. อาณาเขตทางภูมิศาสตร์ (Territory): มีสิทธิ์ดำเนินกิจกรรมการขาย การส่งเสริมการขาย และทำการตลาด “ผลิตภัณฑ์” ได้ภายในพื้นที่ ประเทศไทย เท่านั้น"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-distributor-standard-v1-b_dist_witness', 'tmpl-distributor-standard-v1', 'text_block', 'พยานหลักฐาน', 6, '{"content":"เพื่อเป็นหลักฐานแห่งการนี้ คู่สัญญาโดยผู้มีอำนาจลงนามได้อ่านและเข้าใจข้อความในสัญญานี้โดยละเอียดตลอดแล้ว เห็นว่าถูกต้องตรงตามเจตนา จึงได้ลงลายมือชื่อและประทับตราสำคัญ (ถ้ามี) ไว้เป็นสำคัญต่อหน้าพยาน"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-distributor-standard-v1-b_dist_signatures', 'tmpl-distributor-standard-v1', 'signatures', 'ลงนามคู่สัญญา', 7, '{"slots":[{"id":"s1","name":"{{authorized_signatory_name}}","role":"ผู้จัดจำหน่ายหลัก (Distributor)"},{"id":"s2","name":"{{customer_signatory_name}}","role":"ตัวแทนจำหน่ายต่อ (Reseller)"}]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-notification-standard-v1-b_header', 'tmpl-notification-standard-v1', 'header', 'หัวกระดาษ', 1, '{"hasLogo":true,"logoUrl":"/quotation.png","companyName":"บริษัท เครสท์ เซนโด จำกัด","companyNameEn":"CREST ZENDO CO., LTD.","taxId":"0105558073755","address":"8/40 The Connect 37, ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210","phone":"02-123-4567","email":"contact@crestzendo.com","align":"split"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-notification-standard-v1-b_title', 'tmpl-notification-standard-v1', 'doc_title', 'หัวเรื่อง', 2, '{"titleText":"หนังสือแจ้งเปลี่ยนแปลงที่ตั้งสำนักงานใหญ่","subtitleText":"NOTICE OF HEAD OFFICE RELOCATION","align":"center"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-notification-standard-v1-b_info', 'tmpl-notification-standard-v1', 'info_grid', 'ข้อมูลหนังสือ', 3, '{"billToTitle":"เรียน:","billToCompany":"ท่านคู่ค้า ลูกค้า และพันธมิตรทางธุรกิจทุกท่าน","attnName":"ผู้มีอุปการคุณทุกท่าน","subject":"แจ้งเปลี่ยนแปลงสถานที่ตั้งสำนักงานใหญ่แห่งใหม่","quotationNo":"TRAC-2609001","date":"01 กันยายน 2569","validity":"มีผล 16 กันยายน 2569","amName":"ฝ่ายบริหารจัดการทั่วไป"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-notification-standard-v1-b_text', 'tmpl-notification-standard-v1', 'text_block', 'ข้อความหนังสือแจ้ง', 4, '{"content":"บริษัท เครสท์ เซนโด จำกัด ขอเรียนแจ้งให้ท่านทราบว่า บริษัทฯ ได้ดำเนินการย้ายสถานที่ตั้งสำนักงานใหญ่แห่งใหม่ เพื่อรองรับการขยายตัวทางธุรกิจและการให้บริการที่มีประสิทธิภาพยิ่งขึ้น โดยมีผลบังคับใช้ตั้งแต่วันที่ 16 กันยายน 2569 เป็นต้นไป"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-notification-standard-v1-b_terms', 'tmpl-notification-standard-v1', 'terms', 'เปรียบเทียบที่อยู่เดิมและใหม่', 5, '{"heading":"รายละเอียดสถานที่ตั้งสำนักงานใหญ่:","bullets":["ที่อยู่เดิม: 45 ซอยโกสุมรวมใจ 37 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210","ที่อยู่ใหม่ (มีผล 16 ก.ย. 2569): 8/40 The Connect 37, ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210","หมายเลขโทรศัพท์และช่องทางการติดต่อทางอิเล็กทรอนิกส์ยังคงใช้งานได้ตามปกติ"]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('tmpl-notification-standard-v1-b_signatures', 'tmpl-notification-standard-v1', 'signatures', 'ผู้มีอำนาจลงนาม', 6, '{"slots":[{"id":"s1","name":"นายศรายุทธ โกสิยารักษ์","role":"กรรมการผู้จัดการ / CEO"}]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_header', 'tmpl-nda-standard-v1', 'header', 'หัวกระดาษ', 0, '{"hasLogo":true,"logoUrl":"/preview.webp","companyName":"{{company_name}}","companyNameEn":"{{company_name_en}}","taxId":"{{company_tax_id}}","address":"{{company_address}}","phone":"{{company_phone}}","email":"{{company_email}}","align":"split"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_title', 'tmpl-nda-standard-v1', 'doc_title', 'หัวเรื่อง', 1, '{"titleText":"หนังสือสัญญาไม่เปิดเผยข้อมูล","subtitleText":"(NON-DISCLOSURE AGREEMENT - NDA)","align":"center"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_preamble', 'tmpl-nda-standard-v1', 'contract_preamble', 'คำนำสัญญาและคู่สัญญา', 2, '{"locationPrefix":"สัญญาฉบับนี้ทำขึ้น ณ","locationText":"{{contract_location}}","datePrefix":"เมื่อวันที่","dateText":"{{contract_date}}","betweenLabel":"ระหว่าง:","party1Text":"{{company_name}} สำนักงานใหญ่ ตั้งอยู่เลขที่ 8/40 เดอะ คอนเนค 37 ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210 ประเทศไทย ซึ่งต่อไปในสัญญานี้จะเรียกว่า “ผู้เปิดเผยข้อมูล” (Disclosing Party) ฝ่ายหนึ่ง","andLabel":"และ","party2Text":"{{customer_company}} สำนักงานใหญ่ ตั้งอยู่เลขที่ {{customer_address}} ซึ่งต่อไปในสัญญานี้จะเรียกว่า “ผู้รับข้อมูล” (Receiving Party) อีกฝ่ายหนึ่ง","partiesSummary":"(รวมเรียกว่า “คู่สัญญาทั้งสองฝ่าย” หรือเรียกว่า “ฝ่าย” หากหมายถึงฝ่ายใดฝ่ายหนึ่ง)","recital":"โดยที่ ผู้เปิดเผยข้อมูล เป็นผู้ประกอบธุรกิจจัดจำหน่ายและให้บริการด้านซอฟต์แวร์ ไอทีโซลูชัน และเทคโนโลยีดิจิทัล และมีความประสงค์จะเปิดเผยข้อมูลที่มีลักษณะเป็นความลับของตนให้แก่ ผู้รับข้อมูล เพื่อวัตถุประสงค์ในการประเมิน ความร่วมมือ หรือการทำธุรกิจร่วมกัน และผู้รับข้อมูลตกลงที่จะรับและรักษาข้อมูลความลับดังกล่าวตามข้อกำหนดและเงื่อนไขในสัญญานี้ คู่สัญญาจึงตกลงทำสัญญามีข้อความดังต่อไปนี้:"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_sec_1', 'tmpl-nda-standard-v1', 'contract_section', '1. คำนิยามข้อมูลที่เป็นความลับ (Definition of Confidential Information)', 3, '{"intro":"1.1. “ข้อมูลที่เป็นความลับ” (Confidential Information) หมายถึง ข้อมูล เอกสาร สารสนเทศ เทคโนโลยี และความรู้ความชำนาญ (Know-how) ทั้งหมด ไม่ว่าจะอยู่ในรูปแบบใด (ลายลักษณ์อักษร, วาจา, อิเล็กทรอนิกส์, รหัสคอมพิวเตอร์, หรือสื่อบันทึกข้อมูลอื่นใด) ที่ผู้เปิดเผยข้อมูลส่งมอบ เปิดเผย หรือให้เข้าถึงแก่ผู้รับข้อมูล ทั้งก่อนและหลังวันทำสัญญาฉบับนี้ ซึ่งรวมถึงแต่ไม่จำกัดเพียง:","content":null,"bullets":["ข้อมูลด้านเทคนิคและซอฟต์แวร์: ซอร์ซโค้ด (Source Code), ออบเจกต์โค้ด (Object Code), อัลกอริทึม (Algorithms), สถาปัตยกรรมระบบ (System Architecture), โครงสร้างฐานข้อมูล, เอกสาร API, คู่มือเทคนิค, ผลการทดสอบ, บัก (Bugs), Credential, Log, API Token, User Experience (UX), User Interface (UI), Credential ต่างๆ, Knowledge Base และข้อผิดพลาดของระบบ","ข้อมูลทางการค้าและธุรกิจ: ข้อมูลราคาต้นทุน (Cost Structure), โครงสร้างส่วนลด (Discount Schemes), อัตราค่าคอมมิชชั่น, บันทึกการประชุม, แผนกลยุทธ์การตลาด, แผนการขาย, รายชื่อและข้อมูลลูกค้าปลายทาง (End-customers), รายชื่อผู้จัดจำหน่าย และประมาณการทางการเงิน","ข้อมูลส่วนบุคคล (Personal Data): ข้อมูลส่วนบุคคลของพนักงาน ลูกค้า หรือผู้ใช้งานระบบตามกฎหมายว่าด้วยการคุ้มครองข้อมูลส่วนบุคคล (PDPA) ที่ผู้รับข้อมูลเข้าถึงได้ระหว่างการทำระบบ การทดสอบ (PoC) หรือการสนับสนุนทางเทคนิค (Technical Support)","ความคิดสร้างสรรค์และทรัพย์สินทางปัญญา: แบบระเบียบ ขั้นตอนการทำงาน ต้นแบบ (Prototypes) สิทธิบัตร เครื่องหมายการค้า หรือความลับทางการค้าที่ยังไม่ได้เปิดเผยต่อสาธารณะ"],"subClauses":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_sec_2', 'tmpl-nda-standard-v1', 'contract_section', '2. ข้อยกเว้นข้อมูลที่เป็นความลับ (Exclusions from Confidential Information)', 4, '{"intro":"ข้อมูลความลับตามข้อ 1 ให้ไม่รวมถึงข้อมูลใดๆ ที่ผู้รับข้อมูลสามารถพิสูจน์ได้ด้วยหลักฐานเป็นลายลักษณ์อักษรว่า:","content":null,"bullets":null,"subClauses":["2.1. เป็นข้อมูลที่ตกเป็นของสาธารณะหรือเปิดเผยทั่วไปอยู่แล้วก่อน หรือในเวลาที่เปิดเผย โดยไม่ได้เกิดจากการกระทำผิดสัญญาหรือการละเมิดของผู้รับข้อมูล หรือบุคคลในสังกัด","2.2. เป็นข้อมูลที่ผู้รับข้อมูลมีอยู่แล้วโดยชอบด้วยกฎหมายก่อนที่จะได้รับจากผู้เปิดเผยข้อมูล โดยไม่มีข้อผูกมัดเรื่องการรักษาความลับใดๆ","2.3. เป็นข้อมูลที่ผู้รับข้อมูลได้รับมาจากบุคคลที่สามโดยชอบธรรม โดยบุคคลที่สามดังกล่าวมีสิทธิ์เปิดเผยได้และไม่มีข้อผูกมัดเรื่องการรักษาความลับกับผู้เปิดเผยข้อมูล","2.4. เป็นข้อมูลที่ผู้รับข้อมูลพัฒนาขึ้นมาเองโดยอิสระ (Independently Developed) โดยไม่ได้อ้างอิงหรือใช้ข้อมูลความลับของผู้เปิดเผยข้อมูลเลย","2.5. ข้อมูลที่ต้องเปิดเผยตามคำสั่งศาล หน่วยงานราชการ หรือองค์กรกำกับดูแลตามกฎหมาย โดยผู้รับข้อมูลต้องแจ้งให้ผู้เปิดเผยข้อมูลทราบทันทีล่วงหน้าเป็นลายลักษณ์อักษร (หากไม่ขัดต่อกฎหมาย) เพื่อให้ผู้เปิดเผยข้อมูลมีโอกาสคัดค้านหรือร้องขอมาตรการคุ้มครอง"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_sec_3', 'tmpl-nda-standard-v1', 'contract_section', '3. วัตถุประสงค์ในการเปิดเผยข้อมูล (Purpose of Disclosure)', 5, '{"intro":"3.1. ผู้เปิดเผยข้อมูลเปิดเผยข้อมูลความลับแก่ผู้รับข้อมูล เพื่อวัตถุประสงค์เฉพาะเจาะจงดังต่อไปนี้เท่านั้น (“วัตถุประสงค์”):","content":null,"bullets":["เพื่อการประเมินความเป็นไปได้ในการเข้าทำสัญญาความร่วมมือทางธุรกิจ การเป็นพันธมิตร (Partner), ผู้จัดจำหน่าย (Distributor) หรือตัวแทนจำหน่าย (Reseller)","เพื่อการทดสอบระบบ การสาธิต หรือการทำระบบทดลองใช้ (Proof of Concept - PoC) ให้แก่คู่สัญญาหรือลูกค้าเป้าหมาย","เพื่อการบูรณาการระบบ (System Integration), การติดตั้ง, การพัฒนาต่อเติมตามคำขอ หรือการให้บริการสนับสนุนทางเทคนิค (Technical Support)","เพื่อสนับสนุนการขาย หรือการให้บริการที่เกี่ยวข้องกับข้อมูลนั้น"],"subClauses":null,"closing":"3.2. ผู้รับข้อมูลตกลงอย่างเคร่งครัดว่าจะไม่นำข้อมูลความลับไปใช้เพื่อวัตถุประสงค์อื่นใด นอกเหนือจากที่ระบุในข้อ 3.1 โดยเฉพาะอย่างยิ่ง ห้ามนำไปใช้เพื่อประโยชน์ทางการค้าของตนเองหรือบุคคลภายนอก หรือนำไปใช้ในลักษณะที่เป็นแข่งขันกับผู้เปิดเผยข้อมูล"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_sec_4', 'tmpl-nda-standard-v1', 'contract_section', '4. หน้าที่และความรับผิดชอบของผู้รับข้อมูล (Obligations of Receiving Party)', 6, '{"intro":"ผู้รับข้อมูลตกลงและรับรองที่จะปฏิบัติตามหน้าที่ดังต่อไปนี้:","content":null,"bullets":null,"subClauses":["4.1. การเก็บรักษาความลับ: ต้องระมัดระวังและรักษาข้อมูลความลับด้วยมาตรฐานความปลอดภัยที่ไม่น้อยกว่าระดับที่ตนใช้รักษาข้อมูลความลับของตนเอง และต้องไม่ต่ำกว่ามาตรฐานระมัดระวังตามวิญญูชน","4.2. ข้อจำกัดในการเข้าถึง (Need-to-Know Basis): จำกัดการเปิดเผยข้อมูลความลับเฉพาะแก่กรรมการ พนักงาน ลูกจ้าง หรือที่ปรึกษาทางกฎหมาย/การเงินของผู้รับข้อมูลที่มีความจำเป็นต้องทราบข้อมูลดังกล่าวเพื่อวัตถุประสงค์ข้างต้นเท่านั้น และบุคคลดังกล่าวต้องมีพันธะผูกพันในการรักษาความลับไม่ต่ำกว่าข้อกำหนดในสัญญานี้","4.3. มาตรการความมั่นคงปลอดภัยทางไซเบอร์: จัดให้มีมาตรการรักษาความปลอดภัยทางเทคนิคและการบริหารจัดการ (Technical and Organizational Security Measures) ที่เหมาะสม เช่น การเข้ารหัสข้อมูล (Encryption), การกำหนดสิทธิ์เข้าถึง (Access Control), การป้องกันไวรัสและมัลแวร์เพื่อป้องกันการเข้าถึง การสูญหาย หรือการรั่วไหลโดยไม่ได้รับอนุญาต","4.4. การแจ้งเหตุละเมิด: หากพบหรือสงสัยว่ามีการรั่วไหล การเข้าถึงโดยมิชอบ หรือการละเมิดข้อมูลความลับ ผู้รับข้อมูลต้องแจ้งให้ผู้เปิดเผยข้อมูลทราบทันทีภายใน 24 ชั่วโมงนับแต่พบเหตุ พร้อมทั้งร่วมมือในการระงับและแก้ไขเหตุการณ์ดังกล่าว"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_sec_5', 'tmpl-nda-standard-v1', 'contract_section', '5. ข้อจำกัดเรื่องวิศวกรรมย้อนกลับ (Strict No Reverse Engineering/Decompilation)', 7, '{"intro":null,"content":"ผู้รับข้อมูลตกลงและรับรองว่าจะไม่ทำการ (และจะไม่ยินยอมหรือมอบหมายให้บุคคลภายนอกทำการ) ถอดรหัส (Decompile), ทำวิศวกรรมย้อนกลับ (Reverse Engineer), ถอดประกอบ (Disassemble), แปลงรหัส (Translate) หรือพยายามแกะรหัสเพื่อเข้าถึงซอร์ซโค้ด (Source Code), อัลกอริทึม หรือสถาปัตยกรรมภายในของซอฟต์แวร์ ระบบ หรือเทคโนโลยีของผู้เปิดเผยข้อมูล ไม่ว่าด้วยวิธีใดๆ เว้นแต่จะได้รับความยินยอมเป็นลายลักษณ์อักษรจากผู้เปิดเผยข้อมูลก่อนเท่านั้น","bullets":null,"subClauses":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_sec_6', 'tmpl-nda-standard-v1', 'contract_section', '6. ระยะเวลาของสัญญาและการมีผลต่อเนื่อง (Term and Survival)', 8, '{"intro":null,"content":null,"bullets":null,"subClauses":["6.1. สัญญาฉบับนี้มีผลบังคับใช้นับแต่วันที่ระบุในตอนต้นของสัญญา และจะมีผลบังคับเป็นระยะเวลา 3 ปี นับจากวันทำสัญญา (“ระยะเวลาสัญญา”)","6.2. แม้ว่าสัญญานี้จะสิ้นสุดลงหรือระงับไปไม่ว่าด้วยเหตุใดก็ตาม ข้อผูกพันในการรักษาความลับตามสัญญานี้ยังคงมีผลบังคับต่อเนื่องไปอีกเป็นระยะเวลา 3 ปีนับแต่วันที่สัญญานี้สิ้นสุดลง หรือจนกว่าข้อมูลความลับนั้นจะตกเป็นของสาธารณะโดยมิใช่ความผิดของผู้รับข้อมูล (แล้วแต่วาระใดจะถึงก่อน)","6.3. สำหรับข้อมูลความลับที่เป็นความลับทางการค้า (Trade Secrets) หรือซอร์ซโค้ด (Source Code) ภาระผูกพันในการรักษาความลับจะมีผลบังคับอย่างถาวรโดยไม่มีกำหนดระยะเวลาสิ้นสุด"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_sec_7', 'tmpl-nda-standard-v1', 'contract_section', '7. การจัดการข้อมูลเมื่อสัญญาสินสุด (Return or Destruction of Information)', 9, '{"intro":"7.1. เมื่อสัญญานี้สิ้นสุดลง หรือเมื่อได้รับการร้องขอเป็นลายลักษณ์อักษรจากผู้เปิดเผยข้อมูล ผู้รับข้อมูลต้องดำเนินการทันทีภายในระยะเวลา 14 วัน ดังนี้:","content":null,"bullets":["คืนเอกสาร สื่อบันทึกข้อมูล และสำเนาข้อมูลความลับทั้งหมดให้แก่ผู้เปิดเผยข้อมูล หรือ","ทำลายข้อมูลความลับรวมถึงไฟล์อิเล็กทรอนิกส์ สำเนา สรุป หรือเอกสารดัดแปลงที่เกี่ยวข้องทั้งหมดอย่างถาวร ไม่สามารถกู้คืนได้"],"subClauses":null,"closing":"7.2. ผู้รับข้อมูลต้องจัดทำหนังสือรับรองเป็นลายลักษณ์อักษร ลงนามโดยกรรมการผู้มีอำนาจเพื่อยืนยันว่าได้ส่งคืนหรือทำลายข้อมูลความลับทั้งหมดเรียบร้อยแล้วส่งมอบให้แก่ผู้เปิดเผยข้อมูล (เว้นแต่ข้อมูลที่จำเป็นต้องจัดเก็บตามข้อกำหนดทางกฎหมาย หรือระบบสำรองข้อมูลอัตโนมัติ (Automated Backup) ซึ่งต้องได้รับการรักษาความลับตามสัญญานี้ต่อไป)"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_sec_8', 'tmpl-nda-standard-v1', 'contract_section', '8. การเยียวยาเมื่อผิดสัญญาและค่าเสียหาย (Remedies for Breach)', 10, '{"intro":null,"content":null,"bullets":null,"subClauses":["8.1. คู่สัญญาตกลงว่าการเปิดเผยหรือใช้ข้อมูลความลับโดยขัดต่อสัญญานี้ จะก่อให้เกิดความเสียหายอย่างร้ายแรงแก่ผู้เปิดเผยข้อมูล ซึ่งไม่สามารถชดเชยด้วยเยียวยาทางการเงิน หรือค่าเสียหายเพียงอย่างเดียวได้","8.2. ในกรณีที่มีการฝ่าฝืนหรือมีแนวโน้มว่าจะฝ่าฝืนสัญญานี้ ผู้เปิดเผยข้อมูลมีสิทธิร้องขอต่อศาลที่มีเขตอำนาจเพื่อให้ออกคำสั่งคุ้มครองชั่วคราว คำสั่งห้ามกระทำการ (Injunctive Relief) หรือมาตรการบรรเทาทุกข์ตามกฎหมายอื่นใด โดยไม่จำเป็นต้องพิสูจน์ความเสียหายเป็นตัวเงินจริง","8.3. สิทธิตามข้อ 8.2 ไม่ตัดสิทธิผู้เปิดเผยข้อมูลในการเรียกร้องค่าเสียหายที่เกิดขึ้นจริง (Actual Damages) ค่าขาดประโยชน์ และค่าใช้จ่ายทางกฎหมายรวมถึงค่าทนายความตามสมควรจากผู้รับข้อมูล"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_sec_9', 'tmpl-nda-standard-v1', 'contract_section', '9. กฎหมายที่ใช้บังคับและเขตอำนาจศาล (Governing Law and Jurisdiction)', 11, '{"intro":null,"content":null,"bullets":null,"subClauses":["9.1. สัญญาฉบับนี้ให้ตีความและบังคับใช้ตามกฎหมายแห่งราชอาณาจักรไทย","9.2. หากเกิดข้อพิพาท ข้อขัดแย้ง หรือการเรียกร้องใดๆ ที่เกิดขึ้นจากหรือเกี่ยวเนื่องกับสัญญานี้รวมทั้งการผิดสัญญา คู่สัญญาทั้งสองฝ่ายตกลงจะพยายามระงับข้อพิพาทโดยการเจรจาด้วยความซื่อสัตย์สุจริตก่อน หากไม่สามารถตกลงกันได้ภายใน 30 วัน ให้ส่งเรื่องให้ศาลในประเทศไทยที่มีเขตอำนาจ เป็นผู้พิจารณาชี้ขาด"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_sec_10', 'tmpl-nda-standard-v1', 'contract_section', '10. บททั่วไป (General Provisions)', 12, '{"intro":null,"content":null,"bullets":null,"subClauses":["10.1. ไม่มีการโอนสิทธิในทรัพย์สินทางปัญญา: การเปิดเผยข้อมูลความลับตามสัญญานี้ไม่ถือเป็นการโอนสิทธิ์ มอบสิทธิ์ (License) หรือให้สิทธิใดๆ ในสิทธิบัตร ลิขสิทธิ์ เครื่องหมายการค้า หรือทรัพย์สินทางปัญญาของผู้เปิดเผยข้อมูลแก่ผู้รับข้อมูล","10.2. การแก้ไขเพิ่มเติม: การแก้ไขหรือเปลี่ยนแปลงสัญญานี้จะทำได้ต่อเมื่อทำเป็นหนังสือและลงนามโดยผู้มีอำนาจของทั้งสองฝ่ายเท่านั้น","10.3. การแยกออกจากกันได้ (Severability): หากข้อกำหนดใดในสัญญานี้ตกเป็นโมฆะ หรือไม่สามารถบังคับใช้ได้ตามกฎหมาย ให้ข้อกำหนดส่วนที่เหลือยังคงมีผลบังคับใช้ได้โดยสมบูรณ์"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_witness', 'tmpl-nda-standard-v1', 'text_block', 'พยานหลักฐาน', 13, '{"content":"เพื่อเป็นหลักฐานแห่งการนี้ คู่สัญญาโดยผู้มีอำนาจลงนามได้อ่านและเข้าใจข้อความในสัญญานี้โดยละเอียดตลอดแล้ว เห็นว่าถูกต้องตรงตามเจตนา จึงได้ลงลายมือชื่อและประทับตราสำคัญ (ถ้ามี) ไว้เป็นสำคัญต่อหน้าพยาน ณ วัน เดือน ปี ที่ระบุไว้ข้างต้น"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_nda_signatures', 'tmpl-nda-standard-v1', 'signatures', 'ลงนามทั้งสองฝ่าย', 14, '{"slots":[{"id":"s1","name":"{{authorized_signatory_name}}","role":"ผู้เปิดเผยข้อมูล (Disclosing Party)"},{"id":"s2","name":"{{customer_signatory_name}}","role":"ผู้รับข้อมูล (Receiving Party)"}]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_header', 'tmpl-partner-standard-v1', 'header', 'หัวกระดาษ', 0, '{"hasLogo":true,"logoUrl":"/Partner-logo.webp","companyName":"{{company_name}}","companyNameEn":"{{company_name_en}}","taxId":"{{company_tax_id}}","address":"{{company_address}}","phone":"{{company_phone}}","email":"{{company_email}}","align":"split"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_title', 'tmpl-partner-standard-v1', 'doc_title', 'หัวเรื่อง', 1, '{"titleText":"สัญญาแต่งตั้งพันธมิตรตัวแทนจำหน่าย","subtitleText":"(Partner Agreement)","align":"center"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_preamble', 'tmpl-partner-standard-v1', 'contract_preamble', 'คำนำสัญญาและคู่สัญญา', 2, '{"locationPrefix":"สัญญาฉบับนี้ทำขึ้น ณ","locationText":"{{contract_location}}","datePrefix":"สัญญาฉบับนี้ทำขึ้น ณ วันที่","dateText":"{{contract_date}}","betweenLabel":"ระหว่าง:","party1Text":"{{company_name}} เลขทะเบียนนิติบุคคล {{company_tax_id}} {{company_address}} (ซึ่งต่อไปในสัญญานี้จะเรียกว่า “Distributor” หรือ “ผู้จัดจำหน่ายหลัก”) ฝ่ายหนึ่ง","andLabel":"กับ","party2Text":"{{customer_company}} เลขทะเบียนนิติบุคคล {{customer_tax_id}} สำนักงานใหญ่ ตั้งอยู่เลขที่ {{customer_address}} (ซึ่งต่อไปในสัญญานี้จะเรียกว่า “Reseller” หรือ “ตัวแทนจำหน่าย”) อีกฝ่ายหนึ่ง","recital":"คู่สัญญาทั้งสองฝ่ายตกลงทำสัญญาแต่งตั้งตัวแทนจำหน่าย เพื่อทำการตลาด นำเสนอ และจัดจำหน่ายผลิตภัณฑ์ ซอฟต์แวร์ และเครื่องมือทางไอที (ซึ่งต่อไปนี้เรียกว่า “ผลิตภัณฑ์”) โดยมีข้อกำหนดและเงื่อนไขดังต่อไปนี้:"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_1', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 1. นิยามศัพท์ (Definitions)', 3, '{"intro":"ในสัญญานี้ คำหรือข้อความดังต่อไปนี้ให้มีความหมายตามที่กำหนดไว้ เว้นแต่บริบทจะกำหนดเป็นอย่างอื่น:","content":null,"bullets":null,"subClauses":["1.1 “เจ้าของผลิตภัณฑ์” (Vendor) หมายถึง บุคคล นิติบุคคล หรือผู้พัฒนาซอฟต์แวร์ ซึ่งเป็นผู้ถือครองลิขสิทธิ์ ทรัพย์สินทางปัญญา และสิทธิ์โดยชอบด้วยกฎหมายในตัวผลิตภัณฑ์ซอฟต์แวร์แต่เพียงผู้เดียว (หรือตามสิทธิ์ที่ได้รับอนุญาต)","1.2 “ผู้ใช้ปลายทาง” (End User) หมายถึง บุคคล นิติบุคคล หรือองค์กรที่เป็นผู้ซื้อ ได้รับสิทธิ์ หรือจัดหาผลิตภัณฑ์ซอฟต์แวร์ไปเพื่อวัตถุประสงค์ในการใช้งานจริงภายในองค์กรของตนเอง ไม่ใช่เพื่อวัตถุประสงค์ในการนำไปจำหน่ายหรือให้เช่าช่วง","1.3 “ผลิตภัณฑ์” (Product) หมายถึง ซอฟต์แวร์ ระบบปฏิบัติการ หรือเครื่องมือทางไอที รวมถึง “สิทธิ์การใช้งาน” เอกสารคู่มือ การอัปเดต และแพตช์แก้ไขความปลอดภัย ซึ่ง “ผู้จัดจำหน่ายหลัก” ได้รับสิทธิ์จัดจำหน่ายจาก “เจ้าของผลิตภัณฑ์”","1.4 “สิทธิ์การใช้งาน” (License/Subscription) หมายถึง สิทธิ์ทางกฎหมายที่ “เจ้าของผลิตภัณฑ์” หรือ “ผู้จัดจำหน่ายหลัก” อนุญาตให้ “ตัวแทนจำหน่าย” นำไปจัดจำหน่ายแก่ “ผู้ใช้ปลายทาง” เพื่อเข้าใช้ “ผลิตภัณฑ์” ตามข้อกำหนดและเงื่อนไขที่กำหนดไว้ในข้อตกลงสิทธิ์การใช้งานสำหรับ “ผู้ใช้ปลายทาง” (EULA)","1.5 “การลงทะเบียนสิทธิ์ในข้อตกลงทางการค้า” (Deal Registration) หมายถึง กระบวนการที่ “ตัวแทนจำหน่าย” แจ้งข้อมูลรายละเอียดของ “ผู้ใช้ปลายทาง” ขอบเขตงาน หรือโอกาสทางการค้า ผ่านระบบหรือช่องทางที่ “ผู้จัดจำหน่ายหลัก” กำหนดไว้ เพื่อขอรับสิทธิ์ในการเสนอขายและสิทธิประโยชน์อื่นใดตามเงื่อนไขของสัญญานั้น ๆ"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_2', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 2. ขอบเขตการแต่งตั้งและอาณาเขต (Scope of Appointment & Territory)', 4, '{"intro":null,"content":null,"bullets":null,"subClauses":["2.1 การแต่งตั้งและบทบาทของ “ผู้จัดจำหน่ายหลัก”: “ผู้จัดจำหน่ายหลัก” ในฐานะผู้ได้รับสิทธิ์อย่างถูกต้องจาก “เจ้าของผลิตภัณฑ์” แต่งตั้งตัวแทนจำหน่ายให้เป็น “ตัวแทนจำหน่าย” ประเภทแบบไม่ผูกขาด (Non-exclusive) โดย “ผู้จัดจำหน่ายหลัก” มีหน้าที่ในการจัดหา จัดส่ง และประสานงานเรื่องการออก “สิทธิ์การใช้งาน” ของ “ผลิตภัณฑ์” ให้แก่ “ตัวแทนจำหน่าย” เพื่อนำไปจำหน่ายให้แก่ “ผู้ใช้ปลายทาง”","2.2 สิทธิ์การจำหน่ายของ “ตัวแทนจำหน่าย”: “ตัวแทนจำหน่าย” สามารถจัดจำหน่าย “สิทธิ์การใช้งาน” ของ “ผลิตภัณฑ์” ให้กับ “ผู้ใช้ปลายทาง” เท่านั้น ไม่สามารถโอนสิทธิ์การใช้งาน หรือแสดงความเป็นเจ้าของในตัว “ผลิตภัณฑ์”","2.3 อาณาเขตทางภูมิศาสตร์ (Territory): “ตัวแทนจำหน่าย” มีสิทธิดำเนินกิจกรรมการขาย การส่งเสริมการขาย และทำตลาด “ผลิตภัณฑ์” ได้ภายในพื้นที่ ประเทศไทย เท่านั้น"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_3', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 3. สิทธิ หน้าที่ และความรับผิดชอบของคู่สัญญา (Obligations of the Parties)', 5, '{"intro":null,"content":null,"bullets":null,"subClauses":null,"distributorObligations":["การสนับสนุนด้านการขายและสื่อการตลาด: “ผู้จัดจำหน่ายหลัก” มีหน้าที่จัดหาเอกสาร ข้อมูลทางเทคนิค คู่มือการใช้งาน สื่อส่งเสริมการขาย และรายละเอียดราคาที่เป็นปัจจุบันให้แก่ “ตัวแทนจำหน่าย”","การอบรมบุคลากร (Training): “ผู้จัดจำหน่ายหลัก” ตกลงจะจัดให้มีการอบรมด้านผลิตภัณฑ์ (Product Training) และการใช้งานเบื้องต้นให้แก่ทีมงานของ “ตัวแทนจำหน่าย” ตามรอบเวลาที่ตกลงกัน","การประสานงานกับ “เจ้าของผลิตภัณฑ์”: “ผู้จัดจำหน่ายหลัก” จะทำหน้าที่เป็นตัวกลางในการประสานงาน แก้ไขปัญหา และติดตามข้อเรียกร้องต่าง ๆ ระหว่าง “ตัวแทนจำหน่าย” หรือ “ผู้ใช้ปลายทาง” กับ “เจ้าของผลิตภัณฑ์”","การไม่แข่งขันทางธุรกิจและการไม่ใช้ข้อมูลในทางที่ไม่เหมาะสม (Non-competition & Data Misuse): “ผู้จัดจำหน่ายหลัก” ตกลงจะไม่ดำเนินกิจกรรมทางธุรกิจ การส่งเสริมการขาย หรือติดต่อเสนอขาย “ผลิตภัณฑ์” โดยตรงแก่ “ผู้ใช้ปลายทาง” ของ “ตัวแทนจำหน่าย” ในลักษณะที่เป็นการแข่งขันทางธุรกิจกับ “ตัวแทนจำหน่าย” ในอาณาเขตที่กำหนด และจะไม่นำข้อมูลรายชื่อ “ผู้ใช้ปลายทาง” ข้อมูลการเสนอราคา หรือข้อมูลทางการค้าใด ๆ ที่ได้รับจาก “ตัวแทนจำหน่าย” ไปใช้ประโยชน์เพื่อตนเอง หรือบุคคลภายนอก หรือนำไปใช้ในลักษณะที่ส่งผลกระทบ ก่อให้เกิดความเสียหาย หรือทำให้ “ตัวแทนจำหน่าย” เสียประโยชน์ทางธุรกิจ ไม่ว่าโดยทางตรง หรือทางอ้อม"],"resellerObligations":["การทำตลาดและการรักษามาตรฐาน: “ตัวแทนจำหน่าย” ต้องทำการตลาด ถ่ายทอดข้อมูลอย่างถูกต้อง ปฏิบัติตามจรรยาบรรณทางธุรกิจ และรักษาสภาพแวดล้อมทางธุรกิจเพื่อส่งเสริมภาพลักษณ์ของ “ผลิตภัณฑ์” และ “ผู้จัดจำหน่ายหลัก”","การปฏิเสธการทำตลาดทับซ้อน (Non-poaching / Territory Limit): “ตัวแทนจำหน่าย” ต้องไม่แสวงหา “ผู้ใช้ปลายทาง” ส่งเสริมการขาย หรือเสนอขาย “ผลิตภัณฑ์” นอกอาณาเขตหรือกลุ่ม “ผู้ใช้ปลายทาง” ที่ได้รับการสงวนสิทธิ์ไว้ให้แก่คู่ค้ารายอื่นโดยชัดแจ้ง เว้นแต่ได้รับความยินยอมเป็นลายลักษณ์อักษรจาก “ผู้จัดจำหน่ายหลัก”"],"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_4', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 4. ลิขสิทธิ์ซอฟต์แวร์ รูปแบบการใช้งาน และการปฏิบัติตามกฎหมาย (Software Licensing & Compliance)', 6, '{"intro":null,"content":null,"bullets":null,"subClauses":["4.1 การรับประกันสิทธิโดย “ผู้จัดจำหน่ายหลัก”: “ผู้จัดจำหน่ายหลัก” รับประกันว่าตนมีสิทธิทางกฎหมายอย่างถูกต้องในการนำเสนอ และจัดจำหน่าย “สิทธิการใช้งาน” ของ “ผลิตภัณฑ์” ดังกล่าวให้แก่ “ตัวแทนจำหน่าย”","4.2 ข้อตกลงกับ “ผู้ใช้ปลายทาง”: “ตัวแทนจำหน่าย” มีหน้าที่ต้องแจ้ง ส่งมอบ และดูแลให้ “ผู้ใช้ปลายทาง” ยินยอมปฏิบัติตามข้อตกลงสิทธิการใช้งานสำหรับ “ผู้ใช้ปลายทาง” (End User License Agreement: EULA) ของ “เจ้าของผลิตภัณฑ์” ทุกครั้งก่อนเริ่มใช้งาน","4.3 การต่อต้านการละเมิดลิขสิทธิ์ (Anti-Piracy & Compliance): “ตัวแทนจำหน่าย” ตกลงจะไม่ทำการคัดลอก ดัดแปลง ทำวิศวกรรมย้อนกลับ (Reverse Engineering) หรือสนับสนุนให้เกิดการละเมิดลิขสิทธิ์ซอฟต์แวร์ และต้องให้ความร่วมมือในการตรวจสอบการใช้งานของ “ผู้ใช้ปลายทาง” เมื่อได้รับการร้องขอ"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_5', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 5. การกำหนดราคา ส่วนลด และเงื่อนไขการชำระเงิน (Pricing, Discounts, and Payment Terms)', 7, '{"intro":null,"content":null,"bullets":null,"subClauses":["5.1 โครงสร้างราคา: “ผู้จัดจำหน่ายหลัก” จะกำหนด และจัดส่งราคาต้นทุน (Cost Price) สำหรับ “ตัวแทนจำหน่าย” และระบุราคาแนะนำสำหรับ “ผู้ใช้ปลายทาง” (End User Price)","5.2 ส่วนลดพิเศษ (Special Discounts): การอนุมัติส่วนลดพิเศษให้อยู่ในวิจารณญาณของ “ผู้จัดจำหน่ายหลัก” โดย “ผู้จัดจำหน่ายหลัก” จะแจ้งยืนยันเป็นลายลักษณ์อักษร (หรือผ่านระบบอิเล็กทรอนิกส์) พร้อมกำหนดระยะเวลาความคุ้มครองของราคานั้น ๆ (Price Validity Period)","5.3 เงื่อนไขการส่งใบแจ้งหนี้ กำหนดระยะเวลาชำระเงิน (Credit Term) และการชำระเงิน: “ผู้จัดจำหน่ายหลัก” จะออกใบแจ้งหนี้เมื่อได้รับใบสั่งซื้อ (Purchase Order) และดำเนินการออก “สิทธิการใช้งาน” เรียบร้อยแล้ว โดยกำหนดระยะเวลาชำระเงิน (Credit Term) ภายใน 30 (สามสิบ) วัน นับแต่วันที่ออกใบแจ้งหนี้ให้กับ “ตัวแทนจำหน่าย” หากชำระล่าช้าต้องเสียดอกเบี้ยร้อยละ 1.5 ต่อเดือน สกุลเงินที่ใช้คือ บาทไทย","5.4 เงื่อนไขอัตราแลกเปลี่ยน (Exchange Rate Condition): การคำนวณราคาเป็นสกุลเงินบาทไทยจะอ้างอิงอัตราแลกเปลี่ยน ณ วันที่ออกใบเสนอราคา โดยตรึงไว้ 30 วัน"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_6', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 6. การบริการหลังการขายและการสนับสนุนทางเทคนิค (Technical Support and Maintenance & SLA)', 8, '{"intro":null,"content":null,"bullets":null,"subClauses":["6.1 ระดับการบริการขั้นแรกของ Reseller (Tier 1 Support): แบ่งตามความพร้อมของตัวแทนจำหน่าย (กรณีมีทีมงาน Tier 1 หรือกรณีส่งต่อ Pass-through ให้ผู้จัดจำหน่ายหลัก)","6.2 ระดับการบริการของ “ผู้จัดจำหน่ายหลัก” และการส่งต่อปัญหา (Tier 2/3 Escalation Path & SLA): อ้างอิง Back-to-Back SLA ของเจ้าของผลิตภัณฑ์","6.3 การต่ออายุสัญญาบริการ (Renewals): “ผู้จัดจำหน่ายหลัก” มีหน้าที่แจ้งเตือนรอบการต่ออายุ “สิทธิการใช้งาน” รายปีล่วงหน้าแก่ “ตัวแทนจำหน่าย” ไม่น้อยกว่า 60 วัน ก่อนวันหมดอายุ"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_7', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 7. การจัดการทรัพย์สินทางปัญญาและการจำกัดความรับผิด (Intellectual Property & Limitation of Liability)', 9, '{"intro":null,"content":null,"bullets":null,"subClauses":["7.1 การชดใช้ค่าเสียหายจากข้อพิพาทลิขสิทธิ์ (Indemnification): “ผู้จัดจำหน่ายหลัก” รับประกันว่า “ผลิตภัณฑ์” ไม่มีการละเมิดทรัพย์สินทางปัญญาของบุคคลภายนอก","7.2 การจำกัดความรับผิด (Limitation of Liability): ความรับผิดชอบสูงสุดทางการเงินจำกัดไว้ไม่เกินยอดเงินรวมที่ชำระให้แก่ผู้จัดจำหน่ายหลักที่ผ่านมาก่อนเกิดเหตุ"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_8', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 8. การรับประกัน (Warranty)', 10, '{"intro":null,"content":null,"bullets":null,"subClauses":["8.1 การรับประกันการทำงานของซอฟต์แวร์: รับประกันว่าทำงานตรงตามคุณลักษณะทางเทคนิคที่ระบุในคู่มือ","8.2 ข้อยกเว้นการรับประกัน: ไม่ครอบคลุมความเสียหายจากการดัดแปลงโดยไม่ได้รับอนุญาต"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_9', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 9. การรักษาความลับข้อมูลและการคุ้มครองข้อมูลส่วนบุคคล (Confidentiality & Data Protection)', 11, '{"intro":null,"content":null,"bullets":null,"subClauses":["9.1 การรักษาความลับทางธุรกิจและการใช้ข้อมูล: รักษาความลับตลอดอายุสัญญาและต่อเนื่อง 2 ปีหลังสิ้นสุดสัญญา","9.2 การคุ้มครองข้อมูลส่วนบุคคล (PDPA): ปฏิบัติตามกฎหมายคุ้มครองข้อมูลส่วนบุคคลอย่างเคร่งครัด"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_10', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 10. ระยะเวลาและการบอกเลิกสัญญา (Term and Termination)', 12, '{"intro":null,"content":null,"bullets":null,"subClauses":["10.1 ระยะเวลาสัญญา: 1 ปี นับแต่วันที่ลงนาม และต่ออายุอัตโนมัติคราวละ 1 ปี","10.2 การบอกเลิกสัญญาแบบมีเหตุผล: บอกเลิกได้ทันทีหากผิดสัญญาและไม่แก้ไขใน 30 วัน หรือล้มละลาย","10.3 การบอกเลิกสัญญาโดยไม่มีเหตุผล: แจ้งล่วงหน้าเป็นลายลักษณ์อักษรไม่น้อยกว่า 60 วัน","10.4 ภาระผูกพันหลังสิ้นสุดสัญญา: ยังคงต้องชำระค่าบริการที่ค้างชำระทั้งหมด และดูแลสิทธิการใช้งานที่มีผลอยู่"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_sec_11', 'tmpl-partner-standard-v1', 'contract_section', 'ข้อ 11. กฎหมายที่ใช้บังคับและกระบวนการระงับข้อพิพาท (Governing Law & Dispute Resolution)', 13, '{"intro":null,"content":null,"bullets":null,"subClauses":["11.1 กฎหมายที่ใช้บังคับ: อยู่ภายใต้กฎหมายแห่งราชอาณาจักรไทย","11.2 กระบวนการระงับข้อพิพาท: เจรจาด้วยมิตรภาพภายใน 30 วัน หากไม่ยุติให้ส่งเรื่องสู่ศาลไทย"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_witness', 'tmpl-partner-standard-v1', 'text_block', 'พยานหลักฐาน', 14, '{"content":"สัญญานี้ทำขึ้นเป็นสองฉบับมีข้อความถูกต้องตรงกัน คู่สัญญาได้อ่านและเข้าใจข้อความโดยรายละเอียดตลอดแล้ว จึงได้ลงลายมือชื่อและประทับตรา (ถ้ามี) ไว้เป็นสำคัญต่อหน้าพยาน"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_partner_signatures', 'tmpl-partner-standard-v1', 'signatures', 'ลงนามแต่งตั้ง', 15, '{"slots":[{"id":"s1","name":"{{authorized_signatory_name}}","role":"ผู้จัดจำหน่ายหลัก (Distributor)"},{"id":"s2","name":"{{customer_signatory_name}}","role":"ตัวแทนจำหน่าย (Reseller)"}]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_dist_header', 'tmpl-distributor-standard-v1', 'header', 'หัวกระดาษ', 0, '{"hasLogo":true,"logoUrl":"/preview.webp","companyName":"{{company_name}}","companyNameEn":"{{company_name_en}}","taxId":"{{company_tax_id}}","address":"{{company_address}}","phone":"{{company_phone}}","email":"{{company_email}}","align":"split"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_dist_title', 'tmpl-distributor-standard-v1', 'doc_title', 'หัวเรื่อง', 1, '{"titleText":"สัญญาแต่งตั้งและจัดจำหน่ายซอฟต์แวร์","subtitleText":"(Distributor and Reseller Master Agreement)","align":"center"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_dist_preamble', 'tmpl-distributor-standard-v1', 'contract_preamble', 'คำนำสัญญาและคู่สัญญา', 2, '{"locationPrefix":"สัญญาฉบับนี้ทำขึ้น ณ","locationText":"{{contract_location}}","datePrefix":"เมื่อวันที่","dateText":"{{contract_date}}","betweenLabel":"ระหว่าง:","party1Text":"{{company_name}} {{company_address}} ซึ่งต่อไปในสัญญานี้จะเรียกว่า “ผู้จัดจำหน่ายหลัก” (Distributor) ฝ่ายหนึ่ง","andLabel":"กับ","party2Text":"{{customer_company}} สำนักงานใหญ่ ตั้งอยู่เลขที่ {{customer_address}} (ซึ่งต่อไปในสัญญานี้จะเรียกว่า “Reseller” หรือ “ตัวแทนจำหน่ายต่อ”) อีกฝ่ายหนึ่ง","recital":"คู่สัญญาทั้งสองฝ่ายตกลงเข้าทำสัญญาแต่งตั้งตัวแทนจำหน่ายต่อ เพื่อทำการตลาด นำเสนอ และจัดจำหน่ายผลิตภัณฑ์ซอฟต์แวร์ และเครื่องมือทางไอที (ซึ่งต่อไปนี้เรียกว่า “ผลิตภัณฑ์”) โดยมีข้อกำหนดและเงื่อนไขดังต่อไปนี้:"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_dist_sec_1', 'tmpl-distributor-standard-v1', 'contract_section', '1. นิยามศัพท์ (Definitions)', 3, '{"intro":null,"content":null,"bullets":null,"subClauses":["1.1. “เจ้าของผลิตภัณฑ์” (Vendor) หมายถึง บุคคล นิติบุคคล หรือผู้พัฒนาซอฟต์แวร์ ซึ่งเป็นผู้ถือครองลิขสิทธิ์ ทรัพย์สินทางปัญญา และสิทธิ์โดยชอบด้วยกฎหมายในตัวผลิตภัณฑ์ซอฟต์แวร์แต่เพียงผู้เดียว (หรือตามสิทธิ์ที่ได้รับอนุญาต)","1.2. “ผู้ใช้ปลายทาง” (End User) หมายถึง บุคคล นิติบุคคล หรือองค์กรที่เป็นผู้ซื้อ ได้รับสิทธิ์ หรือจัดหาผลิตภัณฑ์ซอฟต์แวร์ไปเพื่อวัตถุประสงค์ในการใช้งานจริงภายในองค์กรของตนเอง ไม่ใช่เพื่อวัตถุประสงค์ในการนำไปจำหน่ายต่อหรือให้เช่าช่วง","1.3. “ผลิตภัณฑ์” (Product) หมายถึง ซอฟต์แวร์ ระบบปฏิบัติการ หรือเครื่องมือทางไอที รวมถึง “สิทธิ์การใช้งาน” เอกสารคู่มือ การอัปเดต และแพตช์แก้ไขความปลอดภัย ซึ่ง “ผู้จัดจำหน่ายหลัก” ได้รับสิทธิ์จัดจำหน่ายจาก “เจ้าของผลิตภัณฑ์”","1.4. “สิทธิ์การใช้งาน” (License/Subscription) หมายถึง สิทธิ์ทางกฎหมายที่ “เจ้าของผลิตภัณฑ์” หรือ “ผู้จัดจำหน่ายหลัก” อนุญาตให้ “ตัวแทนจำหน่ายต่อ” นำไปจัดจำหน่ายแก่ “ผู้ใช้ปลายทาง” เพื่อเข้าใช้ “ผลิตภัณฑ์” ตามข้อกำหนดและเงื่อนไขที่กำหนดไว้ในข้อตกลงสิทธิ์การใช้งานสำหรับ “ผู้ใช้ปลายทาง” (EULA)"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_dist_sec_2', 'tmpl-distributor-standard-v1', 'contract_section', '2. ขอบเขตการแต่งตั้งและอาณาเขต (Scope of Appointment & Territory)', 4, '{"intro":null,"content":null,"bullets":null,"subClauses":["2.1. การแต่งตั้งและบทบาทของ “ผู้จัดจำหน่ายหลัก”: “ผู้จัดจำหน่ายหลัก” แต่งตั้งตัวแทนจำหน่ายต่อให้เป็น “ตัวแทนจำหน่ายต่อ” ประเภทแบบไม่ผูกขาด (Non-exclusive)","2.2. สิทธิ์การจำหน่ายของ “ตัวแทนจำหน่ายต่อ”: สามารถจัดจำหน่าย “สิทธิ์การใช้งาน” ของ “ผลิตภัณฑ์” ให้กับ “ผู้ใช้ปลายทาง” เท่านั้น","2.3. อาณาเขตทางภูมิศาสตร์ (Territory): มีสิทธิ์ดำเนินกิจกรรมการขาย การส่งเสริมการขาย และทำการตลาด “ผลิตภัณฑ์” ได้ภายในพื้นที่ ประเทศไทย เท่านั้น"],"distributorObligations":null,"resellerObligations":null,"closing":null}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_dist_witness', 'tmpl-distributor-standard-v1', 'text_block', 'พยานหลักฐาน', 5, '{"content":"เพื่อเป็นหลักฐานแห่งการนี้ คู่สัญญาโดยผู้มีอำนาจลงนามได้อ่านและเข้าใจข้อความในสัญญานี้โดยละเอียดตลอดแล้ว เห็นว่าถูกต้องตรงตามเจตนา จึงได้ลงลายมือชื่อและประทับตราสำคัญ (ถ้ามี) ไว้เป็นสำคัญต่อหน้าพยาน"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO template_blocks (id, template_version_id, block_type, title, sort_order, settings)
VALUES ('b_dist_signatures', 'tmpl-distributor-standard-v1', 'signatures', 'ลงนามคู่สัญญา', 6, '{"slots":[{"id":"s1","name":"{{authorized_signatory_name}}","role":"ผู้จัดจำหน่ายหลัก (Distributor)"},{"id":"s2","name":"{{customer_signatory_name}}","role":"ตัวแทนจำหน่ายต่อ (Reseller)"}]}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO field_profiles (id, org_id, name, profile_type, counterparty_id)
VALUES ('profile-1787103435257', 'org-crestzendo', 'บริษัท เครสท์ เซนโด จำกัด', 'client', NULL)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-counterparty_name', 'profile-1787103435257', 'counterparty_name', 'บริษัท เน็กซ์เจน เทคโนโลยี แอนด์ ดิจิทัล โซลูชันส์ จำกัด')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-counterparty_address', 'profile-1787103435257', 'counterparty_address', '888 อาคารเอ็มไพร์ ทาวเวอร์ ชั้น 21 ถนนสาทรใต้ แขวงยานนาวา เขตสาทร กรุงเทพมหานคร 10120')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-counterparty_signatory_name', 'profile-1787103435257', 'counterparty_signatory_name', 'นายวิทวัส อัครเดชากุล')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-counterparty_signatory_position', 'profile-1787103435257', 'counterparty_signatory_position', 'กรรมการผู้มีอำนาจลงนามผูกพันบริษัท')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-counterparty_signature_text', 'profile-1787103435257', 'counterparty_signature_text', 'นายวิทวัส อัครเดชากุล')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-our_signature_text', 'profile-1787103435257', 'our_signature_text', 'นายศรายุทธ โกสิยารักษ์')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-our_signatory_position', 'profile-1787103435257', 'our_signatory_position', 'CEO/Founder')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-our_signatory_name', 'profile-1787103435257', 'our_signatory_name', 'นายศรายุทธ โกสิยารักษ์')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-our_company_name', 'profile-1787103435257', 'our_company_name', 'บริษัท เครสท์ เซนโด จำกัด')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-contract_location', 'profile-1787103435257', 'contract_location', 'บริษัท เครสท์ เซนโด จำกัด')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-contract_date_day', 'profile-1787103435257', 'contract_date_day', '16')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-contract_date_month', 'profile-1787103435257', 'contract_date_month', 'กันยายน')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-contract_date_year', 'profile-1787103435257', 'contract_date_year', '2564')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103435257-counterparty_registration_number', 'profile-1787103435257', 'counterparty_registration_number', '0107544000108')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profiles (id, org_id, name, profile_type, counterparty_id)
VALUES ('profile-1787103657141', 'org-crestzendo', 'บริษัท เดอะ รีโคฟเวอรี่ แอดไวเซอร์ จำกัด', 'client', NULL)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-counterparty_signatory_name', 'profile-1787103657141', 'counterparty_signatory_name', 'นายศรายุทธ โกสิยารักษ์')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-counterparty_address', 'profile-1787103657141', 'counterparty_address', '45 ซอย โกสุมรวมใจ 37 แขวงดอนเมือง ดอนเมือง กรุงเทพมหานคร 10210')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-counterparty_name', 'profile-1787103657141', 'counterparty_name', 'บริษัท เดอะ รีโคฟเวอรี่ แอดไวเซอร์ จำกัด')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-contract_location', 'profile-1787103657141', 'contract_location', 'บริษัท เดอะ รีโคฟเวอรี่ แอดไวเซอร์ จำกัด')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-our_signatory_name', 'profile-1787103657141', 'our_signatory_name', 'นายศรายุทธ โกสิยารักษ์')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-our_signatory_position', 'profile-1787103657141', 'our_signatory_position', 'CEO/Founder')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-our_company_name', 'profile-1787103657141', 'our_company_name', 'บริษัท เครสท์ เซนโด จำกัด')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-our_signature_text', 'profile-1787103657141', 'our_signature_text', 'นายศรายุทธ โกสิยารักษ์')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-counterparty_signature_text', 'profile-1787103657141', 'counterparty_signature_text', 'นายศรายุทธ โกสิยารักษ์')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-counterparty_signatory_position', 'profile-1787103657141', 'counterparty_signatory_position', 'CEO/Founder')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-contract_date_day', 'profile-1787103657141', 'contract_date_day', '20')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-contract_date_month', 'profile-1787103657141', 'contract_date_month', 'สิงหาคม')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787103657141-contract_date_year', 'profile-1787103657141', 'contract_date_year', '2566')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profiles (id, org_id, name, profile_type, counterparty_id)
VALUES ('profile-1787275130685', 'org-crestzendo', 'CS LoxInfo Public Company Limited.', 'quotation', NULL)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787275130685-bill_to_company', 'profile-1787275130685', 'bill_to_company', 'CS LoxInfo Public Company Limited.')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787275130685-attn_name', 'profile-1787275130685', 'attn_name', 'Sarun Phongpodchanan')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787275130685-end_user', 'profile-1787275130685', 'end_user', ' P.R. Foodland Co., Ltd.')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787275130685-subject', 'profile-1787275130685', 'subject', 'CDNetworks Annual Services (WAF+DDoS+BOT)')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787275130685-am_name', 'profile-1787275130685', 'am_name', ' Narin Rattanavijai / Channel Manager ')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1787275130685-am_phone', 'profile-1787275130685', 'am_phone', '+6682-44-666-95')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profiles (id, org_id, name, profile_type, counterparty_id)
VALUES ('profile-1789096120166', 'org-crestzendo', 'บจก. เทสท์ คลาวด์ ซิสเต็มส์ (สาขา 1)', 'client', NULL)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1789096120166-counterparty_name', 'profile-1789096120166', 'counterparty_name', 'บจก. เทสท์ คลาวด์ ซิสเต็มส์ (สาขา 1)')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1789096120166-branch', 'profile-1789096120166', 'branch', 'สาขา 1')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1789096120166-tax_id', 'profile-1789096120166', 'tax_id', '0105599887766')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1789096120166-address', 'profile-1789096120166', 'address', '456 ถ.สุขุมวิท กทม.')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1789096120166-counterparty_signatory_name', 'profile-1789096120166', 'counterparty_signatory_name', 'นายทดสอบ ระบบดี')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO field_profile_values (id, profile_id, shared_key, field_value)
VALUES ('fpv-profile-1789096120166-counterparty_signatory_position', 'profile-1789096120166', 'counterparty_signatory_position', 'กรรมการผู้จัดการ')
ON CONFLICT (id) DO UPDATE SET field_value = EXCLUDED.field_value;
INSERT INTO documents (id, org_id, template_id, template_version_id, name, status, verification_token, sent_to, last_sent_at, created_at, updated_at)
VALUES ('test-qt-1789096120265', 'org-crestzendo', 'quotation', 'tv-tmpl-quotation-standard-v1', 'ใบเสนอราคาบริการ Cloud & AI 2026', 'draft', 'test-qt-1789096120265', NULL, NULL, '2026-09-11T03:08:40.455Z'::timestamptz, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO documents (id, org_id, template_id, template_version_id, name, status, verification_token, sent_to, last_sent_at, created_at, updated_at)
VALUES ('test-doc-1789096120219', 'org-crestzendo', 'partner', 'tv-tmpl-partner-standard-v1', 'สัญญาคู่ค้าทดสอบ Dual-Write', 'draft', 'VRF-MTWDMXEP-OZYYY', NULL, NULL, '2026-09-11T03:08:40.225Z'::timestamptz, '2026-09-11T03:08:40.225Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO document_activity_logs (id, document_id, action, performed_by, details, comment, created_at)
VALUES ('act-1789096120225', 'test-doc-1789096120219', 'create', 'นายสมชาย ใจดี (ผู้จัดทำ)', 'สร้างเอกสารฉบับร่าง', NULL, '2026-09-11T03:08:40.225Z'::timestamptz)
ON CONFLICT (id) DO NOTHING;
INSERT INTO documents (id, org_id, template_id, template_version_id, name, status, verification_token, sent_to, last_sent_at, created_at, updated_at)
VALUES ('doc-1788331547618', 'org-crestzendo', 'notification', 'tv-tmpl-notification-standard-v1', 'NotificationLetter_02-09-2569.pdf', 'draft', 'VRF-MTJQFHEQ-T2D3O', NULL, NULL, '2026-09-02T06:45:47.617Z'::timestamptz, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO document_activity_logs (id, document_id, action, performed_by, details, comment, created_at)
VALUES ('act-1788331547618', 'doc-1788331547618', 'create', 'นายสมชาย ใจดี (ผู้จัดทำ)', 'สร้างเอกสารฉบับร่าง', NULL, '2026-09-02T06:45:47.617Z'::timestamptz)
ON CONFLICT (id) DO NOTHING;
INSERT INTO documents (id, org_id, template_id, template_version_id, name, status, verification_token, sent_to, last_sent_at, created_at, updated_at)
VALUES ('doc-1787812462153', 'org-crestzendo', 'quotation', 'tv-tmpl-quotation-standard-v1', 'CZ26080001.pdf', 'sent', 'doc-1787812462153', 'sirawit.pec@gmail.com', NULL, '2026-08-27T06:34:22.153Z'::timestamptz, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO documents (id, org_id, template_id, template_version_id, name, status, verification_token, sent_to, last_sent_at, created_at, updated_at)
VALUES ('qt-1787638573675', 'org-crestzendo', 'quotation', 'tv-tmpl-quotation-standard-v1', 'ใบเสนอราคา CZ2608063', 'draft', 'qt-1787638573675', NULL, NULL, '2026-08-25T06:16:13.675Z'::timestamptz, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO documents (id, org_id, template_id, template_version_id, name, status, verification_token, sent_to, last_sent_at, created_at, updated_at)
VALUES ('qt-1787631227758', 'org-crestzendo', 'quotation', 'tv-tmpl-quotation-standard-v1', 'ใบเสนอราคา CZ2608063', 'draft', 'qt-1787631227758', NULL, NULL, '2026-08-25T04:13:47.758Z'::timestamptz, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO documents (id, org_id, template_id, template_version_id, name, status, verification_token, sent_to, last_sent_at, created_at, updated_at)
VALUES ('doc-1787207517799', 'org-crestzendo', 'partner', 'tv-tmpl-partner-standard-v1', 'PartnerAgreement_20-08-2569.pdf', 'sent', 'doc-1787207517799', 'sirawit.pec@gmail.com', NULL, '2026-08-20T06:31:57.799Z'::timestamptz, '2026-08-20T06:31:57.799Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO documents (id, org_id, template_id, template_version_id, name, status, verification_token, sent_to, last_sent_at, created_at, updated_at)
VALUES ('doc-1787192788708', 'org-crestzendo', 'partner', 'tv-tmpl-partner-standard-v1', 'PartnerAgreement_20-08-2569.pdf', 'draft', 'doc-1787192788708', NULL, NULL, '2026-08-20T02:26:28.708Z'::timestamptz, '2026-08-20T02:26:28.709Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO documents (id, org_id, template_id, template_version_id, name, status, verification_token, sent_to, last_sent_at, created_at, updated_at)
VALUES ('doc-1787128888165', 'org-crestzendo', 'partner', 'tv-tmpl-partner-standard-v1', 'PartnerAgreement_19-08-2569.pdf', 'sent', 'doc-1787128888165', 'sirawit.pec@gmail.com', NULL, '2026-08-19T08:41:28.165Z'::timestamptz, CURRENT_TIMESTAMP)
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-doc_no', 'doc-1788331547618', 'doc_no', 'TRAC-2609001', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-doc_date', 'doc-1788331547618', 'doc_date', '01 กันยายน 2569 / September 01, 2026', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-recipient', 'doc-1788331547618', 'recipient', 'ท่านคู่ค้าและลูกค้าผู้มีอุปการคุณ / Valued Business Partners', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-subject', 'doc-1788331547618', 'subject', 'แจ้งเปลี่ยนแปลงที่อยู่สำนักงานใหญ่ / Change of Head Office Address', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-effective_date', 'doc-1788331547618', 'effective_date', '16 กันยายน 2569', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-old_address_th', 'doc-1788331547618', 'old_address_th', '45 ซอยโกสุมรวมใจ 37 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-old_address_en', 'doc-1788331547618', 'old_address_en', '45 Soi Kosum Ruam Chai 37, Don Mueang, Don Mueang, Bangkok 10210, Thailand', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-new_address_th', 'doc-1788331547618', 'new_address_th', '18 ซอยโกสุมรวมใจ 35 แยก 4 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-new_address_en', 'doc-1788331547618', 'new_address_en', '18 Soi Kosum Ruam Chai 35 Yaek 4, Don Mueang, Don Mueang, Bangkok 10210, Thailand', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-signatory_name', 'doc-1788331547618', 'signatory_name', 'นายศรายุทธ  โกสิยารักษ์', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-signatory_position', 'doc-1788331547618', 'signatory_position', 'กรรมการผู้จัดการ / CEO', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-effective_date_en', 'doc-1788331547618', 'effective_date_en', 'September 16, 2026', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1788331547618-effective_date_badge', 'doc-1788331547618', 'effective_date_badge', '(มีผล 16 ก.ย. 2569 / Effective Sept 16, 2026):', NULL, '2026-09-10T02:40:42.224Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-id', 'doc-1787812462153', 'id', 'qt-1787638573675', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-quotationNo', 'doc-1787812462153', 'quotationNo', 'CZ26080001', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-name', 'doc-1787812462153', 'name', 'ใบเสนอราคา CZ2608063', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-templateId', 'doc-1787812462153', 'templateId', 'quotation', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-templateName', 'doc-1787812462153', 'templateName', 'ใบเสนอราคา (Quotation)', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-quotationDate', 'doc-1787812462153', 'quotationDate', '25 Aug 2026', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-priceValidity', 'doc-1787812462153', 'priceValidity', '24 Sept 2026', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-deliveryTerm', 'doc-1787812462153', 'deliveryTerm', '7 days', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-creditTerm', 'doc-1787812462153', 'creditTerm', '30 days', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-vatRate', 'doc-1787812462153', 'vatRate', NULL, 7, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-remarks', 'doc-1787812462153', 'remarks', 'Payment: Annually', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-senderName', 'doc-1787812462153', 'senderName', 'Narin Rattanavijai(PoP)', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-senderPhone', 'doc-1787812462153', 'senderPhone', '082 44 666 95', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-createdBy', 'doc-1787812462153', 'createdBy', 'Admin', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-createdAt', 'doc-1787812462153', 'createdAt', '2026-08-25T06:16:13.675Z', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-updatedAt', 'doc-1787812462153', 'updatedAt', '2026-08-27T02:05:21.118Z', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-status', 'doc-1787812462153', 'status', 'draft', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-sentTo', 'doc-1787812462153', 'sentTo', NULL, NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-remarksList', 'doc-1787812462153', 'remarksList', 'Payment: Annually', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-specialDiscount', 'doc-1787812462153', 'specialDiscount', NULL, NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-senderPosition', 'doc-1787812462153', 'senderPosition', 'Executive Assistant - Technology & Governance', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787812462153-senderEmail', 'doc-1787812462153', 'senderEmail', 'narin@crestzendo.com', NULL, '2026-08-27T06:34:22.153Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-id', 'qt-1787638573675', 'id', 'qt-1787638573675', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-quotationNo', 'qt-1787638573675', 'quotationNo', 'CZ26080001', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-name', 'qt-1787638573675', 'name', 'ใบเสนอราคา CZ2608063', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-templateId', 'qt-1787638573675', 'templateId', 'quotation', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-templateName', 'qt-1787638573675', 'templateName', 'ใบเสนอราคา (Quotation)', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-quotationDate', 'qt-1787638573675', 'quotationDate', '25 Aug 2026', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-priceValidity', 'qt-1787638573675', 'priceValidity', '24 Sept 2026', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-deliveryTerm', 'qt-1787638573675', 'deliveryTerm', '7 days', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-creditTerm', 'qt-1787638573675', 'creditTerm', '30 days', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-vatRate', 'qt-1787638573675', 'vatRate', NULL, 7, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-remarks', 'qt-1787638573675', 'remarks', 'Payment: Annually', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-senderName', 'qt-1787638573675', 'senderName', 'Narin Rattanavijai(PoP)', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-senderPhone', 'qt-1787638573675', 'senderPhone', '082 44 666 95', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-createdBy', 'qt-1787638573675', 'createdBy', 'Admin', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-createdAt', 'qt-1787638573675', 'createdAt', '2026-08-25T06:16:13.675Z', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-updatedAt', 'qt-1787638573675', 'updatedAt', '2026-08-27T02:05:21.118Z', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-status', 'qt-1787638573675', 'status', 'draft', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-sentTo', 'qt-1787638573675', 'sentTo', NULL, NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-remarksList', 'qt-1787638573675', 'remarksList', 'Payment: Annually', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-specialDiscount', 'qt-1787638573675', 'specialDiscount', NULL, NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-senderPosition', 'qt-1787638573675', 'senderPosition', 'Executive Assistant - Technology & Governance', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787638573675-senderEmail', 'qt-1787638573675', 'senderEmail', 'narin@crestzendo.com', NULL, '2026-08-27T02:05:21.118Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-id', 'qt-1787631227758', 'id', 'qt-1787631227758', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-quotationNo', 'qt-1787631227758', 'quotationNo', 'CZ2608063', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-name', 'qt-1787631227758', 'name', 'ใบเสนอราคา CZ2608063', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-templateId', 'qt-1787631227758', 'templateId', 'quotation', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-templateName', 'qt-1787631227758', 'templateName', 'ใบเสนอราคา (Quotation)', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-quotationDate', 'qt-1787631227758', 'quotationDate', '25 Aug 2026', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-priceValidity', 'qt-1787631227758', 'priceValidity', '24 Sept 2026', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-deliveryTerm', 'qt-1787631227758', 'deliveryTerm', '7 days', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-creditTerm', 'qt-1787631227758', 'creditTerm', '30 days', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-vatRate', 'qt-1787631227758', 'vatRate', NULL, 7, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-remarks', 'qt-1787631227758', 'remarks', 'Payment: Annually', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-senderName', 'qt-1787631227758', 'senderName', 'Narin Rattanavajij (PoP)', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-senderPhone', 'qt-1787631227758', 'senderPhone', '+6682-44-666-95', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-createdBy', 'qt-1787631227758', 'createdBy', 'Admin', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-createdAt', 'qt-1787631227758', 'createdAt', '2026-08-25T04:13:47.758Z', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-updatedAt', 'qt-1787631227758', 'updatedAt', '2026-08-25T04:13:47.758Z', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-status', 'qt-1787631227758', 'status', 'draft', NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-qt-1787631227758-sentTo', 'qt-1787631227758', 'sentTo', NULL, NULL, '2026-08-25T04:13:47.758Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787207517799-contract_date_day', 'doc-1787207517799', 'contract_date_day', '16', NULL, '2026-08-20T06:31:57.799Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787207517799-contract_date_month', 'doc-1787207517799', 'contract_date_month', 'กันยายน', NULL, '2026-08-20T06:31:57.799Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787207517799-contract_date_year', 'doc-1787207517799', 'contract_date_year', '2564', NULL, '2026-08-20T06:31:57.799Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787207517799-reseller_name', 'doc-1787207517799', 'reseller_name', 'บริษัท เน็กซ์เจน เทคโนโลยี แอนด์ ดิจิทัล โซลูชันส์ จำกัด', NULL, '2026-08-20T06:31:57.799Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787207517799-reseller_registration_number', 'doc-1787207517799', 'reseller_registration_number', '0107544000108', NULL, '2026-08-20T06:31:57.799Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787207517799-reseller_address', 'doc-1787207517799', 'reseller_address', '888 อาคารเอ็มไพร์ ทาวเวอร์ ชั้น 21 ถนนสาทรใต้ แขวงยานนาวา เขตสาทร กรุงเทพมหานคร 10120', NULL, '2026-08-20T06:31:57.799Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787207517799-reseller_signatory_name', 'doc-1787207517799', 'reseller_signatory_name', 'นายวิทวัส อัครเดชากุล', NULL, '2026-08-20T06:31:57.799Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787207517799-reseller_signatory_position', 'doc-1787207517799', 'reseller_signatory_position', 'กรรมการผู้มีอำนาจลงนามผูกพันบริษัท', NULL, '2026-08-20T06:31:57.799Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787192788708-contract_date_day', 'doc-1787192788708', 'contract_date_day', '16', NULL, '2026-08-20T02:26:28.709Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787192788708-contract_date_month', 'doc-1787192788708', 'contract_date_month', 'กันยายน', NULL, '2026-08-20T02:26:28.709Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787192788708-contract_date_year', 'doc-1787192788708', 'contract_date_year', '2564', NULL, '2026-08-20T02:26:28.709Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787192788708-reseller_name', 'doc-1787192788708', 'reseller_name', 'บริษัท เน็กซ์เจน เทคโนโลยี แอนด์ ดิจิทัล โซลูชันส์ จำกัด', NULL, '2026-08-20T02:26:28.709Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787192788708-reseller_registration_number', 'doc-1787192788708', 'reseller_registration_number', '0107544000108', NULL, '2026-08-20T02:26:28.709Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787192788708-reseller_address', 'doc-1787192788708', 'reseller_address', '888 อาคารเอ็มไพร์ ทาวเวอร์ ชั้น 21 ถนนสาทรใต้ แขวงยานนาวา เขตสาทร กรุงเทพมหานคร 10120', NULL, '2026-08-20T02:26:28.709Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787192788708-reseller_signatory_name', 'doc-1787192788708', 'reseller_signatory_name', 'นายวิทวัส อัครเดชากุล', NULL, '2026-08-20T02:26:28.709Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787192788708-reseller_signatory_position', 'doc-1787192788708', 'reseller_signatory_position', 'กรรมการผู้มีอำนาจลงนามผูกพันบริษัท', NULL, '2026-08-20T02:26:28.709Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787128888165-contract_date_day', 'doc-1787128888165', 'contract_date_day', '16', NULL, '2026-08-19T08:41:28.165Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787128888165-contract_date_month', 'doc-1787128888165', 'contract_date_month', 'กันยายน', NULL, '2026-08-19T08:41:28.165Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787128888165-contract_date_year', 'doc-1787128888165', 'contract_date_year', '2564', NULL, '2026-08-19T08:41:28.165Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787128888165-reseller_name', 'doc-1787128888165', 'reseller_name', 'บริษัท เน็กซ์เจน เทคโนโลยี แอนด์ ดิจิทัล โซลูชันส์ จำกัด', NULL, '2026-08-19T08:41:28.165Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787128888165-reseller_registration_number', 'doc-1787128888165', 'reseller_registration_number', '0107544000108', NULL, '2026-08-19T08:41:28.165Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787128888165-reseller_address', 'doc-1787128888165', 'reseller_address', 'เลขที่ 888 อาคารเอ็มไพร์ ทาวเวอร์ ชั้น 21 ถนนสาทรใต้ แขวงยานนาวา เขตสาทร กรุงเทพมหานคร 10120', NULL, '2026-08-19T08:41:28.165Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787128888165-reseller_signatory_name', 'doc-1787128888165', 'reseller_signatory_name', 'นายวิทวัส อัครเดชากุล', NULL, '2026-08-19T08:41:28.165Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-doc-1787128888165-reseller_signatory_position', 'doc-1787128888165', 'reseller_signatory_position', 'กรรมการผู้มีอำนาจลงนามผูกพันบริษัท', NULL, '2026-08-19T08:41:28.165Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-doc-1789096120219-company_name', 'test-doc-1789096120219', 'company_name', 'บริษัท เครสท์ เซนโด จำกัด', NULL, '2026-09-11T03:08:40.226Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-doc-1789096120219-customer_name', 'test-doc-1789096120219', 'customer_name', 'นายทดสอบ ระบบดี', NULL, '2026-09-11T03:08:40.226Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-doc-1789096120219-customer_company', 'test-doc-1789096120219', 'customer_company', 'บจก. เทสท์ คลาวด์ ซิสเต็มส์', NULL, '2026-09-11T03:08:40.226Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-doc-1789096120219-contract_date', 'test-doc-1789096120219', 'contract_date', '2026-09-11', NULL, '2026-09-11T03:08:40.226Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-doc-1789096120219-commission_rate', 'test-doc-1789096120219', 'commission_rate', NULL, 15, '2026-09-11T03:08:40.226Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-doc-1789096120219-is_active', 'test-doc-1789096120219', 'is_active', NULL, NULL, '2026-09-11T03:08:40.226Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-id', 'test-qt-1789096120265', 'id', 'test-qt-1789096120265', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-quotationNo', 'test-qt-1789096120265', 'quotationNo', 'CZ26099999', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-revision', 'test-qt-1789096120265', 'revision', '01', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-name', 'test-qt-1789096120265', 'name', 'ใบเสนอราคาบริการ Cloud & AI 2026', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-templateId', 'test-qt-1789096120265', 'templateId', 'quotation', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-templateName', 'test-qt-1789096120265', 'templateName', 'ใบเสนอราคา (Quotation)', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-quotationDate', 'test-qt-1789096120265', 'quotationDate', '11/9/2569', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-priceValidity', 'test-qt-1789096120265', 'priceValidity', '30 Days', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-deliveryTerm', 'test-qt-1789096120265', 'deliveryTerm', 'Within 15-30 Days', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-creditTerm', 'test-qt-1789096120265', 'creditTerm', '30 Days', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-billTo', 'test-qt-1789096120265', 'billTo', NULL, NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-vatRate', 'test-qt-1789096120265', 'vatRate', NULL, 7, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-remarks', 'test-qt-1789096120265', 'remarks', NULL, NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-senderName', 'test-qt-1789096120265', 'senderName', NULL, NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-senderPhone', 'test-qt-1789096120265', 'senderPhone', NULL, NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-createdBy', 'test-qt-1789096120265', 'createdBy', 'Admin', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-createdAt', 'test-qt-1789096120265', 'createdAt', '2026-09-11T03:08:40.455Z', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-updatedAt', 'test-qt-1789096120265', 'updatedAt', '2026-09-11T03:08:40.455Z', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-status', 'test-qt-1789096120265', 'status', 'draft', NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_field_values (id, document_id, field_key, text_value, number_value, updated_at)
VALUES ('dfv-test-qt-1789096120265-sentTo', 'test-qt-1789096120265', 'sentTo', NULL, NULL, '2026-09-11T03:08:40.455Z'::timestamptz)
ON CONFLICT (id) DO UPDATE SET text_value = EXCLUDED.text_value;
INSERT INTO document_tables (id, document_id, table_name, currency, vat_rate, subtotal, discount_amount, vat_amount, grand_total)
VALUES ('tbl-doc-1787812462153', 'doc-1787812462153', 'รายการสินค้า', 'THB', 7, 0, 0, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_tables (id, document_id, table_name, currency, vat_rate, subtotal, discount_amount, vat_amount, grand_total)
VALUES ('tbl-qt-1787638573675', 'qt-1787638573675', 'รายการสินค้า', 'THB', 7, 0, 0, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_tables (id, document_id, table_name, currency, vat_rate, subtotal, discount_amount, vat_amount, grand_total)
VALUES ('tbl-qt-1787631227758', 'qt-1787631227758', 'รายการสินค้า', 'THB', 7, 0, 0, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_tables (id, document_id, table_name, currency, vat_rate, subtotal, discount_amount, vat_amount, grand_total)
VALUES ('dtbl-test-qt-1789096120265', 'test-qt-1789096120265', 'รายการสินค้า/บริการ (Quotation Items)', 'THB', 7, 0, 0, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_tables (id, document_id, table_name, currency, vat_rate, subtotal, discount_amount, vat_amount, grand_total)
VALUES ('tbl-test-qt-1789096120265', 'test-qt-1789096120265', 'รายการสินค้า', 'THB', 7, 0, 0, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('row-tbl-doc-1787812462153-0', 'tbl-doc-1787812462153', 'item', 0, NULL, NULL, 1, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('row-tbl-doc-1787812462153-1', 'tbl-doc-1787812462153', 'item', 1, NULL, NULL, 1, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('row-tbl-qt-1787638573675-0', 'tbl-qt-1787638573675', 'item', 0, NULL, NULL, 1, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('row-tbl-qt-1787638573675-1', 'tbl-qt-1787638573675', 'item', 1, NULL, NULL, 1, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('row-tbl-qt-1787631227758-0', 'tbl-qt-1787631227758', 'item', 0, NULL, NULL, 1, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('row-tbl-qt-1787631227758-1', 'tbl-qt-1787631227758', 'item', 1, NULL, NULL, 1, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('row-tbl-qt-1787631227758-2', 'tbl-qt-1787631227758', 'item', 2, NULL, NULL, 1, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('dtr-test-qt-1789096120265-1', 'dtbl-test-qt-1789096120265', 'item', 1, 'Cloud Server Enterprise Tier', NULL, 2, 25000, 50000)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('dtr-test-qt-1789096120265-2', 'dtbl-test-qt-1789096120265', 'item', 2, 'AI DocBuilder Enterprise License', NULL, 1, 50000, 50000)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('row-tbl-test-qt-1789096120265-0', 'tbl-test-qt-1789096120265', 'item', 0, NULL, NULL, 1, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO document_table_rows (id, table_id, row_type, sort_order, item_description, item_details, quantity, unit_price, line_total)
VALUES ('row-tbl-test-qt-1789096120265-1', 'tbl-test-qt-1789096120265', 'item', 1, NULL, NULL, 1, 0, 0)
ON CONFLICT (id) DO NOTHING;
INSERT INTO sent_history (id, document_id, document_name, recipient_email, subject, sent_by, status, action_type, format, channel, sent_at)
VALUES ('history-1787812462439', 'qt-1787638573675', 'CZ26080001.pdf', 'sirawit.pec@gmail.com', 'CZ26080001.pdf', 'Admin', 'sent', 'email', NULL, 'email', '2026-08-27T06:34:22.439Z'::timestamptz)
ON CONFLICT (id) DO NOTHING;
INSERT INTO sent_history (id, document_id, document_name, recipient_email, subject, sent_by, status, action_type, format, channel, sent_at)
VALUES ('history-1787207517811', 'doc-1787192788708', 'PartnerAgreement_20-08-2569.pdf', 'sirawit.pec@gmail.com', 'PartnerAgreement_20-08-2569.pdf', 'Admin', 'sent', 'email', NULL, 'email', '2026-08-20T06:31:57.811Z'::timestamptz)
ON CONFLICT (id) DO NOTHING;
INSERT INTO sent_history (id, document_id, document_name, recipient_email, subject, sent_by, status, action_type, format, channel, sent_at)
VALUES ('history-1787128888176', 'doc-1787128888165', 'PartnerAgreement_19-08-2569.pdf', 'sirawit.pec@gmail.com', 'PartnerAgreement_19-08-2569.pdf', 'Admin', 'sent', 'email', NULL, 'email', '2026-08-19T08:41:28.176Z'::timestamptz)
ON CONFLICT (id) DO NOTHING;
INSERT INTO sent_history (id, document_id, document_name, recipient_email, subject, sent_by, status, action_type, format, channel, sent_at)
VALUES ('history-1787128342315', 'doc-1787128888165', 'PartnerAgreement_19-08-2569.pdf', 'sirawit.pec@gmail.com', 'PartnerAgreement_19-08-2569.pdf', 'Admin', 'sent', 'email', NULL, 'email', '2026-08-19T08:32:22.315Z'::timestamptz)
ON CONFLICT (id) DO NOTHING;
INSERT INTO sent_history (id, document_id, document_name, recipient_email, subject, sent_by, status, action_type, format, channel, sent_at)
VALUES ('history-1787125902243', 'doc-1787128888165', 'PartnerAgreement_19-08-2569.pdf', 'sirawit.pec@gmail.com', 'PartnerAgreement_19-08-2569.pdf', 'Admin', 'sent', 'email', NULL, 'email', '2026-08-19T07:51:42.243Z'::timestamptz)
ON CONFLICT (id) DO NOTHING;
INSERT INTO sent_history (id, document_id, document_name, recipient_email, subject, sent_by, status, action_type, format, channel, sent_at)
VALUES ('history-1787125495740', 'doc-1787128888165', 'PartnerAgreement_19-08-2569.pdf', 'sirawit.pec@gmail.com', 'PartnerAgreement_19-08-2569.pdf', 'Admin', 'sent', 'email', NULL, 'email', '2026-08-19T07:44:55.740Z'::timestamptz)
ON CONFLICT (id) DO NOTHING;
INSERT INTO sent_history (id, document_id, document_name, recipient_email, subject, sent_by, status, action_type, format, channel, sent_at)
VALUES ('history-1787122422801', 'doc-1787128888165', 'PartnerAgreement_19-08-2569.pdf', 'sirawit.pec@gmail.com', 'PartnerAgreement_19-08-2569.pdf', 'Admin', 'sent', 'email', NULL, 'email', '2026-08-19T06:53:42.801Z'::timestamptz)
ON CONFLICT (id) DO NOTHING;
INSERT INTO sent_history (id, document_id, document_name, recipient_email, subject, sent_by, status, action_type, format, channel, sent_at)
VALUES ('history-1787120846132', 'doc-1787128888165', 'PartnerAgreement_19-08-2569.pdf', 'sirawit.pec@gmail.com', 'PartnerAgreement_19-08-2569.pdf', 'Admin', 'sent', 'email', NULL, 'email', '2026-08-19T06:27:26.132Z'::timestamptz)
ON CONFLICT (id) DO NOTHING;
INSERT INTO settings (id, org_id, key, value)
VALUES ('set-account', 'org-crestzendo', 'account', '{"fullName":"สิรวิทย์ เพชรจำรัส","email":"keem@crestzendo.com","role":"Owner / Admin","avatar":"","twoFactorEnabled":true}'::jsonb)
ON CONFLICT (id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (id, org_id, key, value)
VALUES ('set-preferences', 'org-crestzendo', 'preferences', '{"theme":"light","language":"en","dateFormat":"buddhist","defaultExportFormat":"pdf"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (id, org_id, key, value)
VALUES ('set-organization', 'org-crestzendo', 'organization', '{"name":"บริษัท เครสท์ เซนโด จำกัด","nameEn":"Crest Zendo Co., Ltd.","taxId":"0105558073755","branch":"สำนักงานใหญ่","address":"8/40 The Connect 37, ซอยช่างอากาศอุทิศ 10 แยก 1-2 แขวงดอนเมือง เขตดอนเมือง กรุงเทพมหานคร 10210","phone":"02-123-4567","email":"contact@crestzendo.com","website":"https://crestzendo.com","logo":""}'::jsonb)
ON CONFLICT (id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (id, org_id, key, value)
VALUES ('set-sessions', 'org-crestzendo', 'sessions', '[{"id":"sess-current","device":"Chrome บน Windows 11","ip":"127.0.0.1","location":"Bangkok, Thailand","current":true,"lastActive":"Active now"},{"id":"sess-mobile","device":"Safari บน iPhone 15 Pro","ip":"182.52.41.22","location":"Bangkok, Thailand","current":false,"lastActive":"2 ชั่วโมงที่แล้ว"}]'::jsonb)
ON CONFLICT (id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (id, org_id, key, value)
VALUES ('set-language', 'org-crestzendo', 'language', '"en"'::jsonb)
ON CONFLICT (id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (id, org_id, key, value)
VALUES ('set-currency', 'org-crestzendo', 'currency', '"THB"'::jsonb)
ON CONFLICT (id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO settings (id, org_id, key, value)
VALUES ('set-theme', 'org-crestzendo', 'theme', '"light"'::jsonb)
ON CONFLICT (id) DO UPDATE SET value = EXCLUDED.value;
