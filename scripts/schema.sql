-- ==============================================================================
-- DocBuilder Database Schema (Golden Standard)
-- PostgreSQL DDL Script
-- Compatible with PostgreSQL 14+, Supabase, Neon
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Organizations
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

-- 2. Users
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

-- 3. Organization Signatories
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

-- 4. Counterparties (Clients / Partners / Vendors)
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

-- 5. Counterparty Signatories
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

-- 6. Categories
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

-- 7. Templates
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

-- 8. Template Versions
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

ALTER TABLE templates 
    ADD CONSTRAINT fk_templates_current_version 
    FOREIGN KEY (current_version_id) 
    REFERENCES template_versions(id) 
    DEFERRABLE INITIALLY DEFERRED;

-- 9. Template Blocks
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

-- 10. Template Fields
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

-- 11. Template Table Columns
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

-- 12. Custom Tokens
CREATE TABLE IF NOT EXISTS custom_tokens (
    id VARCHAR(64) PRIMARY KEY,
    token_key VARCHAR(100) NOT NULL UNIQUE,
    label VARCHAR(255) NOT NULL,
    category VARCHAR(100) DEFAULT 'ทั่วไป',
    scope VARCHAR(50) DEFAULT 'global',
    field_type VARCHAR(50) DEFAULT 'text',
    example_value TEXT,
    description TEXT,
    created_by_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 13. Documents
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

-- 14. Document Field Values (EAV Model)
CREATE TABLE IF NOT EXISTS document_field_values (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    template_field_id VARCHAR(64) REFERENCES template_fields(id) ON DELETE SET NULL,
    field_key VARCHAR(100) NOT NULL,
    text_value TEXT,
    number_value DECIMAL(18,4),
    date_value DATE,
    boolean_value BOOLEAN,
    json_value JSONB,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_doc_field UNIQUE (document_id, template_field_id)
);

-- 15. Document Tables
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

-- 16. Document Table Rows
CREATE TABLE IF NOT EXISTS document_table_rows (
    id VARCHAR(64) PRIMARY KEY,
    table_id VARCHAR(64) NOT NULL REFERENCES document_tables(id) ON DELETE CASCADE,
    row_type VARCHAR(50) DEFAULT 'item',
    sort_order INT DEFAULT 0,
    item_description TEXT NOT NULL,
    item_details TEXT,
    quantity DECIMAL(12,4) DEFAULT 1.0000,
    unit_name VARCHAR(50) DEFAULT 'หน่วย',
    unit_price DECIMAL(18,4) DEFAULT 0.0000,
    discount_amount DECIMAL(18,4) DEFAULT 0.0000,
    line_total DECIMAL(18,4) DEFAULT 0.0000,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 17. Document Assets
CREATE TABLE IF NOT EXISTS document_assets (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    asset_type VARCHAR(50) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size_bytes BIGINT,
    mime_type VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 18. Document Activity Logs
CREATE TABLE IF NOT EXISTS document_activity_logs (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    performed_by VARCHAR(255),
    details TEXT,
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 19. Document Approval Steps
CREATE TABLE IF NOT EXISTS document_approval_steps (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    step_number INT NOT NULL,
    step_name VARCHAR(255) NOT NULL,
    assigned_role VARCHAR(100),
    assigned_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    assigned_user_name VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending',
    signed_at TIMESTAMPTZ,
    comment TEXT
);

-- 20. Notifications
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

-- 21. Sent History
CREATE TABLE IF NOT EXISTS sent_history (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) REFERENCES documents(id) ON DELETE SET NULL,
    document_name VARCHAR(255),
    recipient_email VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    message TEXT,
    sent_by VARCHAR(255),
    status VARCHAR(50) DEFAULT 'success',
    sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 22. Settings
CREATE TABLE IF NOT EXISTS settings (
    id VARCHAR(64) PRIMARY KEY,
    org_id VARCHAR(64) REFERENCES organizations(id) ON DELETE CASCADE,
    key VARCHAR(100) NOT NULL UNIQUE,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_documents_org_id ON documents(org_id);
CREATE INDEX IF NOT EXISTS idx_documents_status ON documents(status);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_doc_field_values_doc_id ON document_field_values(document_id);
CREATE INDEX IF NOT EXISTS idx_template_versions_template_id ON template_versions(template_id);
CREATE INDEX IF NOT EXISTS idx_document_tables_doc_id ON document_tables(document_id);
CREATE INDEX IF NOT EXISTS idx_document_table_rows_table_id ON document_table_rows(table_id);
