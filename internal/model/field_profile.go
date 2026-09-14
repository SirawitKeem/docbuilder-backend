package model

import "time"

type FieldProfile struct {
	ID                  string                 `json:"id"`
	OrgID               *string                `json:"orgId,omitempty"`
	Name                string                 `json:"name"`
	ProfileType         string                 `json:"profileType"` // customer, counterparty, internal
	CounterpartyID      *string                `json:"counterpartyId,omitempty"`
	CompatibleTemplates []string               `json:"compatibleTemplates"`
	Fields              map[string]interface{} `json:"fields"`
	CreatedAt           time.Time              `json:"createdAt"`
	UpdatedAt           time.Time              `json:"updatedAt"`
}
