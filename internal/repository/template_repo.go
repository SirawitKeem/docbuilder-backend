package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"docbuilder-backend/internal/model"
)

type TemplateRepository struct {
	db *sql.DB
}

func NewTemplateRepository(db *sql.DB) *TemplateRepository {
	return &TemplateRepository{db: db}
}

// GetAllTemplates retrieves all templates with category information from PostgreSQL
func (r *TemplateRepository) GetAllTemplates(ctx context.Context) ([]model.CustomTemplate, error) {
	query := `
		SELECT id, name, category_id, description, editor_type, created_at, updated_at
		FROM templates
		WHERE status != 'archived'
		ORDER BY is_standard DESC, name ASC
	`
	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("query templates failed: %w", err)
	}
	defer rows.Close()

	var templates []model.CustomTemplate
	for rows.Next() {
		var t model.CustomTemplate
		var desc sql.NullString
		if err := rows.Scan(&t.ID, &t.Name, &t.CategoryID, &desc, &t.Format, &t.CreatedAt, &t.UpdatedAt); err != nil {
			return nil, fmt.Errorf("scan template row failed: %w", err)
		}
		if desc.Valid {
			t.Description = desc.String
		}
		templates = append(templates, t)
	}

	return templates, nil
}

// GetTemplateByID retrieves a template along with its dynamic blocks from PostgreSQL
func (r *TemplateRepository) GetTemplateByID(ctx context.Context, id string) (*model.CustomTemplate, error) {
	query := `
		SELECT id, name, category_id, description, editor_type, created_at, updated_at
		FROM templates
		WHERE id = $1
		LIMIT 1
	`
	var t model.CustomTemplate
	var desc sql.NullString
	err := r.db.QueryRowContext(ctx, query, id).Scan(&t.ID, &t.Name, &t.CategoryID, &desc, &t.Format, &t.CreatedAt, &t.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get template by id failed: %w", err)
	}
	if desc.Valid {
		t.Description = desc.String
	}

	// Query blocks belonging to this template (via latest template_version)
	blocksQuery := `
		SELECT tb.id, tb.block_type, tb.title, tb.sort_order, tb.settings
		FROM template_blocks tb
		JOIN template_versions tv ON tb.template_version_id = tv.id
		WHERE tv.template_id = $1
		ORDER BY tb.sort_order ASC
	`
	rows, err := r.db.QueryContext(ctx, blocksQuery, id)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var b model.TemplateBlock
			var settingsJSON []byte
			if err := rows.Scan(&b.ID, &b.Type, &b.Content, &b.Order, &settingsJSON); err == nil {
				if len(settingsJSON) > 0 {
					var props map[string]interface{}
					if err := json.Unmarshal(settingsJSON, &props); err == nil {
						b.Props = props
					}
				}
				t.Blocks = append(t.Blocks, b)
			}
		}
	}

	return &t, nil
}
