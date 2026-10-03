-- Migration 000021: Consolidate custom_tokens into templates and drop standalone custom_tokens table

-- 1. Add custom_tokens JSONB column to templates table
ALTER TABLE templates ADD COLUMN IF NOT EXISTS custom_tokens JSONB DEFAULT '[]'::jsonb;

-- 2. Migrate existing token 'url' to matching template
UPDATE templates 
SET custom_tokens = jsonb_build_array(
  jsonb_build_object(
    'id', '01a08586-0ea8-716c-9038-a3bbb8ada0fa',
    'key', 'url',
    'label', 'URL',
    'scope', 'template',
    'fieldType', 'text',
    'example', ''
  )
)
WHERE id = '01a09e9a-fd1f-75f7-b619-dc9cbecc7ff0';

-- 3. Drop standalone custom_tokens table
DROP TABLE IF EXISTS custom_tokens CASCADE;
