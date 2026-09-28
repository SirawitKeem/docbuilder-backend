package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"docbuilder-backend/internal/model"
)

type TemplateRepository struct {
	db *sql.DB
}

func NewTemplateRepository(db *sql.DB) *TemplateRepository {
	return &TemplateRepository{db: db}
}

// GetAllTemplates retrieves all templates from PostgreSQL with full metadata and pages
func (r *TemplateRepository) GetAllTemplates(ctx context.Context) ([]model.CustomTemplate, error) {
	query := `
		SELECT id, name, category_id, description, editor_type, canvas_preset,
		       orientation, theme, status, icon, badge, current_version_id,
		       pages, sheet_data, margin, created_at, updated_at
		FROM templates
		WHERE status != 'archived' AND deleted_at IS NULL
		ORDER BY is_standard DESC, updated_at DESC, name ASC
	`
	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("query templates failed: %w", err)
	}
	defer rows.Close()

	var templates []model.CustomTemplate
	for rows.Next() {
		var t model.CustomTemplate
		var desc, editorType, canvasPreset, orientation, theme, status, icon, badge, curVer sql.NullString
		var pagesJSON, sheetJSON, marginJSON []byte

		if err := rows.Scan(
			&t.ID, &t.Name, &t.CategoryID, &desc, &editorType, &canvasPreset,
			&orientation, &theme, &status, &icon, &badge, &curVer,
			&pagesJSON, &sheetJSON, &marginJSON, &t.CreatedAt, &t.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan template row failed: %w", err)
		}

		if desc.Valid { t.Description = desc.String }
		if editorType.Valid { t.EditorType = editorType.String; t.Format = editorType.String }
		if canvasPreset.Valid { t.CanvasPreset = canvasPreset.String }
		if orientation.Valid { t.Orientation = orientation.String }
		if theme.Valid { t.Theme = theme.String }
		if status.Valid { t.Status = status.String }
		if icon.Valid { t.Icon = icon.String }
		if badge.Valid { t.Badge = badge.String }
		if curVer.Valid { t.CurrentVersionID = curVer.String }

		if len(pagesJSON) > 0 {
			var pages []map[string]interface{}
			if err := json.Unmarshal(pagesJSON, &pages); err == nil {
				t.Pages = pages
				t.PageCount = len(pages)
			}
		}
		if len(sheetJSON) > 0 {
			var sheet map[string]interface{}
			if err := json.Unmarshal(sheetJSON, &sheet); err == nil {
				t.SheetData = sheet
			}
		}
		if len(marginJSON) > 0 {
			var margin map[string]interface{}
			if err := json.Unmarshal(marginJSON, &margin); err == nil {
				t.Margin = margin
			}
		}

		templates = append(templates, t)
	}

	return templates, nil
}

// GetTemplateByID retrieves a single template with full pages, sheet data, and blocks
func (r *TemplateRepository) GetTemplateByID(ctx context.Context, id string) (*model.CustomTemplate, error) {
	query := `
		SELECT id, name, category_id, description, editor_type, canvas_preset,
		       orientation, theme, status, icon, badge, current_version_id,
		       pages, sheet_data, margin, created_at, updated_at
		FROM templates
		WHERE id = $1 AND deleted_at IS NULL
		LIMIT 1
	`
	var t model.CustomTemplate
	var desc, editorType, canvasPreset, orientation, theme, status, icon, badge, curVer sql.NullString
	var pagesJSON, sheetJSON, marginJSON []byte

	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&t.ID, &t.Name, &t.CategoryID, &desc, &editorType, &canvasPreset,
		&orientation, &theme, &status, &icon, &badge, &curVer,
		&pagesJSON, &sheetJSON, &marginJSON, &t.CreatedAt, &t.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get template by id failed: %w", err)
	}

	if desc.Valid { t.Description = desc.String }
	if editorType.Valid { t.EditorType = editorType.String; t.Format = editorType.String }
	if canvasPreset.Valid { t.CanvasPreset = canvasPreset.String }
	if orientation.Valid { t.Orientation = orientation.String }
	if theme.Valid { t.Theme = theme.String }
	if status.Valid { t.Status = status.String }
	if icon.Valid { t.Icon = icon.String }
	if badge.Valid { t.Badge = badge.String }
	if curVer.Valid { t.CurrentVersionID = curVer.String }

	if len(pagesJSON) > 0 {
		var pages []map[string]interface{}
		if err := json.Unmarshal(pagesJSON, &pages); err == nil {
			t.Pages = pages
			t.PageCount = len(pages)
		}
	}
	if len(sheetJSON) > 0 {
		var sheet map[string]interface{}
		if err := json.Unmarshal(sheetJSON, &sheet); err == nil {
			t.SheetData = sheet
		}
	}
	if len(marginJSON) > 0 {
		var margin map[string]interface{}
		if err := json.Unmarshal(marginJSON, &margin); err == nil {
			t.Margin = margin
		}
	}

	return &t, nil
}

// CreateTemplate inserts a new custom template with JSONB pages and version
func (r *TemplateRepository) CreateTemplate(ctx context.Context, t *model.CustomTemplate) (*model.CustomTemplate, error) {
	if t.ID == "" {
		t.ID = fmt.Sprintf("tmpl-%d", time.Now().UnixMilli())
	}
	now := time.Now()
	t.CreatedAt = now
	t.UpdatedAt = now
	if t.Status == "" { t.Status = "published" }
	if t.EditorType == "" { t.EditorType = "document" }
	if t.CanvasPreset == "" {
		if t.EditorType == "slide" {
			t.CanvasPreset = "slide-16-9"
		} else {
			t.CanvasPreset = "a4-portrait"
		}
	}
	if t.Orientation == "" { t.Orientation = "portrait" }
	if t.Theme == "" { t.Theme = "modern" }
	if t.Version == 0 { t.Version = 1 }
	if t.CurrentVersionID == "" {
		t.CurrentVersionID = fmt.Sprintf("ver-%s-v%d", t.ID, t.Version)
	}

	pagesJSON, _ := json.Marshal(t.Pages)
	if t.Pages == nil { pagesJSON = []byte("[]") }
	sheetJSON, _ := json.Marshal(t.SheetData)
	if t.SheetData == nil { sheetJSON = []byte("{}") }
	marginJSON, _ := json.Marshal(t.Margin)
	if t.Margin == nil { marginJSON = []byte("{}") }
	blocksJSON, _ := json.Marshal(t.Blocks)
	if t.Blocks == nil { blocksJSON = []byte("[]") }

	// 1. Insert template row
	query := `
		INSERT INTO templates (
			id, org_id, category_id, name, description, editor_type,
			canvas_preset, orientation, theme, status, is_custom, is_standard,
			current_version_id, icon, badge, pages, sheet_data, margin,
			created_at, updated_at
		) VALUES (
			$1, 'org-crestzendo', $2, $3, $4, $5,
			$6, $7, $8, $9, TRUE, FALSE,
			$10, $11, $12, $13, $14, $15,
			$16, $17
		)
		ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name,
			category_id = EXCLUDED.category_id,
			description = EXCLUDED.description,
			editor_type = EXCLUDED.editor_type,
			canvas_preset = EXCLUDED.canvas_preset,
			orientation = EXCLUDED.orientation,
			theme = EXCLUDED.theme,
			status = EXCLUDED.status,
			current_version_id = EXCLUDED.current_version_id,
			icon = EXCLUDED.icon,
			badge = EXCLUDED.badge,
			pages = EXCLUDED.pages,
			sheet_data = EXCLUDED.sheet_data,
			margin = EXCLUDED.margin,
			updated_at = EXCLUDED.updated_at;
	`
	_, err := r.db.ExecContext(ctx, query,
		t.ID, t.CategoryID, t.Name, t.Description, t.EditorType,
		t.CanvasPreset, t.Orientation, t.Theme, t.Status,
		t.CurrentVersionID, t.Icon, t.Badge, pagesJSON, sheetJSON, marginJSON,
		t.CreatedAt, t.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("create template failed: %w", err)
	}

	// 2. Insert template version
	verQuery := `
		INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks, pages, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name,
			description = EXCLUDED.description,
			blocks = EXCLUDED.blocks,
			pages = EXCLUDED.pages;
	`
	_, _ = r.db.ExecContext(ctx, verQuery, t.CurrentVersionID, t.ID, t.Version, t.Name, t.Description, t.CategoryID, blocksJSON, pagesJSON, t.CreatedAt)

	return t, nil
}

// UpdateTemplate updates an existing template
func (r *TemplateRepository) UpdateTemplate(ctx context.Context, id string, t *model.CustomTemplate) (*model.CustomTemplate, error) {
	now := time.Now()
	t.ID = id
	t.UpdatedAt = now

	pagesJSON, _ := json.Marshal(t.Pages)
	if t.Pages == nil { pagesJSON = []byte("[]") }
	sheetJSON, _ := json.Marshal(t.SheetData)
	if t.SheetData == nil { sheetJSON = []byte("{}") }
	marginJSON, _ := json.Marshal(t.Margin)
	if t.Margin == nil { marginJSON = []byte("{}") }

	query := `
		UPDATE templates
		SET name = COALESCE(NULLIF($2, ''), name),
		    category_id = COALESCE(NULLIF($3, ''), category_id),
		    description = $4,
		    editor_type = COALESCE(NULLIF($5, ''), editor_type),
		    canvas_preset = COALESCE(NULLIF($6, ''), canvas_preset),
		    orientation = COALESCE(NULLIF($7, ''), orientation),
		    theme = COALESCE(NULLIF($8, ''), theme),
		    status = COALESCE(NULLIF($9, ''), status),
		    icon = COALESCE(NULLIF($10, ''), icon),
		    badge = COALESCE(NULLIF($11, ''), badge),
		    pages = $12,
		    sheet_data = $13,
		    margin = $14,
		    updated_at = $15
		WHERE id = $1 AND deleted_at IS NULL
	`
	res, err := r.db.ExecContext(ctx, query,
		id, t.Name, t.CategoryID, t.Description, t.EditorType,
		t.CanvasPreset, t.Orientation, t.Theme, t.Status,
		t.Icon, t.Badge, pagesJSON, sheetJSON, marginJSON,
		now,
	)
	if err != nil {
		return nil, fmt.Errorf("update template failed: %w", err)
	}
	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		return nil, nil
	}

	return r.GetTemplateByID(ctx, id)
}

// DeleteTemplate soft-deletes a template
func (r *TemplateRepository) DeleteTemplate(ctx context.Context, id string) error {
	query := `UPDATE templates SET deleted_at = CURRENT_TIMESTAMP, status = 'archived' WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}
