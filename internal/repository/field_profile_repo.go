package repository

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"docbuilder-backend/internal/model"
)

type FieldProfileRepository struct {
	db *sql.DB
}

func NewFieldProfileRepository(db *sql.DB) *FieldProfileRepository {
	return &FieldProfileRepository{db: db}
}

func (r *FieldProfileRepository) GetAllFieldProfiles(ctx context.Context) ([]model.FieldProfile, error) {
	query := `
		SELECT id, name, COALESCE(profile_type, 'customer'), created_at, updated_at
		FROM field_profiles
		ORDER BY created_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("query field profiles failed: %w", err)
	}
	defer rows.Close()

	var profiles []model.FieldProfile
	for rows.Next() {
		var fp model.FieldProfile
		if err := rows.Scan(&fp.ID, &fp.Name, &fp.ProfileType, &fp.CreatedAt, &fp.UpdatedAt); err != nil {
			return nil, err
		}
		fp.CompatibleTemplates = []string{}
		fp.Fields = make(map[string]interface{})

		// Fetch compatible templates
		tRows, err := r.db.QueryContext(ctx, "SELECT template_id FROM field_profile_templates WHERE profile_id = $1", fp.ID)
		if err == nil {
			for tRows.Next() {
				var tid string
				if err := tRows.Scan(&tid); err == nil {
					fp.CompatibleTemplates = append(fp.CompatibleTemplates, tid)
				}
			}
			tRows.Close()
		}

		// Fetch values
		vRows, err := r.db.QueryContext(ctx, "SELECT shared_key, field_value FROM field_profile_values WHERE profile_id = $1", fp.ID)
		if err == nil {
			for vRows.Next() {
				var k string
				var v sql.NullString
				if err := vRows.Scan(&k, &v); err == nil && v.Valid {
					fp.Fields[k] = v.String
				}
			}
			vRows.Close()
		}

		profiles = append(profiles, fp)
	}

	return profiles, nil
}

func (r *FieldProfileRepository) GetFieldProfileByID(ctx context.Context, id string) (*model.FieldProfile, error) {
	query := `
		SELECT id, name, COALESCE(profile_type, 'customer'), created_at, updated_at
		FROM field_profiles
		WHERE id = $1
	`
	var fp model.FieldProfile
	err := r.db.QueryRowContext(ctx, query, id).Scan(&fp.ID, &fp.Name, &fp.ProfileType, &fp.CreatedAt, &fp.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	fp.CompatibleTemplates = []string{}
	fp.Fields = make(map[string]interface{})

	tRows, err := r.db.QueryContext(ctx, "SELECT template_id FROM field_profile_templates WHERE profile_id = $1", fp.ID)
	if err == nil {
		for tRows.Next() {
			var tid string
			if err := tRows.Scan(&tid); err == nil {
				fp.CompatibleTemplates = append(fp.CompatibleTemplates, tid)
			}
		}
		tRows.Close()
	}

	vRows, err := r.db.QueryContext(ctx, "SELECT shared_key, field_value FROM field_profile_values WHERE profile_id = $1", fp.ID)
	if err == nil {
		for vRows.Next() {
			var k string
			var v sql.NullString
			if err := vRows.Scan(&k, &v); err == nil && v.Valid {
				fp.Fields[k] = v.String
			}
		}
		vRows.Close()
	}

	return &fp, nil
}

func (r *FieldProfileRepository) CreateFieldProfile(ctx context.Context, fp *model.FieldProfile) (*model.FieldProfile, error) {
	if fp.ID == "" {
		fp.ID = fmt.Sprintf("profile-%d", time.Now().UnixMilli())
	}
	if fp.ProfileType == "" {
		fp.ProfileType = "customer"
	}
	orgID := "org-crestzendo"

	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	query := `
		INSERT INTO field_profiles (id, org_id, name, profile_type, created_at, updated_at)
		VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		RETURNING created_at, updated_at
	`
	err = tx.QueryRowContext(ctx, query, fp.ID, orgID, fp.Name, fp.ProfileType).Scan(&fp.CreatedAt, &fp.UpdatedAt)
	if err != nil {
		return nil, err
	}

	// Insert templates
	for _, tid := range fp.CompatibleTemplates {
		_, _ = tx.ExecContext(ctx, "INSERT INTO field_profile_templates (profile_id, template_id) VALUES ($1, $2) ON CONFLICT DO NOTHING", fp.ID, tid)
	}

	// Insert fields
	for k, v := range fp.Fields {
		valID := fmt.Sprintf("fpv-%s-%s", fp.ID, k)
		strVal := fmt.Sprintf("%v", v)
		_, _ = tx.ExecContext(ctx, "INSERT INTO field_profile_values (id, profile_id, shared_key, field_value, updated_at) VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)", valID, fp.ID, k, strVal)
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}
	return fp, nil
}

func (r *FieldProfileRepository) UpdateFieldProfile(ctx context.Context, id string, patch *model.FieldProfile) (*model.FieldProfile, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	query := `
		UPDATE field_profiles
		SET name = COALESCE(NULLIF($2, ''), name),
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $1
		RETURNING id, name, COALESCE(profile_type, 'customer'), updated_at
	`
	var fp model.FieldProfile
	err = tx.QueryRowContext(ctx, query, id, patch.Name).Scan(&fp.ID, &fp.Name, &fp.ProfileType, &fp.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	// Update templates if provided
	if patch.CompatibleTemplates != nil {
		_, _ = tx.ExecContext(ctx, "DELETE FROM field_profile_templates WHERE profile_id = $1", id)
		for _, tid := range patch.CompatibleTemplates {
			_, _ = tx.ExecContext(ctx, "INSERT INTO field_profile_templates (profile_id, template_id) VALUES ($1, $2) ON CONFLICT DO NOTHING", id, tid)
		}
		fp.CompatibleTemplates = patch.CompatibleTemplates
	}

	// Update fields if provided
	if patch.Fields != nil {
		_, _ = tx.ExecContext(ctx, "DELETE FROM field_profile_values WHERE profile_id = $1", id)
		for k, v := range patch.Fields {
			valID := fmt.Sprintf("fpv-%s-%s", id, k)
			strVal := fmt.Sprintf("%v", v)
			_, _ = tx.ExecContext(ctx, "INSERT INTO field_profile_values (id, profile_id, shared_key, field_value, updated_at) VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)", valID, id, k, strVal)
		}
		fp.Fields = patch.Fields
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}
	return &fp, nil
}

func (r *FieldProfileRepository) DeleteFieldProfile(ctx context.Context, id string) error {
	res, err := r.db.ExecContext(ctx, "DELETE FROM field_profiles WHERE id = $1", id)
	if err != nil {
		return err
	}
	rowsAff, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAff == 0 {
		return sql.ErrNoRows
	}
	return nil
}
