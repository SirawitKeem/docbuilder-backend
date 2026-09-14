package repository

import (
	"context"
	"database/sql"
	"fmt"

	"docbuilder-backend/internal/model"
)

type SentHistoryRepository struct {
	db *sql.DB
}

func NewSentHistoryRepository(db *sql.DB) *SentHistoryRepository {
	return &SentHistoryRepository{db: db}
}

func (r *SentHistoryRepository) GetAllSentHistory(ctx context.Context) ([]model.SentHistory, error) {
	query := `
		SELECT s.id, s.document_id, COALESCE(s.document_name, d.name, 'เอกสารไม่มีชื่อ'),
		       COALESCE(s.recipient_email, ''), COALESCE(s.subject, ''), COALESCE(s.message, ''),
		       COALESCE(s.sent_by, 'System'), COALESCE(s.status, 'success'),
		       COALESCE(s.action_type, 'email'), COALESCE(s.format, 'pdf'), COALESCE(s.channel, 'email'),
		       s.sent_at
		FROM sent_history s
		LEFT JOIN documents d ON s.document_id = d.id
		ORDER BY s.sent_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("query sent history failed: %w", err)
	}
	defer rows.Close()

	var history []model.SentHistory
	for rows.Next() {
		var h model.SentHistory
		var docID sql.NullString
		err := rows.Scan(
			&h.ID, &docID, &h.DocumentName, &h.RecipientEmail, &h.Subject, &h.Message,
			&h.SentBy, &h.Status, &h.ActionType, &h.Format, &h.Channel, &h.SentAt,
		)
		if err != nil {
			return nil, err
		}
		if docID.Valid {
			h.DocumentID = &docID.String
		}
		history = append(history, h)
	}

	return history, nil
}

func (r *SentHistoryRepository) DeleteSentHistory(ctx context.Context, id string) error {
	res, err := r.db.ExecContext(ctx, "DELETE FROM sent_history WHERE id = $1", id)
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
