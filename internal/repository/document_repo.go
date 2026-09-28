package repository

import (
	"context"
	"database/sql"
	"encoding/json"
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
		SELECT d.id, d.verification_token, d.name, d.template_id,
		       COALESCE(d.template_name, t.name, d.template_id),
		       COALESCE(d.created_by, 'ผู้จัดทำเอกสาร'),
		       d.status, d.sent_to, d.last_sent_at,
		       d.values, d.activity_logs, d.approval_chain,
		       d.created_at, d.updated_at
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
		var token, templateID, sentTo, createdBy, tmplName sql.NullString
		var lastSentAt sql.NullTime
		var valuesJSON, logsJSON, chainJSON []byte

		if err := rows.Scan(
			&doc.ID, &token, &doc.Name, &templateID, &tmplName,
			&createdBy, &doc.Status, &sentTo, &lastSentAt,
			&valuesJSON, &logsJSON, &chainJSON,
			&doc.CreatedAt, &doc.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("scan document failed: %w", err)
		}

		if token.Valid { doc.VerificationToken = token.String }
		if templateID.Valid { doc.TemplateID = templateID.String }
		if sentTo.Valid { doc.SentTo = &sentTo.String }
		if lastSentAt.Valid { doc.LastSentAt = &lastSentAt.Time }
		if createdBy.Valid { doc.CreatedBy = createdBy.String }
		if tmplName.Valid { doc.TemplateName = tmplName.String }

		doc.Values = make(map[string]interface{})
		if len(valuesJSON) > 0 {
			_ = json.Unmarshal(valuesJSON, &doc.Values)
		}
		if len(logsJSON) > 0 {
			_ = json.Unmarshal(logsJSON, &doc.ActivityLogs)
		}
		if len(chainJSON) > 0 {
			_ = json.Unmarshal(chainJSON, &doc.ApprovalChain)
		}

		docs = append(docs, doc)
	}

	return docs, nil
}

// GetDocumentByID retrieves a single document with all its field values and logs
func (r *DocumentRepository) GetDocumentByID(ctx context.Context, id string) (*model.Document, error) {
	query := `
		SELECT d.id, d.verification_token, d.name, d.template_id,
		       COALESCE(d.template_name, t.name, d.template_id),
		       COALESCE(d.created_by, 'ผู้จัดทำเอกสาร'),
		       d.status, d.sent_to, d.last_sent_at,
		       d.values, d.activity_logs, d.approval_chain,
		       d.created_at, d.updated_at
		FROM documents d
		LEFT JOIN templates t ON d.template_id = t.id
		WHERE (d.id = $1 OR d.verification_token = $1) AND d.deleted_at IS NULL
		LIMIT 1
	`
	var doc model.Document
	var token, templateID, sentTo, createdBy, tmplName sql.NullString
	var lastSentAt sql.NullTime
	var valuesJSON, logsJSON, chainJSON []byte

	err := r.db.QueryRowContext(ctx, query, id).Scan(
		&doc.ID, &token, &doc.Name, &templateID, &tmplName,
		&createdBy, &doc.Status, &sentTo, &lastSentAt,
		&valuesJSON, &logsJSON, &chainJSON,
		&doc.CreatedAt, &doc.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, fmt.Errorf("get document by id failed: %w", err)
	}

	if token.Valid { doc.VerificationToken = token.String }
	if templateID.Valid { doc.TemplateID = templateID.String }
	if sentTo.Valid { doc.SentTo = &sentTo.String }
	if lastSentAt.Valid { doc.LastSentAt = &lastSentAt.Time }
	if createdBy.Valid { doc.CreatedBy = createdBy.String }
	if tmplName.Valid { doc.TemplateName = tmplName.String }

	doc.Values = make(map[string]interface{})
	if len(valuesJSON) > 0 {
		_ = json.Unmarshal(valuesJSON, &doc.Values)
	}
	if len(logsJSON) > 0 {
		_ = json.Unmarshal(logsJSON, &doc.ActivityLogs)
	}
	if len(chainJSON) > 0 {
		_ = json.Unmarshal(chainJSON, &doc.ApprovalChain)
	}

	return &doc, nil
}

// CreateDocument inserts a new document and its JSONB values and logs inside a transaction
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
	if doc.CreatedBy == "" {
		doc.CreatedBy = "ผู้จัดทำเอกสาร"
	}

	orgID := "org-crestzendo"
	templateID := doc.TemplateID

	// If templateName empty, look up from templates table
	if doc.TemplateName == "" && templateID != "" {
		_ = r.db.QueryRowContext(ctx, `SELECT name FROM templates WHERE id = $1`, templateID).Scan(&doc.TemplateName)
	}

	now := time.Now()
	doc.CreatedAt = now
	doc.UpdatedAt = now

	// Prepare default activity log if empty
	if len(doc.ActivityLogs) == 0 {
		doc.ActivityLogs = []model.ActivityLog{
			{
				ID:          fmt.Sprintf("act-%d", time.Now().UnixMilli()),
				Action:      "create",
				PerformedBy: doc.CreatedBy,
				Timestamp:   now,
				Details:     "สร้างเอกสารฉบับร่าง",
			},
		}
	}

	// Prepare default approval chain if empty
	if len(doc.ApprovalChain) == 0 {
		doc.ApprovalChain = []map[string]interface{}{
			{
				"id":           "step-1",
				"stepName":     "ผู้จัดทำ / ผู้ยื่นเอกสาร",
				"assignedRole": "ผู้จัดทำ",
				"assignedUser": doc.CreatedBy,
				"status":       "approved",
				"signedAt":     now.Format(time.RFC3339),
			},
			{
				"id":           "step-2",
				"stepName":     "ผู้มีอำนาจอนุมัติ / กรรมการ",
				"assignedRole": "กรรมการผู้จัดการ",
				"assignedUser": "นายศรายุทธ โกสิยารักษ์",
				"status":       "pending",
				"signedAt":     nil,
			},
		}
	}

	valuesJSON, _ := json.Marshal(doc.Values)
	if doc.Values == nil { valuesJSON = []byte("{}") }
	logsJSON, _ := json.Marshal(doc.ActivityLogs)
	chainJSON, _ := json.Marshal(doc.ApprovalChain)

	var safeTemplateID *string
	if templateID != "" {
		var exists bool
		_ = r.db.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM templates WHERE id = $1)`, templateID).Scan(&exists)
		if exists {
			safeTemplateID = &templateID
		}
	}

	insertDocQuery := `
		INSERT INTO documents (
			id, org_id, template_id, template_name, name, created_by,
			status, verification_token, watermark, sent_to,
			values, activity_logs, approval_chain,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6,
			$7, $8, 'none', $9,
			$10, $11, $12,
			$13, $14
		)
		ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name,
			template_id = EXCLUDED.template_id,
			template_name = EXCLUDED.template_name,
			created_by = EXCLUDED.created_by,
			status = EXCLUDED.status,
			sent_to = EXCLUDED.sent_to,
			values = EXCLUDED.values,
			activity_logs = EXCLUDED.activity_logs,
			approval_chain = EXCLUDED.approval_chain,
			updated_at = EXCLUDED.updated_at
		RETURNING created_at, updated_at
	`
	err := r.db.QueryRowContext(ctx, insertDocQuery,
		doc.ID, orgID, safeTemplateID, doc.TemplateName, doc.Name, doc.CreatedBy,
		doc.Status, doc.VerificationToken, doc.SentTo,
		valuesJSON, logsJSON, chainJSON,
		now, now,
	).Scan(&doc.CreatedAt, &doc.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("insert document failed: %w", err)
	}

	return doc, nil
}

// UpdateDocument updates document metadata and syncs JSONB values
func (r *DocumentRepository) UpdateDocument(ctx context.Context, id string, patch *model.Document) (*model.Document, error) {
	now := time.Now()

	var valuesJSON, logsJSON, chainJSON []byte
	if patch.Values != nil {
		valuesJSON, _ = json.Marshal(patch.Values)
	}
	if patch.ActivityLogs != nil {
		logsJSON, _ = json.Marshal(patch.ActivityLogs)
	}
	if patch.ApprovalChain != nil {
		chainJSON, _ = json.Marshal(patch.ApprovalChain)
	}

	updateQuery := `
		UPDATE documents
		SET name = COALESCE(NULLIF($2, ''), name),
		    template_id = COALESCE(NULLIF($3, ''), template_id),
		    template_name = COALESCE(NULLIF($4, ''), template_name),
		    status = COALESCE(NULLIF($5, ''), status),
		    sent_to = COALESCE($6, sent_to),
		    values = CASE WHEN $7::jsonb IS NOT NULL THEN $7::jsonb ELSE values END,
		    activity_logs = CASE WHEN $8::jsonb IS NOT NULL THEN $8::jsonb ELSE activity_logs END,
		    approval_chain = CASE WHEN $9::jsonb IS NOT NULL THEN $9::jsonb ELSE approval_chain END,
		    updated_at = $10
		WHERE id = $1 AND deleted_at IS NULL
	`
	res, err := r.db.ExecContext(ctx, updateQuery,
		id, patch.Name, patch.TemplateID, patch.TemplateName, patch.Status, patch.SentTo,
		valuesJSON, logsJSON, chainJSON, now,
	)
	if err != nil {
		return nil, fmt.Errorf("update document failed: %w", err)
	}
	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		return nil, nil
	}

	return r.GetDocumentByID(ctx, id)
}

// DeleteDocument soft-deletes a document
func (r *DocumentRepository) DeleteDocument(ctx context.Context, id string) error {
	query := `UPDATE documents SET deleted_at = CURRENT_TIMESTAMP WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, id)
	return err
}

// RecordAction adds an activity log entry
func (r *DocumentRepository) RecordAction(ctx context.Context, id string, action string, format string, recipient string) error {
	logID := fmt.Sprintf("act-%d", time.Now().UnixNano())
	details := fmt.Sprintf("ดำเนินการ: %s", action)
	if format != "" {
		details += fmt.Sprintf(" (%s)", format)
	}
	if recipient != "" {
		details += fmt.Sprintf(" ส่งไปยัง %s", recipient)
	}
	logEntry := model.ActivityLog{
		ID:          logID,
		Action:      action,
		PerformedBy: "User",
		Timestamp:   time.Now(),
		Details:     details,
	}
	logBytes, _ := json.Marshal([]model.ActivityLog{logEntry})

	query := `
		UPDATE documents
		SET activity_logs = activity_logs || $2::jsonb,
		    updated_at = CURRENT_TIMESTAMP
		WHERE id = $1
	`
	_, err := r.db.ExecContext(ctx, query, id, logBytes)
	return err
}
