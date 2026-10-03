-- ==============================================================================
-- MIGRATION: 000008_realignment_document_master_3nf.sql
-- Database Normalization (1NF, 2NF, 3NF):
-- 1NF: Atomic values, eliminate multi-valued JSON arrays (timelines, approvals, object values)
-- 2NF: Eliminate partial dependencies by separating page_presets and object_styles
-- 3NF: Eliminate transitive dependencies (FK references without duplicated attributes)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Create page_presets (2NF Master Table for Canvas Dimensions)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS page_presets (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    display_type VARCHAR(50) NOT NULL DEFAULT 'document',
    width_px INT NOT NULL,
    height_px INT NOT NULL,
    width_mm DECIMAL(8, 2),
    height_mm DECIMAL(8, 2),
    aspect_ratio VARCHAR(20),
    is_standard BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Seed standard presets
INSERT INTO page_presets (id, name, display_type, width_px, height_px, width_mm, height_mm, aspect_ratio, is_standard)
VALUES 
    ('a4-portrait', 'Document (Word) - A4 แนวตั้ง', 'document', 794, 1123, 210.00, 297.00, '1:1.414', TRUE),
    ('a4-landscape', 'Document (Word) - A4 แนวนอน', 'document', 1123, 794, 297.00, 210.00, '1.414:1', TRUE),
    ('slide-16-9', 'Slides (16:9 Presentation)', 'slide', 1280, 720, 338.67, 190.50, '16:9', TRUE),
    ('sheet-excel', 'Spread Sheet (Excel)', 'sheet', 1200, 800, NULL, NULL, 'grid', TRUE),
    ('artwork-square', 'Art Work - จัตุรัส (1200 × 1200)', 'artwork', 1200, 1200, 317.50, 317.50, '1:1', TRUE),
    ('artwork-custom', 'Art Work (กำหนดขนาดอิสระ)', 'artwork', 1000, 1000, NULL, NULL, 'custom', FALSE)
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name, 
    display_type = EXCLUDED.display_type, 
    width_px = EXCLUDED.width_px, 
    height_px = EXCLUDED.height_px;

-- ------------------------------------------------------------------------------
-- 2. Create document_masters (Primary Unified Entity for Templates & Documents)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS document_masters (
    id VARCHAR(64) PRIMARY KEY,
    doc_type VARCHAR(20) NOT NULL DEFAULT 'document', -- 'template' or 'document'
    format_type VARCHAR(50) NOT NULL DEFAULT 'word',  -- 'word', 'slide', 'excel', 'artwork'
    parent_template_id VARCHAR(64) REFERENCES templates(id) ON DELETE SET NULL,
    version INT NOT NULL DEFAULT 1,
    category_id VARCHAR(64) REFERENCES categories(id) ON DELETE SET NULL,
    org_id VARCHAR(64) REFERENCES organizations(id) ON DELETE CASCADE,
    document_number VARCHAR(100),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    created_by_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    created_by_name VARCHAR(255) DEFAULT 'สิรวิทย์ เพชรจำรัส',
    created_by_email VARCHAR(255) DEFAULT 'keem@crestzendo.com',
    verification_token VARCHAR(100) UNIQUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_doc_masters_doc_type ON document_masters(doc_type);
CREATE INDEX IF NOT EXISTS idx_doc_masters_status ON document_masters(status);
CREATE INDEX IF NOT EXISTS idx_doc_masters_category ON document_masters(category_id);
CREATE INDEX IF NOT EXISTS idx_doc_masters_created_by ON document_masters(created_by_user_id);

-- ------------------------------------------------------------------------------
-- 3. Create document_object_styles (2NF: Style, Margins & Canvas Presets)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS document_object_styles (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL,
    preset_id VARCHAR(50) REFERENCES page_presets(id) ON DELETE SET NULL,
    page_width_px INT NOT NULL DEFAULT 794,
    page_height_px INT NOT NULL DEFAULT 1123,
    unit VARCHAR(10) DEFAULT 'mm',
    orientation VARCHAR(20) DEFAULT 'portrait',
    margin_top_mm DECIMAL(6, 2) DEFAULT 15.0,
    margin_bottom_mm DECIMAL(6, 2) DEFAULT 15.0,
    margin_left_mm DECIMAL(6, 2) DEFAULT 15.0,
    margin_right_mm DECIMAL(6, 2) DEFAULT 15.0,
    primary_color VARCHAR(50) DEFAULT '#5542F6',
    background_color VARCHAR(50) DEFAULT '#FFFFFF',
    font_family VARCHAR(100) DEFAULT 'Noto Sans Thai',
    has_watermark BOOLEAN DEFAULT FALSE,
    watermark_text VARCHAR(100),
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_doc_styles_doc_id ON document_object_styles(document_id);

-- ------------------------------------------------------------------------------
-- 4. Create document_object_values (1NF: Atomic Field Values)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS document_object_values (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL,
    object_key VARCHAR(100) NOT NULL,
    object_type VARCHAR(50) NOT NULL DEFAULT 'text',
    text_value TEXT,
    numeric_value DECIMAL(18, 4),
    json_value JSONB,
    sort_order INT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_doc_obj_val_doc_id ON document_object_values(document_id);
CREATE INDEX IF NOT EXISTS idx_doc_obj_val_key ON document_object_values(document_id, object_key);

-- ------------------------------------------------------------------------------
-- 5. Create document_authorizations (3NF Email-Based Access Control)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS document_authorizations (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL,
    user_email VARCHAR(255) NOT NULL,
    permission_level VARCHAR(50) NOT NULL DEFAULT 'viewer', -- 'owner', 'editor', 'approver', 'viewer', 'signer'
    granted_by_email VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_doc_auth_doc_id ON document_authorizations(document_id);
CREATE INDEX IF NOT EXISTS idx_doc_auth_email ON document_authorizations(user_email);

-- ------------------------------------------------------------------------------
-- 6. Create document_timelines (1NF Atomic Event & Export History)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS document_timelines (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- 'created', 'updated', 'exported', 'printed', 'sent', 'approved', 'rejected'
    actor_name VARCHAR(255) DEFAULT 'สิรวิทย์ เพชรจำรัส',
    actor_email VARCHAR(255) DEFAULT 'keem@crestzendo.com',
    channel VARCHAR(50) DEFAULT 'web_app',
    export_format VARCHAR(20),
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_doc_timelines_doc_id ON document_timelines(document_id);
CREATE INDEX IF NOT EXISTS idx_doc_timelines_event ON document_timelines(event_type);

-- ------------------------------------------------------------------------------
-- 7. Drop empty, redundant legacy tables (Clean Schema)
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS template_table_columns CASCADE;
DROP TABLE IF EXISTS template_fields CASCADE;
DROP TABLE IF EXISTS field_profile_templates CASCADE;
DROP TABLE IF EXISTS template_permissions CASCADE;
DROP TABLE IF EXISTS template_shares CASCADE;
