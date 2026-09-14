package repository

import (
	"context"
	"database/sql"
	"fmt"
	"math/rand"
	"time"

	"docbuilder-backend/internal/model"
)

type DocumentRepository struct {
	db *sql.DB
}

func NewDocumentRepository(db *sql.DB) *DocumentRepository {
	return &DocumentRepository{db: db}
}

// GetAllDocuments retrieves all documents ordered by created_at DESC
func (r *DocumentRepository) GetAllDocuments(ctx context.Context) ([]model.Document, error) {
	query := `
		SELECT d.id, d.verification_token, d.name, d.template_id, COALESCE(t.name, d.template_id),
		       d.status, d.sent_to, d.last_sent_at, d.created_at, d.updated_at
		FROM documents d
		LEFT JOIN templates t ON d.template_id = t.id
		WHERE d.deleted_at IS NULL
		ORDER BY d.created_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("query documents failed: %w", err)
	}
	defer rows.Close()

	var docs []model.Document
	for rows.Next() {
		var doc model.Document
		var token, sentTo sql.NullString
		var lastSentAt sql.NullTime

		if err := rows.Scan(
			&doc.ID, &token, &doc.Name, &doc.TemplateID, &doc.TemplateName,
			&doc.Status, &sentTo, &lastSentAt, &doc.CreatedAt, &doc.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan document failed: %w", err)
		}

		if token.Valid {
			doc.VerificationToken = token.String
		}
		if sentTo.Valid {
			doc.SentTo = &sentTo.String
		}
		if lastSentAt.Valid {
			doc.LastSentAt = &lastSentAt.Time
		}

		doc.Values = make(map[string]interface{})
		docs = append(docs, doc)
	}

	return docs, nil
}

// GetDocumentByID retrieves a single document with all its field values and logs
func (r *DocumentRepository) GetDocumentByID(ctx context.Context, id string) (*model.Document, error) {
	query := `
		SELECT d.id, d.verification_token, d.name, d.template_id, COALESCE(t.name, d.template_id),
		       d.status, d.sent_to, d.last_sent_at, d.created_at, d.updated_at
		FROM documents d
		LEFT JOIN templates t ON d.template_id = t.id
		WHERE d.id = $1 AND d.deleted_at IS NULL
		LIMIT 1
	`
	var doc model.Document
	var token, sentTo sql.NullString
	var lastSentAt sql.NullTime

	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&doc.ID, &token, &doc.Name, &doc.TemplateID, &doc.TemplateName,
		&doc.Status, &sentTo, &lastSentAt, &doc.CreatedAt, &doc.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get document by id failed: %w", err)
	}

	if token.Valid {
		doc.VerificationToken = token.String
	}
	if sentTo.Valid {
		doc.SentTo = &sentTo.String
	}
	if lastSentAt.Valid {
		doc.LastSentAt = &lastSentAt.Time
	}

	// Fetch document field values (EAV)
	valuesQuery := `
		SELECT field_key, text_value, number_value
		FROM document_field_values
		WHERE document_id = $1
	`
	doc.Values = make(map[string]interface{})
	vRows, err := r.db.QueryContext(ctx, valuesQuery, id)
	if err == nil {
		defer vRows.Close()
		for vRows.Next() {
			var k string
			var textVal sql.NullString
			var numVal sql.NullFloat64
			if err := vRows.Scan(&k, &textVal, &numVal); err == nil {
				if textVal.Valid {
					doc.Values[k] = textVal.String
				} else if numVal.Valid {
					doc.Values[k] = numVal.Float64
				}
			}
		}
	}

	// Fetch activity logs
	logsQuery := `
		SELECT id, action, performed_by, details, comment, created_at
		FROM document_activity_logs
		WHERE document_id = $1
		ORDER BY created_at ASC
	`
	lRows, err := r.db.QueryContext(ctx, logsQuery, id)
	if err == nil {
		defer lRows.Close()
		for lRows.Next() {
			var l model.ActivityLog
			var action, perf, det, comm sql.NullString
			var createdAt time.Time
			if err := lRows.Scan(&l.ID, &action, &perf, &det, &comm, &createdAt); err == nil {
				l.Action = action.String
				l.PerformedBy = perf.String
				l.Details = det.String
				l.Comment = comm.String
				l.Timestamp = createdAt
				doc.ActivityLogs = append(doc.ActivityLogs, l)
			}
		}
	}

	return &doc, nil
}

// CreateDocument inserts a new document and its field values inside a transaction
func (r *DocumentRepository) CreateDocument(ctx context.Context, doc *model.Document) (*model.Document, error) {
	if doc.ID == "" {
		doc.ID = fmt.Sprintf("doc-%d", time.Now().UnixMilli())
	}
	if doc.VerificationToken == "" {
		doc.VerificationToken = fmt.Sprintf("VRF-%X-%X", rand.Int31(), rand.Int31())
	}
	if doc.Status == "" {
		doc.Status = "draft"
	}

	orgID := "org-crestzendo"
	templateID := doc.TemplateID
	if templateID == "" {
		templateID = "nda"
	}

	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("begin transaction failed: %w", err)
	}
	defer tx.Rollback()

	insertDocQuery := `
		INSERT INTO documents (id, org_id, template_id, name, status, verification_token, watermark, sent_to, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		RETURNING created_at, updated_at
	`
	err = tx.QueryRowContext(ctx, insertDocQuery,
		doc.ID, orgID, templateID, doc.Name, doc.Status, doc.VerificationToken, "none", doc.SentTo,
	).Scan(&doc.CreatedAt, &doc.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("insert document failed: %w", err)
	}

	// Insert field values
	if doc.Values != nil && len(doc.Values) > 0 {
		upsertFieldQuery := `
			INSERT INTO document_field_values (id, document_id, field_key, text_value, updated_at)
			VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
			ON CONFLICT (document_id, field_key) 
			DO UPDATE SET text_value = EXCLUDED.text_value, updated_at = CURRENT_TIMESTAMP
		`
		for k, v := range doc.Values {
			fieldID := fmt.Sprintf("val-%s-%s", doc.ID, k)
			strVal := fmt.Sprintf("%v", v)
			_, err = tx.ExecContext(ctx, upsertFieldQuery, fieldID, doc.ID, k, strVal)
			if err != nil {
				return nil, fmt.Errorf("insert field value [%s] failed: %w", k, err)
			}
		}
	}

	// Add Activity Log
	logID := fmt.Sprintf("log-%d", time.Now().UnixNano())
	_, _ = tx.ExecContext(ctx, `
		INSERT INTO document_activity_logs (id, document_id, action, performed_by, details, created_at)
		VALUES ($1, $2, 'create', 'User', 'สร้างเอกสารใหม่ในระบบ', CURRENT_TIMESTAMP)
	`, logID, doc.ID)

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("commit transaction failed: %w", err)
	}

	return doc, nil
}

// UpdateDocument updates document metadata and syncs field values inside a transaction
func (r *DocumentRepository) UpdateDocument(ctx context.Context, id string, patch *model.Document) (*model.Document, error) {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("begin transaction failed: %w", err)
	}
	defer tx.Rollback()

	updateQuery := `
		UPDATE documents
		SET name = COALESCE(NULLIF($2, ''), name),
		    status = COALESCE(NULLIF($3, ''), status),
		    sent_to = COALESCE($4, sent_to),
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $1
		RETURNING id, verification_token, name, template_id, status, sent_to, updated_at
	`
	var doc model.Document
	var sentTo, token sql.NullString
	err = tx.QueryRowContext(ctx, updateQuery, id, patch.Name, patch.Status, patch.SentTo).Scan(
		&doc.ID, &token, &doc.Name, &doc.TemplateID, &doc.Status, &sentTo, &doc.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("update document failed: %w", err)
	}

	if token.Valid {
		doc.VerificationToken = token.String
	}
	if sentTo.Valid {
		doc.SentTo = &sentTo.String
	}

	// Sync Field Values
	if patch.Values != nil && len(patch.Values) > 0 {
		upsertFieldQuery := `
			INSERT INTO document_field_values (id, document_id, field_key, text_value, updated_at)
			VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
			ON CONFLICT (document_id, field_key) 
			DO UPDATE SET text_value = EXCLUDED.text_value, updated_at = CURRENT_TIMESTAMP
		`
		for k, v := range patch.Values {
			fieldID := fmt.Sprintf("val-%s-%s", id, k)
			strVal := fmt.Sprintf("%v", v)
			_, err = tx.ExecContext(ctx, upsertFieldQuery, fieldID, id, k, strVal)
			if err != nil {
				return nil, fmt.Errorf("upsert field value [%s] failed: %w", k, err)
			}
		}
	}

	// Add Activity Log
	logID := fmt.Sprintf("log-%d", time.Now().UnixNano())
	_, _ = tx.ExecContext(ctx, `
		INSERT INTO document_activity_logs (id, document_id, action, performed_by, details, created_at)
		VALUES ($1, $2, 'edit', 'User', 'แก้ไขและบันทึกข้อมูลเอกสาร', CURRENT_TIMESTAMP)
	`, logID, id)

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("commit transaction failed: %w", err)
	}

	doc.Values = patch.Values
	return &doc, nil
}

// DeleteDocument deletes a document by ID (Cascade removes child rows)
func (r *DocumentRepository) DeleteDocument(ctx context.Context, id string) error {
	res, err := r.db.ExecContext(ctx, "DELETE FROM documents WHERE id = $1", id)
	if err != nil {
		return fmt.Errorf("delete document failed: %w", err)
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

// RecordAction logs export, print or email actions in sent_history
func (r *DocumentRepository) RecordAction(ctx context.Context, docID string, actionType string, format string, recipientEmail string) error {
	id := fmt.Sprintf("sent-%d", time.Now().UnixMilli())
	query := `
		INSERT INTO sent_history (id, document_id, action_type, format, recipient_email, status, sent_at)
		VALUES ($1, $2, $3, $4, $5, 'success', CURRENT_TIMESTAMP)
	`
	_, err := r.db.ExecContext(ctx, query, id, docID, actionType, format, recipientEmail)
	return err
}
