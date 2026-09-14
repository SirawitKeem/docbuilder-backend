package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	_ "github.com/lib/pq"
)

type SettingsRepository struct {
	db *sql.DB
}

func NewSettingsRepository(db *sql.DB) *SettingsRepository {
	return &SettingsRepository{db: db}
}

func (r *SettingsRepository) GetSettings(ctx context.Context, orgID string) (map[string]interface{}, error) {
	if orgID == "" {
		orgID = "org-crestzendo"
	}

	query := `SELECT key, value FROM settings WHERE org_id = $1`
	rows, err := r.db.QueryContext(ctx, query, orgID)
	if err != nil {
		return nil, fmt.Errorf("query settings failed: %w", err)
	}
	defer rows.Close()

	res := map[string]interface{}{
		"language": "th",
		"currency": "THB",
		"theme":    "light",
	}

	for rows.Next() {
		var k string
		var rawVal []byte
		if err := rows.Scan(&k, &rawVal); err == nil {
			var parsed interface{}
			if err := json.Unmarshal(rawVal, &parsed); err == nil {
				res[k] = parsed
			} else {
				res[k] = string(rawVal)
			}
		}
	}

	return res, nil
}

func (r *SettingsRepository) UpdateSettings(ctx context.Context, orgID string, patch map[string]interface{}) (map[string]interface{}, error) {
	if orgID == "" {
		orgID = "org-crestzendo"
	}

	upsertQuery := `
		INSERT INTO settings (id, org_id, key, value, updated_at)
		VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
		ON CONFLICT (org_id, key) 
		DO UPDATE SET value = EXCLUDED.value, updated_at = CURRENT_TIMESTAMP
	`

	for k, v := range patch {
		id := fmt.Sprintf("set-%s-%s", orgID, k)
		valBytes, err := json.Marshal(v)
		if err != nil {
			continue
		}
		_, err = r.db.ExecContext(ctx, upsertQuery, id, orgID, k, valBytes)
		if err != nil {
			return nil, fmt.Errorf("upsert setting [%s] failed: %w", k, err)
		}
	}

	return r.GetSettings(ctx, orgID)
}
