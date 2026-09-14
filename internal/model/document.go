package model

import "time"

type Document struct {
	ID                string                 `json:"id"`
	VerificationToken string                 `json:"verificationToken"`
	ProfileID         *string                `json:"profileId,omitempty"`
	Name              string                 `json:"name"`
	TemplateID        string                 `json:"templateId"`
	TemplateName      string                 `json:"templateName"`
	CreatedBy         string                 `json:"createdBy"`
	CreatedAt         time.Time              `json:"createdAt"`
	UpdatedAt         time.Time              `json:"updatedAt"`
	Status            string                 `json:"status"` // draft, sent, exported, pending_approval
	SentTo            *string                `json:"sentTo,omitempty"`
	LastSentAt        *time.Time             `json:"lastSentAt,omitempty"`
	Values            map[string]interface{} `json:"values"`
	ActivityLogs      []ActivityLog          `json:"activityLogs,omitempty"`
	ExportHistory     []ExportHistoryEntry   `json:"exportHistory,omitempty"`
}

type ActivityLog struct {
	ID          string    `json:"id"`
	Action      string    `json:"action"` // create, edit, export, email, approve, reject
	PerformedBy string    `json:"performedBy"`
	Timestamp   time.Time `json:"timestamp"`
	Details     string    `json:"details,omitempty"`
	Comment     string    `json:"comment,omitempty"`
}

type ExportHistoryEntry struct {
	ID          string    `json:"id"`
	Format      string    `json:"format"` // PDF, WEBP, HTML, PRINT
	ExportedAt  time.Time `json:"exportedAt"`
	PerformedBy string    `json:"performedBy"`
	Details     string    `json:"details,omitempty"`
}
