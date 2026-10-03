-- Migration 000016: Enhance document_authorizations for unified template/document sharing
-- Adds entity_type, user_name, and role_title to support both documents and templates

ALTER TABLE document_authorizations 
ADD COLUMN IF NOT EXISTS entity_type VARCHAR(20) NOT NULL DEFAULT 'document',
ADD COLUMN IF NOT EXISTS user_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS role_title VARCHAR(100);

-- Backfill user_name for existing owner records from users table if matching email
UPDATE document_authorizations da
SET user_name = u.full_name
FROM users u
WHERE da.user_email = u.email AND da.user_name IS NULL;

-- Create index for fast lookups by entity_type and document_id
CREATE INDEX IF NOT EXISTS idx_doc_auth_entity ON document_authorizations(document_id, entity_type);
CREATE INDEX IF NOT EXISTS idx_doc_auth_lookup ON document_authorizations(document_id, user_email);
