-- Migration 000014: Clean up signatories and enhance counterparties table
-- Move default signatory to settings.organization and enhance counterparties with contact and metadata

-- 1. Add contact and metadata columns to counterparties
ALTER TABLE counterparties 
ADD COLUMN IF NOT EXISTS contact_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS contact_position VARCHAR(255),
ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;

-- 2. Drop foreign key constraint on documents.our_signatory_id (making it purely independent/optional)
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_our_signatory_id_fkey;
