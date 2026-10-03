-- Migration 000015: Enhance document_types and create template_pages & document_pages
-- Organizes document structure into clean page-level entities with HTML/JSONB

-- 1. Enhance document_types with technical and dimension specifications
ALTER TABLE document_types 
ADD COLUMN IF NOT EXISTS layout_engine VARCHAR(50) DEFAULT 'paged_canvas',
ADD COLUMN IF NOT EXISTS default_width INT DEFAULT 794,
ADD COLUMN IF NOT EXISTS default_height INT DEFAULT 1123,
ADD COLUMN IF NOT EXISTS unit VARCHAR(10) DEFAULT 'mm',
ADD COLUMN IF NOT EXISTS default_orientation VARCHAR(20) DEFAULT 'portrait',
ADD COLUMN IF NOT EXISTS supported_exports JSONB NOT NULL DEFAULT '["pdf"]'::jsonb,
ADD COLUMN IF NOT EXISTS allowed_object_types JSONB NOT NULL DEFAULT '[]'::jsonb;

-- Clean names and set specifications
UPDATE document_types 
SET name = 'Document',
    thai_name = 'เอกสาร',
    layout_engine = 'paged_canvas',
    default_width = 794,
    default_height = 1123,
    unit = 'mm',
    default_orientation = 'portrait',
    supported_exports = '["pdf", "docx"]'::jsonb,
    allowed_object_types = '["text", "rich_text", "table", "signature", "image", "qr_code", "page_number"]'::jsonb
WHERE code = 'word';

UPDATE document_types 
SET name = 'Presentation',
    thai_name = 'งานนำเสนอ',
    layout_engine = 'paged_canvas',
    default_width = 1280,
    default_height = 720,
    unit = 'px',
    default_orientation = 'landscape',
    supported_exports = '["pptx", "pdf"]'::jsonb,
    allowed_object_types = '["text", "rich_text", "image", "shape", "table", "page_number"]'::jsonb
WHERE code = 'slide';

UPDATE document_types 
SET name = 'Spreadsheet',
    thai_name = 'ตารางคำนวณ',
    layout_engine = 'spreadsheet_grid',
    default_width = 1200,
    default_height = 800,
    unit = 'px',
    default_orientation = 'landscape',
    supported_exports = '["xlsx", "csv", "pdf"]'::jsonb,
    allowed_object_types = '["sheet_grid", "currency", "number", "formula"]'::jsonb
WHERE code = 'excel';

UPDATE document_types 
SET name = 'Artwork',
    thai_name = 'อาร์ตเวิร์ก',
    layout_engine = 'freeform',
    default_width = 1200,
    default_height = 1200,
    unit = 'px',
    default_orientation = 'square',
    supported_exports = '["png", "pdf", "jpg", "svg"]'::jsonb,
    allowed_object_types = '["text", "image", "shape", "vector", "qr_code"]'::jsonb
WHERE code = 'artwork';

-- 2. Create template_pages table
CREATE TABLE IF NOT EXISTS template_pages (
    id UUID PRIMARY KEY,
    template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    page_number INT NOT NULL,
    page_name VARCHAR(100),
    styles JSONB NOT NULL DEFAULT '{}'::jsonb,
    values JSONB NOT NULL DEFAULT '{}'::jsonb,
    content_html TEXT,
    canvas_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_template_pages_num UNIQUE(template_id, page_number)
);
CREATE INDEX IF NOT EXISTS idx_template_pages_tmpl_id ON template_pages(template_id);

-- 3. Create document_pages table
CREATE TABLE IF NOT EXISTS document_pages (
    id UUID PRIMARY KEY,
    document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    page_number INT NOT NULL,
    page_name VARCHAR(100),
    styles JSONB NOT NULL DEFAULT '{}'::jsonb,
    values JSONB NOT NULL DEFAULT '{}'::jsonb,
    content_html TEXT,
    canvas_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_document_pages_num UNIQUE(document_id, page_number)
);
CREATE INDEX IF NOT EXISTS idx_document_pages_doc_id ON document_pages(document_id);
