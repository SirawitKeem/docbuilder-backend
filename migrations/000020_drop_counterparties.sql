-- ================================================================
-- Migration 000020: Drop counterparties and consolidate into documents.values
-- ================================================================

BEGIN;

-- 1. Drop foreign key constraint on documents.counterparty_id
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_counterparty_id_fkey CASCADE;

-- 2. Drop column counterparty_id from documents table
ALTER TABLE documents DROP COLUMN IF EXISTS counterparty_id;

-- 3. Drop child table counterparty_signatories
DROP TABLE IF EXISTS counterparty_signatories CASCADE;

-- 4. Drop counterparties table
DROP TABLE IF EXISTS counterparties CASCADE;

COMMIT;
