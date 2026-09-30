-- Migration 000006: Template Sharing and Governance Controls
-- Supports Share Internal (Org, Department, User), Share External (Token, Password, Expiry), and Control Governance

-- 1. Template Permissions (Internal Access Control)
CREATE TABLE IF NOT EXISTS template_permissions (
    id VARCHAR(64) PRIMARY KEY,
    template_id VARCHAR(64) NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    grantee_type VARCHAR(20) NOT NULL, -- 'org', 'department', 'user'
    grantee_id VARCHAR(64),            -- NULL if 'org', department name or user_id
    grantee_name VARCHAR(255),         -- Display name for grantee (e.g. 'Legal Team', 'Somchai Doe')
    permission_level VARCHAR(20) NOT NULL DEFAULT 'creator', -- 'viewer', 'creator', 'editor', 'admin'
    created_by VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_template_perms_tmpl ON template_permissions (template_id);
CREATE INDEX IF NOT EXISTS idx_template_perms_grantee ON template_permissions (grantee_type, grantee_id);

-- 2. Template Shares (External Access Links)
CREATE TABLE IF NOT EXISTS template_shares (
    id VARCHAR(64) PRIMARY KEY,
    template_id VARCHAR(64) NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    share_token VARCHAR(128) UNIQUE NOT NULL,
    share_type VARCHAR(20) NOT NULL DEFAULT 'view_only', -- 'view_only', 'fillable'
    password_hash VARCHAR(255),
    expires_at TIMESTAMPTZ,
    max_uses INT,
    view_count INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by VARCHAR(64),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_template_shares_token ON template_shares (share_token);
CREATE INDEX IF NOT EXISTS idx_template_shares_tmpl ON template_shares (template_id);

-- 3. Enhance Templates Table with Governance & Sharing Summary
ALTER TABLE templates 
    ADD COLUMN IF NOT EXISTS governance_policy JSONB DEFAULT '{
        "is_locked": false,
        "require_approval": false,
        "lock_immutable_clauses": false,
        "enforce_watermark": "none",
        "allow_export_formats": ["pdf", "pptx", "xlsx"]
    }'::jsonb,
    ADD COLUMN IF NOT EXISTS sharing_summary JSONB DEFAULT '{
        "is_public": false,
        "internal_level": "org_use",
        "share_count": 0
    }'::jsonb;
