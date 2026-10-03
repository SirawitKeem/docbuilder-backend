-- ==============================================================================
-- MIGRATION: 000010_cleanup_and_backfill_3nf.sql
-- 1. Backfill existing templates & documents into 3NF document_masters, styles, timelines
-- 2. Drop 6 redundant & unused legacy tables:
--    - document_field_values (superseded by document_object_values)
--    - document_table_rows (superseded by document_object_values)
--    - document_tables (superseded by document_object_values)
--    - document_activity_logs (superseded by document_timelines)
--    - template_blocks (legacy, not used by frontend)
--    - template_versions (legacy, versions are tracked on templates directly)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Step 1: Backfill Templates into document_masters & document_object_styles
-- ------------------------------------------------------------------------------
INSERT INTO document_masters (
    id, doc_type, format_type, document_type_id, version, category_id, org_id,
    document_number, title, description, status,
    created_by_user_id, created_by_name, created_by_email,
    created_at, updated_at
)
SELECT 
    t.id,
    'template' AS doc_type,
    CASE 
        WHEN t.canvas_preset LIKE '%slide%' THEN 'slide'
        WHEN t.canvas_preset LIKE '%custom%' OR t.canvas_preset LIKE '%poster%' THEN 'artwork'
        ELSE 'word'
    END AS format_type,
    CASE 
        WHEN t.canvas_preset LIKE '%slide%' THEN 'slide'
        WHEN t.canvas_preset LIKE '%custom%' OR t.canvas_preset LIKE '%poster%' THEN 'artwork'
        ELSE 'word'
    END AS document_type_id,
    COALESCE(t.version, 1) AS version,
    t.category_id,
    'org-crestzendo' AS org_id,
    NULL AS document_number,
    t.name AS title,
    t.description,
    COALESCE(t.status, 'published') AS status,
    'usr-admin' AS created_by_user_id,
    'สิรวิทย์ เพชรจำรัส' AS created_by_name,
    'keem@crestzendo.com' AS created_by_email,
    COALESCE(t.created_at, CURRENT_TIMESTAMP),
    COALESCE(t.updated_at, CURRENT_TIMESTAMP)
FROM templates t
ON CONFLICT (id) DO UPDATE 
SET title = EXCLUDED.title,
    description = EXCLUDED.description,
    status = EXCLUDED.status,
    document_type_id = EXCLUDED.document_type_id,
    updated_at = EXCLUDED.updated_at;

-- Backfill Template Styles
INSERT INTO document_object_styles (
    id, document_id, preset_id, page_width_px, page_height_px, orientation, updated_at
)
SELECT 
    'style_' || t.id,
    t.id AS document_id,
    CASE 
        WHEN t.canvas_preset = 'slide-16-9' THEN 'slide-16-9'
        WHEN t.canvas_preset LIKE '%custom%' THEN 'artwork-custom'
        WHEN t.orientation = 'landscape' THEN 'a4-landscape'
        ELSE 'a4-portrait'
    END AS preset_id,
    CASE 
        WHEN t.canvas_preset = 'slide-16-9' THEN 1280
        WHEN t.orientation = 'landscape' THEN 1123
        ELSE 794
    END AS page_width_px,
    CASE 
        WHEN t.canvas_preset = 'slide-16-9' THEN 720
        WHEN t.orientation = 'landscape' THEN 794
        ELSE 1123
    END AS page_height_px,
    COALESCE(t.orientation, 'portrait') AS orientation,
    COALESCE(t.updated_at, CURRENT_TIMESTAMP)
FROM templates t
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- Step 2: Backfill Documents into document_masters & document_authorizations
-- ------------------------------------------------------------------------------
INSERT INTO document_masters (
    id, doc_type, format_type, document_type_id, parent_template_id, version,
    category_id, org_id, document_number, title, description, status,
    created_by_user_id, created_by_name, created_by_email,
    verification_token, created_at, updated_at
)
SELECT 
    d.id,
    'document' AS doc_type,
    'word' AS format_type,
    'word' AS document_type_id,
    d.template_id AS parent_template_id,
    COALESCE(d.version, 1) AS version,
    t.category_id AS category_id,
    COALESCE(d.org_id, 'org-crestzendo') AS org_id,
    d.document_number,
    COALESCE(d.name, 'Untitled Document') AS title,
    d.template_name AS description,
    COALESCE(d.status, 'draft') AS status,
    'usr-admin' AS created_by_user_id,
    COALESCE(d.created_by, 'สิรวิทย์ เพชรจำรัส') AS created_by_name,
    'keem@crestzendo.com' AS created_by_email,
    d.verification_token,
    COALESCE(d.created_at, CURRENT_TIMESTAMP),
    COALESCE(d.updated_at, CURRENT_TIMESTAMP)
FROM documents d
LEFT JOIN templates t ON d.template_id = t.id
ON CONFLICT (id) DO UPDATE 
SET title = EXCLUDED.title,
    document_number = EXCLUDED.document_number,
    status = EXCLUDED.status,
    created_by_name = EXCLUDED.created_by_name,
    updated_at = EXCLUDED.updated_at;

-- Grant Owner Authorization to Admin
INSERT INTO document_authorizations (
    id, document_id, user_email, permission_level, granted_by_email, is_active, created_at
)
SELECT 
    'auth_' || d.id,
    d.id,
    'keem@crestzendo.com',
    'owner',
    'keem@crestzendo.com',
    TRUE,
    COALESCE(d.created_at, CURRENT_TIMESTAMP)
FROM documents d
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- Step 3: Migrate Activity Logs from document_activity_logs into document_timelines
-- ------------------------------------------------------------------------------
INSERT INTO document_timelines (
    id, document_id, event_type, actor_name, actor_email, channel, details, created_at
)
SELECT 
    COALESCE(l.id, 'tml_' || gen_random_uuid()),
    l.document_id,
    COALESCE(l.action, 'created') AS event_type,
    COALESCE(l.performed_by, 'สิรวิทย์ เพชรจำรัส') AS actor_name,
    'keem@crestzendo.com' AS actor_email,
    'web_app' AS channel,
    jsonb_build_object('comment', l.comment, 'details', l.details),
    COALESCE(l.created_at, CURRENT_TIMESTAMP)
FROM document_activity_logs l
WHERE EXISTS (SELECT 1 FROM document_masters m WHERE m.id = l.document_id)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- Step 4: Migrate Old Field Values into document_object_values
-- ------------------------------------------------------------------------------
INSERT INTO document_object_values (
    id, document_id, object_key, object_type_id, text_value, numeric_value, page_number, updated_at
)
SELECT 
    COALESCE(dfv.id, 'dov_' || gen_random_uuid()),
    dfv.document_id,
    dfv.field_key AS object_key,
    CASE 
        WHEN dfv.number_value IS NOT NULL THEN 'number'
        ELSE 'text'
    END AS object_type_id,
    dfv.text_value,
    dfv.number_value,
    1 AS page_number,
    COALESCE(dfv.updated_at, CURRENT_TIMESTAMP)
FROM document_field_values dfv
WHERE EXISTS (SELECT 1 FROM document_masters m WHERE m.id = dfv.document_id)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- Step 5: Safely Drop Redundant Legacy Tables
-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS document_table_rows CASCADE;
DROP TABLE IF EXISTS document_tables CASCADE;
DROP TABLE IF EXISTS document_field_values CASCADE;
DROP TABLE IF EXISTS document_activity_logs CASCADE;
DROP TABLE IF EXISTS template_blocks CASCADE;
DROP TABLE IF EXISTS template_versions CASCADE;
DROP TABLE IF EXISTS template_table_columns CASCADE;
DROP TABLE IF EXISTS template_fields CASCADE;
DROP TABLE IF EXISTS field_profile_templates CASCADE;
DROP TABLE IF EXISTS template_permissions CASCADE;
DROP TABLE IF EXISTS template_shares CASCADE;
