-- ==============================================================================
-- MIGRATION: 000003_add_jsonb_storage.sql
-- Add JSONB columns for full canvas layout, document values, and workflow tracking
-- ==============================================================================

-- 1. Templates table enhancements (Canvas pages, spreadsheet data, margins, badges)
ALTER TABLE templates 
    ADD COLUMN IF NOT EXISTS pages JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS sheet_data JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS margin JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS icon VARCHAR(100),
    ADD COLUMN IF NOT EXISTS badge VARCHAR(100);

-- 2. Documents table enhancements (Values payload, activity logs, approval chain)
ALTER TABLE documents
    ADD COLUMN IF NOT EXISTS template_name VARCHAR(255),
    ADD COLUMN IF NOT EXISTS created_by VARCHAR(255),
    ADD COLUMN IF NOT EXISTS values JSONB DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS activity_logs JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS approval_chain JSONB DEFAULT '[]'::jsonb;
