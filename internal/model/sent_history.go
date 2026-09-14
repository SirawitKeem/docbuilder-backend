package model

import "time"

type SentHistory struct {
	ID             string    `json:"id"`
	DocumentID     *string   `json:"documentId,omitempty"`
	DocumentName   string    `json:"documentName"`
	RecipientEmail string    `json:"recipientEmail"`
	Subject        string    `json:"subject"`
	Message        string    `json:"message"`
	SentBy         string    `json:"sentBy"`
	Status         string    `json:"status"`
	ActionType     string    `json:"actionType"` // email, export, print
	Format         string    `json:"format"`     // pdf, etc.
	Channel        string    `json:"channel"`
	SentAt         time.Time `json:"sentAt"`
}
