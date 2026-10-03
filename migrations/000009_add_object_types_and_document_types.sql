-- ==============================================================================
-- MIGRATION: 000009_add_object_types_and_document_types.sql
-- 3NF Master Tables for Document Types & Document Object Types
-- ==============================================================================

-- 1. Create document_types (Master for Core Document Formats)
CREATE TABLE IF NOT EXISTS document_types (
    id VARCHAR(50) PRIMARY KEY, -- 'word', 'excel', 'slide', 'artwork'
    name VARCHAR(100) NOT NULL,
    thai_name VARCHAR(100) NOT NULL,
    default_preset_id VARCHAR(50) REFERENCES page_presets(id) ON DELETE SET NULL,
    icon VARCHAR(50) DEFAULT 'FileText',
    color VARCHAR(50) DEFAULT '#5542F6',
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Seed core document formats
INSERT INTO document_types (id, name, thai_name, default_preset_id, icon, color, description)
VALUES 
    ('word', 'Document (Word)', 'เอกสาร (Word)', 'a4-portrait', 'FileText', '#5542F6', 'เอกสารแนวตั้ง เช่น สัญญา ใบเสนอราคา ใบเสร็จ จดหมายราชการ (A4)'),
    ('excel', 'Spread Sheet (Excel)', 'ตารางคำนวณ (Excel)', 'sheet-excel', 'Table', '#059669', 'ตารางบัญชีสินค้า รายการแจกแจงราคา พร้อมสูตรคำนวณอัตโนมัติ'),
    ('slide', 'Slides (16:9 Presentation)', 'งานนำเสนอ (Slides)', 'slide-16-9', 'Presentation', '#D97706', 'สไลด์ Pitch Deck แนะนำบริษัท หรือรายงานผลงานสัดส่วน 16:9'),
    ('artwork', 'Art Work', 'อาร์ตเวิร์ก (Art Work)', 'artwork-custom', 'SlidersHorizontal', '#2563EB', 'สำหรับโปสเตอร์ (Poster), แบนเนอร์, ป้ายประกาศ หรือกำหนดขนาดอิสระ')
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name,
    thai_name = EXCLUDED.thai_name,
    default_preset_id = EXCLUDED.default_preset_id,
    icon = EXCLUDED.icon,
    color = EXCLUDED.color,
    description = EXCLUDED.description;

-- 2. Create document_object_types (Master for Canvas Elements & Data Fields)
CREATE TABLE IF NOT EXISTS document_object_types (
    id VARCHAR(50) PRIMARY KEY, -- 'text', 'rich_text', 'number', 'currency', 'date', 'image', 'signature', 'table', 'sheet_grid', 'qr_code', 'barcode'
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'content', -- 'content', 'data', 'media', 'security'
    default_settings JSONB,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Seed object types
INSERT INTO document_object_types (id, name, category, description)
VALUES 
    ('text', 'ข้อความสั้น (Short Text)', 'content', 'ชื่อ นามสกุล หัวข้อ หรือข้อความบรรทัดเดียว'),
    ('rich_text', 'ข้อความยาว/ย่อหน้า (Rich Paragraph)', 'content', 'เนื้อหาข้อสัญญา เงื่อนไข หรือบทความหลายบรรทัด'),
    ('number', 'ตัวเลข (Numeric)', 'data', 'จำนวนชิ้น ปริมาณ อัตราส่วน'),
    ('currency', 'ยอดเงิน (Currency / Money)', 'data', 'ยอดเงินรวม ภาษีมูลค่าเพิ่ม ส่วนลด (ทศนิยม 2-4 ตำแหน่ง)'),
    ('date', 'วันที่และเวลา (Date / Timestamp)', 'data', 'วันที่ออกเอกสาร วันครบกำหนด วันที่ทำสัญญา'),
    ('image', 'รูปภาพ/โลโก้ (Image / Asset)', 'media', 'รูปภาพประกอบ โลโก้องค์กร แบนเนอร์'),
    ('signature', 'ลายเซ็น/ตราประทับ (Signature / Seal)', 'security', 'รูปลายเซ็นกรรมการ ผู้มีอำนาจลงนาม ตราประทับบริษัท'),
    ('table', 'ตารางรายการสินค้า (Line Items Table)', 'data', 'ตารางแจกแจงรายการสินค้า ปริมาณ ราคาต่อหน่วย ยอดรวม'),
    ('sheet_grid', 'กริดสเปรดชีต (Spreadsheet Grid)', 'data', 'ตารางคำนวณชีตแบบหลายเซลล์ พร้อมสูตร Excel'),
    ('qr_code', 'คิวอาร์โค้ดตรวจสอบ (Verification QR)', 'security', 'QR Code สำหรับสแกนตรวจสอบเอกสารแท้บนระบบ'),
    ('barcode', 'บาร์โค้ด (Barcode)', 'security', 'บาร์โค้ดรหัสเอกสาร Code 128 / EAN'),
    ('page_number', 'เลขหน้าเอกสาร (Page Numbering)', 'content', 'แสดงเลขหน้าปัจจุบันและจำนวนหน้าทั้งหมด เช่น หน้า 1 จาก 3')
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name,
    category = EXCLUDED.category,
    description = EXCLUDED.description;

-- 3. Update document_masters to reference document_types(id)
ALTER TABLE document_masters 
ADD COLUMN IF NOT EXISTS document_type_id VARCHAR(50) REFERENCES document_types(id) ON DELETE SET NULL;

-- 4. Update document_object_values to reference document_object_types(id) and add page_number
ALTER TABLE document_object_values 
ADD COLUMN IF NOT EXISTS object_type_id VARCHAR(50) REFERENCES document_object_types(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS page_number INT DEFAULT 1;

-- 5. Create index for fast object querying per page
CREATE INDEX IF NOT EXISTS idx_doc_obj_val_page ON document_object_values(document_id, page_number);
CREATE INDEX IF NOT EXISTS idx_doc_obj_val_type ON document_object_values(object_type_id);
CREATE INDEX IF NOT EXISTS idx_doc_masters_doc_type_id ON document_masters(document_type_id);
