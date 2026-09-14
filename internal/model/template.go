package model

import "time"

type TemplateCategory struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	FullName      string `json:"fullName"`
	Description   string `json:"description"`
	Color         string `json:"color"`
	Icon          string `json:"icon"`
	TemplateCount int    `json:"templateCount"`
}

type CustomTemplate struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	CategoryID  string                 `json:"categoryId"`
	Description string                 `json:"description"`
	Format      string                 `json:"format"` // docs (A4), slides (16:9), sheets
	Blocks      []TemplateBlock        `json:"blocks,omitempty"`
	Config      map[string]interface{} `json:"config,omitempty"`
	CreatedAt   time.Time              `json:"createdAt"`
	UpdatedAt   time.Time              `json:"updatedAt"`
}

type TemplateBlock struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"` // header, parties, clauses, table, signatures, text
	Content   string                 `json:"content,omitempty"`
	Order     int                    `json:"order"`
	PageBreak bool                   `json:"pageBreak,omitempty"`
	Props     map[string]interface{} `json:"props,omitempty"`
}
