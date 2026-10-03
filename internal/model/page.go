package model

import (
	"time"

	"github.com/google/uuid"
)

// DocumentType represents a core document format specification
type DocumentType struct {
	ID                 uuid.UUID              `json:"id" db:"id"`
	Code               string                 `json:"code" db:"code"`
	Name               string                 `json:"name" db:"name"`
	ThaiName           string                 `json:"thaiName" db:"thai_name"`
	DefaultPresetID    *uuid.UUID             `json:"defaultPresetId,omitempty" db:"default_preset_id"`
	Icon               string                 `json:"icon" db:"icon"`
	Color              string                 `json:"color" db:"color"`
	Description        *string                `json:"description,omitempty" db:"description"`
	LayoutEngine       string                 `json:"layoutEngine" db:"layout_engine"`
	DefaultWidth       int                    `json:"defaultWidth" db:"default_width"`
	DefaultHeight      int                    `json:"defaultHeight" db:"default_height"`
	Unit               string                 `json:"unit" db:"unit"`
	DefaultOrientation string                 `json:"defaultOrientation" db:"default_orientation"`
	SupportedExports   []string               `json:"supportedExports" db:"supported_exports"`
	AllowedObjectTypes []string               `json:"allowedObjectTypes" db:"allowed_object_types"`
	IsActive           bool                   `json:"isActive" db:"is_active"`
	CreatedAt          time.Time              `json:"createdAt" db:"created_at"`
}

// TemplatePage represents a single page within a template
type TemplatePage struct {
	ID         uuid.UUID              `json:"id" db:"id"`
	TemplateID uuid.UUID              `json:"templateId" db:"template_id"`
	PageNumber int                    `json:"pageNumber" db:"page_number"`
	PageName   string                 `json:"pageName" db:"page_name"`
	Styles     map[string]interface{} `json:"styles" db:"styles"`
	Values     map[string]interface{} `json:"values" db:"values"`
	ContentHTML *string               `json:"contentHtml,omitempty" db:"content_html"`
	CanvasJSON map[string]interface{} `json:"canvasJson" db:"canvas_json"`
	SortOrder  int                    `json:"sortOrder" db:"sort_order"`
	CreatedAt  time.Time              `json:"createdAt" db:"created_at"`
	UpdatedAt  time.Time              `json:"updatedAt" db:"updated_at"`
}

// DocumentPage represents a single rendered page within a document
type DocumentPage struct {
	ID          uuid.UUID              `json:"id" db:"id"`
	DocumentID  uuid.UUID              `json:"documentId" db:"document_id"`
	PageNumber  int                    `json:"pageNumber" db:"page_number"`
	PageName    string                 `json:"pageName" db:"page_name"`
	Styles      map[string]interface{} `json:"styles" db:"styles"`
	Values      map[string]interface{} `json:"values" db:"values"`
	ContentHTML *string                `json:"contentHtml,omitempty" db:"content_html"`
	CanvasJSON  map[string]interface{} `json:"canvasJson" db:"canvas_json"`
	SortOrder   int                    `json:"sortOrder" db:"sort_order"`
	CreatedAt   time.Time              `json:"createdAt" db:"created_at"`
	UpdatedAt   time.Time              `json:"updatedAt" db:"updated_at"`
}
