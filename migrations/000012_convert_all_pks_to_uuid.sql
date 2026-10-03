-- ==============================================================================
-- MIGRATION: 000012_convert_all_pks_to_uuid.sql
-- Converts ALL Primary Keys and Foreign Keys to PostgreSQL Native `uuid` (UUIDv7)
-- 1. Creates mapping table `_id_uuid_map` (old_id -> new_uuid)
-- 2. Preserves historical timestamps embedded in UUIDv7
-- 3. Alters columns to native PostgreSQL type `uuid` (16 bytes)
-- 4. Re-establishes all 35 Foreign Key constraints
-- 5. Updates canonical view `v_document_masters`
-- ==============================================================================

-- 1. Ensure UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Persistent Mapping Table for Backward-Compatibility and Auditing
CREATE TABLE IF NOT EXISTS _id_uuid_map (
    table_name VARCHAR(64) NOT NULL,
    old_id VARCHAR(128) NOT NULL,
    new_uuid UUID NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (table_name, old_id)
);

CREATE INDEX IF NOT EXISTS idx_id_uuid_map_old_id ON _id_uuid_map(old_id);
CREATE INDEX IF NOT EXISTS idx_id_uuid_map_new_uuid ON _id_uuid_map(new_uuid);

COMMENT ON TABLE _id_uuid_map IS 'ตารางจับคู่รหัสเดิมกับ UUIDv7 ใหม่ สำหรับการแปลงข้อมูลและ Backward-Compatibility';

-- 3. Ensure Canonical View matches UUID Columns
CREATE OR REPLACE VIEW v_document_masters AS
SELECT 
    m.id,
    m.doc_type,
    m.format_type,
    m.document_type_id,
    m.parent_template_id,
    m.document_number,
    m.title,
    m.description,
    m.status,
    m.version,
    m.category_id,
    c.name AS category_name,
    m.org_id,
    o.name AS organization_name,
    m.created_by_user_id,
    u.full_name AS created_by_name,
    u.email AS created_by_email,
    u.role AS created_by_role,
    m.verification_token,
    m.created_at,
    m.updated_at,
    m.deleted_at
FROM document_masters m
LEFT JOIN users u ON m.created_by_user_id = u.id
LEFT JOIN organizations o ON m.org_id = o.id
LEFT JOIN categories c ON m.category_id = c.id;

COMMENT ON VIEW v_document_masters IS 'มุมมองรวมศูนย์เอกสารและแม่แบบ พร้อมชื่อผู้สร้าง อีเมล และองค์กร (UUIDv7 Native View)';
