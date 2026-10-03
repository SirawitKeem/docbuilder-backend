-- ==============================================================================
-- MIGRATION: 000011_user_uuid_and_view.sql
-- 1. Standardize User Primary Key to UUIDv7 (replacing legacy string 'usr-admin')
-- 2. Update all Foreign Key references (document_masters, documents, notifications, etc.)
-- 3. Create canonical view `v_document_masters` for clear, readable relations in pgAdmin
-- ==============================================================================

DO $$
DECLARE
    v_old_user_id VARCHAR(64) := 'usr-admin';
    v_new_user_uuid VARCHAR(64) := '01a0fa5c-e3e4-7013-a331-93a672d1fc20';
    v_user_email VARCHAR(255) := 'keem@crestzendo.com';
    v_user_name VARCHAR(255) := 'สิรวิทย์ เพชรจำรัส';
    v_org_id VARCHAR(64) := 'org-crestzendo';
BEGIN
    -- 1. Ensure new UUID user exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = v_new_user_uuid) THEN
        IF EXISTS (SELECT 1 FROM users WHERE id = v_old_user_id) THEN
            -- Insert duplicate user with temp email to swap
            INSERT INTO users (id, org_id, full_name, email, role, two_factor_enabled, created_at, updated_at)
            SELECT v_new_user_uuid, org_id, full_name, email || '.temp', role, two_factor_enabled, created_at, CURRENT_TIMESTAMP
            FROM users WHERE id = v_old_user_id;
        ELSE
            INSERT INTO users (id, org_id, full_name, email, role, two_factor_enabled, created_at, updated_at)
            VALUES (v_new_user_uuid, v_org_id, v_user_name, v_user_email || '.temp', 'Owner / Admin', FALSE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        END IF;
    END IF;

    -- 2. Re-point foreign keys from old ID to new UUIDv7
    UPDATE document_masters SET created_by_user_id = v_new_user_uuid WHERE created_by_user_id = v_old_user_id;
    UPDATE documents SET created_by_user_id = v_new_user_uuid WHERE created_by_user_id = v_old_user_id;
    UPDATE templates SET created_by_user_id = v_new_user_uuid WHERE created_by_user_id = v_old_user_id;
    UPDATE categories SET created_by_user_id = v_new_user_uuid WHERE created_by_user_id = v_old_user_id;
    UPDATE counterparties SET created_by_user_id = v_new_user_uuid WHERE created_by_user_id = v_old_user_id;
    UPDATE field_profiles SET created_by_user_id = v_new_user_uuid WHERE created_by_user_id = v_old_user_id;
    UPDATE notifications SET user_id = v_new_user_uuid WHERE user_id = v_old_user_id;
    UPDATE document_approvals SET approver_user_id = v_new_user_uuid WHERE approver_user_id = v_old_user_id;

    -- 3. Delete old legacy record and restore proper email
    DELETE FROM users WHERE id = v_old_user_id;
    UPDATE users SET email = v_user_email WHERE id = v_new_user_uuid;

END $$;

-- 4. Canonical View: v_document_masters
-- Gives human-readable names and emails directly alongside UUIDs in pgAdmin and BI tools
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

COMMENT ON VIEW v_document_masters IS 'มุมมองรวมศูนย์เอกสารและแม่แบบ พร้อมชื่อผู้สร้าง อีเมล และองค์กร (Human-Readable 3NF View)';
COMMENT ON COLUMN document_masters.created_by_user_id IS 'FK ชี้ไปยัง users.id (UUIDv7 ผู้สร้างเอกสาร)';
COMMENT ON COLUMN document_masters.org_id IS 'FK ชี้ไปยัง organizations.id (องค์กรเจ้าของเอกสาร สำหรับ Tenant Isolation)';
