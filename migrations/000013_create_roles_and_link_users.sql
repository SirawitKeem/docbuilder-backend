-- Migration 000013: Create roles table (RBAC) and link users table
-- 1 User = 1 Role architecture with Native PostgreSQL UUID (UUIDv7)

-- 1. Create roles table
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    display_name_th VARCHAR(100) NOT NULL,
    display_name_en VARCHAR(100) NOT NULL,
    description TEXT,
    hierarchy_level INT NOT NULL,
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_system BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Seed standard system roles
INSERT INTO roles (id, name, display_name_th, display_name_en, description, hierarchy_level, permissions, is_system)
VALUES
    ('01a0fa9c-0db9-74e5-9879-45ab12c71056', 'owner', 'เจ้าของระบบ', 'Workspace Owner', 'สิทธิ์สูงสุดทุกอย่างในระบบ จัดการตั้งค่าองค์กร การเงิน และสมาชิกทั้งหมด', 1, '{"all": true, "manage_organization": true, "manage_billing": true, "manage_users": true, "manage_roles": true, "manage_templates": true, "manage_documents": true, "approve_documents": true, "view_documents": true}'::jsonb, true),
    ('01a0fa9c-0dbe-7465-a961-de730dd597a2', 'admin', 'ผู้ดูแลระบบ', 'Administrator', 'จัดการผู้ใช้ เทมเพลต และตรวจสอบเอกสารทั้งหมดในองค์กร', 2, '{"manage_organization": false, "manage_billing": false, "manage_users": true, "manage_roles": false, "manage_templates": true, "manage_documents": true, "approve_documents": true, "view_documents": true}'::jsonb, true),
    ('01a0fa9c-0dbe-74b3-8a9e-2227e232583d', 'template_manager', 'ผู้จัดการแม่แบบ', 'Template Manager', 'สร้าง แก้ไข และเผยแพร่แม่แบบเอกสาร (Master Templates)', 3, '{"manage_templates": true, "create_documents": true, "view_documents": true}'::jsonb, true),
    ('01a0fa9c-0dbe-7401-8a9e-4063d441e85d', 'creator', 'ผู้จัดทำเอกสาร', 'Document Creator', 'นำแม่แบบไปสร้างเอกสาร จัดการเอกสารของตนเอง และส่งขออนุมัติ', 4, '{"manage_templates": false, "create_documents": true, "edit_own_documents": true, "view_documents": true}'::jsonb, true),
    ('01a0fa9c-0dbe-7419-b85b-56780899081c', 'approver', 'ผู้อนุมัติเอกสาร', 'Document Approver', 'ตรวจสอบเอกสาร ลงนามอนุมัติ (Sign & Approve) หรือส่งกลับแก้ไข', 5, '{"approve_documents": true, "sign_documents": true, "view_documents": true}'::jsonb, true),
    ('01a0fa9c-0dbe-747c-9a35-d2c42d8eeec3', 'viewer', 'ผู้ดูเอกสาร', 'Document Viewer', 'ดูและดาวน์โหลดเอกสารได้อย่างเดียว (Read-Only)', 6, '{"view_documents": true, "download_documents": true}'::jsonb, true)
ON CONFLICT (name) DO UPDATE SET
    display_name_th = EXCLUDED.display_name_th,
    display_name_en = EXCLUDED.display_name_en,
    description = EXCLUDED.description,
    hierarchy_level = EXCLUDED.hierarchy_level,
    permissions = EXCLUDED.permissions,
    updated_at = now();

-- 3. Add role_id column to users if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'role_id'
    ) THEN
        ALTER TABLE users ADD COLUMN role_id UUID REFERENCES roles(id);
    END IF;
END $$;

-- 4. Update existing users to owner role
UPDATE users 
SET role_id = '01a0fa9c-0db9-74e5-9879-45ab12c71056', role = 'owner', updated_at = now()
WHERE role_id IS NULL;

-- 5. Enforce NOT NULL constraint
ALTER TABLE users ALTER COLUMN role_id SET NOT NULL;
