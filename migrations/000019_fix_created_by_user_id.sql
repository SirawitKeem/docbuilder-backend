-- ================================================================
-- Migration 000019: Fix created_by_user_id for categories and counterparties
-- ================================================================

BEGIN;

-- 1. Populate created_by_user_id on existing categories
UPDATE categories
SET created_by_user_id = '01a0fa5c-e3e4-7013-a331-93a672d1fc20',
    updated_at = CURRENT_TIMESTAMP
WHERE created_by_user_id IS NULL;

-- 2. Populate created_by_user_id on existing counterparties
UPDATE counterparties
SET created_by_user_id = '01a0fa5c-e3e4-7013-a331-93a672d1fc20',
    updated_at = CURRENT_TIMESTAMP
WHERE created_by_user_id IS NULL;

COMMIT;
