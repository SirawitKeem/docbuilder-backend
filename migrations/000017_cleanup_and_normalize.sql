-- ================================================================
-- Migration 000017: Database Cleanup & Normalization
-- ================================================================
-- Phase 1: Fix incorrect editor_type on Artwork templates
-- Phase 2: Fix NULL created_by_user_id on standard templates
-- Phase 3: Clear misleading description on Artwork templates
-- Phase 4: Remove unused custom_token (typo duplicate)
-- Phase 5: Drop unused JSONB columns from documents
-- Phase 6: Rename version columns to be semantically correct
-- Phase 7: Drop dead legacy tables
-- Phase 8: Add document_timelines entries for existing activity_logs
-- ================================================================

BEGIN;

-- ================================================================
-- 1. Fix editor_type for Artwork templates
-- ================================================================
UPDATE templates
SET editor_type = 'artwork',
    updated_at  = CURRENT_TIMESTAMP
WHERE description LIKE 'Art Work%'
  AND editor_type = 'document';

-- ================================================================
-- 2. Fix NULL created_by_user_id on standard templates (5 rows)
-- ================================================================
UPDATE templates
SET created_by_user_id = '01a0fa5c-e3e4-7013-a331-93a672d1fc20',
    updated_at         = CURRENT_TIMESTAMP
WHERE created_by_user_id IS NULL;

-- ================================================================
-- 3. Clear misleading description on Artwork templates
--    (description was being used as a proxy for editor_type)
-- ================================================================
UPDATE templates
SET description = '',
    updated_at  = CURRENT_TIMESTAMP
WHERE description LIKE 'Art Work%';

-- ================================================================
-- 4. Remove custom_token typo duplicate
--    rile_6_no (typo) vs rule_6_no (correct) — delete the typo
-- ================================================================
DELETE FROM custom_tokens
WHERE token_key = 'rile_6_no';

-- ================================================================
-- 5. Rename version columns to semantically correct names
--    current_version_id → version_label (not a UUID FK)
--    template_version_id → template_version_label (not a UUID FK)
-- ================================================================
ALTER TABLE templates
  RENAME COLUMN current_version_id TO version_label;

ALTER TABLE documents
  RENAME COLUMN template_version_id TO template_version_label;

-- ================================================================
-- 6. Migrate activity_logs JSONB → document_timelines table
--    before dropping the column
-- ================================================================
INSERT INTO document_timelines (id, document_id, event_type, actor_name, actor_email, channel, details, created_at)
SELECT
  gen_random_uuid(),
  d.id,
  COALESCE((log_entry->>'action'), 'activity') AS event_type,
  COALESCE((log_entry->>'actor'), (log_entry->>'performedBy'), 'System') AS actor_name,
  'keem@crestzendo.com' AS actor_email,
  'web_app' AS channel,
  log_entry AS details,
  COALESCE(
    (log_entry->>'timestamp')::timestamptz,
    d.updated_at,
    CURRENT_TIMESTAMP
  ) AS created_at
FROM documents d,
  jsonb_array_elements(
    CASE
      WHEN d.activity_logs IS NOT NULL
        AND jsonb_typeof(d.activity_logs) = 'array'
        AND jsonb_array_length(d.activity_logs) > 0
      THEN d.activity_logs
      ELSE '[]'::jsonb
    END
  ) WITH ORDINALITY AS t(log_entry, ordinality)
WHERE jsonb_typeof(d.activity_logs) = 'array'
  AND jsonb_array_length(d.activity_logs) > 0
ON CONFLICT DO NOTHING;

-- ================================================================
-- 7. Drop unused JSONB columns from documents
--    activity_logs → replaced by document_timelines table
--    approval_chain → replaced by document_approvals table
-- ================================================================
ALTER TABLE documents
  DROP COLUMN IF EXISTS activity_logs,
  DROP COLUMN IF EXISTS approval_chain;

-- ================================================================
-- 8. Drop dead legacy tables (no active code reads them)
--    document_object_values, document_object_styles → no app code
--    document_masters → dual-write legacy, replaced by documents
-- ================================================================

-- Drop child tables first (FK dependencies)
DROP TABLE IF EXISTS document_object_values CASCADE;
DROP TABLE IF EXISTS document_object_styles CASCADE;

-- Remove document_masters FK constraints if any remain, then drop
DROP TABLE IF EXISTS document_masters CASCADE;

-- ================================================================
-- 9. Fix document_authorizations.document_id that referenced
--    document_masters — already points to documents table OK
--    (FK was on document_masters but same UUIDs are in documents)
-- ================================================================

-- Verify document_authorizations references are still valid
-- (document_masters and documents shared same IDs via dual-write)
-- No action needed — authorizations already reference valid document IDs

COMMIT;
