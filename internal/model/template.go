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
	ID               string                 `json:"id"`
	Name             string                 `json:"name"`
	CategoryID       string                 `json:"categoryId"`
	Description      string                 `json:"description,omitempty"`
	EditorType       string                 `json:"editorType,omitempty"`       // document, slide, sheet
	Format           string                 `json:"format,omitempty"`           // legacy alias
	CanvasPreset     string                 `json:"canvasPreset,omitempty"`     // a4-portrait, slide-16-9, etc.
	Orientation      string                 `json:"orientation,omitempty"`      // portrait, landscape
	Theme            string                 `json:"theme,omitempty"`
	Status           string                 `json:"status,omitempty"`
	Icon             string                 `json:"icon,omitempty"`
	Badge            string                 `json:"badge,omitempty"`
	Version          int                    `json:"version,omitempty"`
	CurrentVersionID string                 `json:"currentVersionId,omitempty"`
	Margin           interface{}            `json:"margin,omitempty"`
	PageCount        int                    `json:"pageCount,omitempty"`
	Pages            interface{}            `json:"pages,omitempty"`          // Canvas Fabric.js pages JSON
	SheetData        interface{}            `json:"sheetData,omitempty"`        // Spreadsheet JSON
	Blocks           []TemplateBlock        `json:"blocks,omitempty"`
	Config           map[string]interface{} `json:"config,omitempty"`
	CreatedByUserID  string                 `json:"createdByUserId,omitempty"`
	CreatedAt        time.Time              `json:"createdAt"`
	UpdatedAt        time.Time              `json:"updatedAt"`
}

type TemplateBlock struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"` // header, parties, clauses, table, signatures, text
	Content   string                 `json:"content,omitempty"`
	Order     int                    `json:"order"`
	PageBreak bool                   `json:"pageBreak,omitempty"`
	Props     map[string]interface{} `json:"props,omitempty"`
}
