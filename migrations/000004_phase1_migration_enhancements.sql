-- ==============================================================================
-- MIGRATION: 000004_phase1_migration_enhancements.sql
-- Purpose: Add version column for optimistic locking, atomic counters, assets table, and unique constraints
-- Safe, additive only, 100% idempotent (No DROP / TRUNCATE)
-- ==============================================================================

-- 1. Add version column for Optimistic Locking in documents and templates
ALTER TABLE documents 
    ADD COLUMN IF NOT EXISTS version INT NOT NULL DEFAULT 1;

ALTER TABLE templates 
    ADD COLUMN IF NOT EXISTS version INT NOT NULL DEFAULT 1;

-- 2. Create document_counters table for atomic running number generation
CREATE TABLE IF NOT EXISTS document_counters (
    prefix VARCHAR(20) NOT NULL,
    period VARCHAR(10) NOT NULL,
    last_value INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (prefix, period)
);

-- 3. Create assets table for uploaded images, signatures, and stamps
CREATE TABLE IF NOT EXISTS assets (
    id VARCHAR(64) PRIMARY KEY,
    org_id VARCHAR(64) REFERENCES organizations(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    sha256 VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_assets_org_id ON assets(org_id);
CREATE INDEX IF NOT EXISTS idx_assets_sha256 ON assets(sha256);

-- 4. Add unique index for document_number (enforce unique quotation and document numbers when not null)
CREATE UNIQUE INDEX IF NOT EXISTS uq_documents_doc_number 
    ON documents(document_number) 
    WHERE document_number IS NOT NULL AND document_number != '';
