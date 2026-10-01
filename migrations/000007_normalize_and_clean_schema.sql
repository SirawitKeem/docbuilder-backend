-- ==============================================================================
-- MIGRATION: 000007_normalize_and_clean_schema.sql
-- Database Normalization (1NF, 2NF, 3NF), Category Cleanup & Hardcode Removal
-- ==============================================================================

-- 1. Add is_system to categories so system/custom status is driven by DB, not hardcoded arrays
ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_system BOOLEAN DEFAULT FALSE;

-- 2. Mark standard canonical categories in PostgreSQL
UPDATE categories 
SET is_system = TRUE, badge = 'มาตรฐาน' 
WHERE id IN ('quotation', 'nda', 'partner', 'distributor', 'notification', 'company-announcement');

-- 3. Resolve duplicate announcement category:
-- Transfer any references from empty 'cat-1788946775522' to 'company-announcement', then delete empty category
UPDATE templates SET category_id = 'company-announcement' WHERE category_id = 'cat-1788946775522';
DELETE FROM categories WHERE id = 'cat-1788946775522';

-- Update 'company-announcement' display names to be uniform and clean
UPDATE categories 
SET name = 'ประกาศบริษัท', 
    full_name = 'ประกาศบริษัท (Company Announcement)', 
    badge = 'มาตรฐาน',
    is_system = TRUE,
    color = 'amber',
    icon = 'FileText'
WHERE id = 'company-announcement';

-- 4. 1NF Normalization: Create document_approvals table to eliminate nested JSON approval_chain
CREATE TABLE IF NOT EXISTS document_approvals (
    id VARCHAR(64) PRIMARY KEY,
    document_id VARCHAR(64) NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    step_order INT NOT NULL DEFAULT 1,
    approver_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    approver_name VARCHAR(255),
    approver_email VARCHAR(255),
    role VARCHAR(100),
    status VARCHAR(50) DEFAULT 'pending',
    comment TEXT,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_doc_approvals_doc_id ON document_approvals(document_id);

-- 5. Delete orphaned duplicate template 'notification' (keeping canonical 'tmpl-notification-standard')
DELETE FROM templates 
WHERE id = 'notification' 
  AND NOT EXISTS (SELECT 1 FROM documents WHERE template_id = 'notification');

-- 6. Ensure proper indexes for relational lookups
CREATE INDEX IF NOT EXISTS idx_templates_category_id ON templates(category_id);
CREATE INDEX IF NOT EXISTS idx_templates_deleted_at ON templates(deleted_at);
CREATE INDEX IF NOT EXISTS idx_documents_template_id ON documents(template_id);
CREATE INDEX IF NOT EXISTS idx_documents_deleted_at ON documents(deleted_at);
