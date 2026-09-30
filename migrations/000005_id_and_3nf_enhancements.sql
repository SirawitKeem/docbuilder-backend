-- ==============================================================================
-- DocBuilder Migration 000005: ID Standardization, 3NF Indexes & Constraints
-- ==============================================================================

-- 1. Ensure categories has org_id for multi-tenancy isolation
ALTER TABLE categories 
    ADD COLUMN IF NOT EXISTS org_id VARCHAR(64) DEFAULT 'org-crestzendo' REFERENCES organizations(id) ON DELETE CASCADE;

-- 2. Remap legacy template IDs in documents to canonical IDs
UPDATE documents SET template_id = 'tmpl-quotation-standard' WHERE template_id = 'quotation';
UPDATE documents SET template_id = 'tmpl-partner-standard' WHERE template_id = 'partner';
UPDATE documents SET template_id = 'tmpl-distributor-standard' WHERE template_id = 'distributor';
UPDATE documents SET template_id = 'tmpl-nda-standard' WHERE template_id = 'nda';

-- 3. Remove redundant duplicate templates superseded by canonical tmpl-*-standard
DELETE FROM templates 
WHERE id IN ('quotation', 'partner', 'distributor', 'nda')
  AND EXISTS (
    SELECT 1 FROM templates t2 
    WHERE t2.id = 'tmpl-' || templates.id || '-standard'
  );

-- 4. Composite Unique Constraints (Prevent name collisions within the same tenant)
CREATE UNIQUE INDEX IF NOT EXISTS uq_categories_org_name 
    ON categories(org_id, lower(trim(name)));

CREATE UNIQUE INDEX IF NOT EXISTS uq_templates_org_cat_name 
    ON templates(org_id, category_id, lower(trim(name))) 
    WHERE deleted_at IS NULL;

-- 5. B-Tree Indexes for 3NF Foreign Keys & Rapid Filtering
CREATE INDEX IF NOT EXISTS idx_documents_org_id ON documents(org_id);
CREATE INDEX IF NOT EXISTS idx_documents_template_id ON documents(template_id);
CREATE INDEX IF NOT EXISTS idx_documents_counterparty_id ON documents(counterparty_id);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_templates_org_id ON templates(org_id);
CREATE INDEX IF NOT EXISTS idx_templates_category_id ON templates(category_id);
CREATE INDEX IF NOT EXISTS idx_templates_created_at ON templates(created_at DESC);

-- 6. GIN Indexes for Fast Unstructured JSONB Queries (Physical Level Optimization)
CREATE INDEX IF NOT EXISTS idx_documents_values_gin ON documents USING GIN (values);
CREATE INDEX IF NOT EXISTS idx_templates_pages_gin ON templates USING GIN (pages);
