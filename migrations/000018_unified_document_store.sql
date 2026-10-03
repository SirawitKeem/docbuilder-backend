-- ================================================================
-- Migration 000018: Unified Document Store (Single Source of Truth)
-- ================================================================
-- 1. Retire and DROP redundant tables:
--    - field_profile_values (child)
--    - field_profiles (parent)
-- 2. Create GIN index on documents.values for high-performance JSONB querying
-- ================================================================

BEGIN;

-- 1. Drop redundant tables
DROP TABLE IF EXISTS field_profile_values CASCADE;
DROP TABLE IF EXISTS field_profiles CASCADE;

-- 2. Create GIN index on documents.values
CREATE INDEX IF NOT EXISTS idx_documents_values_gin ON documents USING gin (values);

COMMIT;
