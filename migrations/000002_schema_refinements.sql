-- ==============================================================================
-- MIGRATION: 000002_schema_refinements.sql
-- Fix critical constraints, foreign keys, triggers, and multi-tenant integrity
-- ==============================================================================

-- 1. Fix settings: change global unique key to per-organization unique (org_id, key)
ALTER TABLE settings DROP CONSTRAINT IF EXISTS settings_key_key;
ALTER TABLE settings DROP CONSTRAINT IF EXISTS uq_org_settings_key;
ALTER TABLE settings ADD CONSTRAINT uq_org_settings_key UNIQUE (org_id, key);

-- 2. Fix Circular FK between templates and template_versions (Add ON DELETE SET NULL)
ALTER TABLE templates DROP CONSTRAINT IF EXISTS fk_templates_current_version;
ALTER TABLE templates 
    ADD CONSTRAINT fk_templates_current_version 
    FOREIGN KEY (current_version_id) 
    REFERENCES template_versions(id) 
    ON DELETE SET NULL 
    DEFERRABLE INITIALLY DEFERRED;

-- 3. Fix document_field_values unique constraint (use document_id, field_key)
ALTER TABLE document_field_values DROP CONSTRAINT IF EXISTS uq_doc_field;
ALTER TABLE document_field_values DROP CONSTRAINT IF EXISTS uq_doc_field_key;
ALTER TABLE document_field_values ADD CONSTRAINT uq_doc_field_key UNIQUE (document_id, field_key);

-- 4. Fix custom_tokens: add org_id support
ALTER TABLE custom_tokens 
    ADD COLUMN IF NOT EXISTS org_id VARCHAR(64) REFERENCES organizations(id) ON DELETE CASCADE;

-- 5. Add CHECK constraints for enum-like fields
ALTER TABLE documents DROP CONSTRAINT IF EXISTS chk_doc_status;
ALTER TABLE documents ADD CONSTRAINT chk_doc_status 
    CHECK (status IS NULL OR LOWER(status) IN ('draft', 'pending_approval', 'approved', 'sent', 'rejected', 'archived'));

ALTER TABLE documents DROP CONSTRAINT IF EXISTS chk_doc_watermark;
ALTER TABLE documents ADD CONSTRAINT chk_doc_watermark 
    CHECK (watermark IS NULL OR LOWER(watermark) IN ('none', 'draft', 'copy', 'confidential'));

ALTER TABLE document_table_rows DROP CONSTRAINT IF EXISTS chk_row_type;
ALTER TABLE document_table_rows ADD CONSTRAINT chk_row_type 
    CHECK (row_type IS NULL OR LOWER(row_type) IN ('header', 'item', 'subtotal', 'discount', 'tax', 'total', 'note'));

-- 6. Add Auto-update Trigger function and triggers for updated_at
CREATE OR REPLACE FUNCTION set_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DO $$
DECLARE
    tbl text;
BEGIN
    FOR tbl IN 
        SELECT table_name 
        FROM information_schema.columns 
        WHERE column_name = 'updated_at' 
          AND table_schema = 'public'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_update_%I ON %I', tbl, tbl);
        EXECUTE format('CREATE TRIGGER trg_update_%I BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION set_updated_at_column()', tbl, tbl);
    END LOOP;
END $$;

-- 7. Add missing foreign key indexes
CREATE INDEX IF NOT EXISTS idx_templates_org_id ON templates(org_id);
CREATE INDEX IF NOT EXISTS idx_counterparties_org_id ON counterparties(org_id);
CREATE INDEX IF NOT EXISTS idx_users_org_id ON users(org_id);
CREATE INDEX IF NOT EXISTS idx_template_fields_version_id ON template_fields(template_version_id);
CREATE INDEX IF NOT EXISTS idx_doc_activity_logs_doc_id ON document_activity_logs(document_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
