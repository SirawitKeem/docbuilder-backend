package model

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
)

// Permissions represents JSONB map of capabilities
type Permissions map[string]bool

// Value implements driver.Valuer
func (p Permissions) Value() (driver.Value, error) {
	return json.Marshal(p)
}

// Scan implements sql.Scanner
func (p *Permissions) Scan(src interface{}) error {
	bytes, ok := src.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed for Permissions")
	}
	return json.Unmarshal(bytes, &p)
}

// Role represents a system role (RBAC)
type Role struct {
	ID            uuid.UUID   `json:"id" db:"id"`
	Name          string      `json:"name" db:"name"`
	DisplayNameTH string      `json:"displayNameTh" db:"display_name_th"`
	DisplayNameEN string      `json:"displayNameEn" db:"display_name_en"`
	Description   *string     `json:"description" db:"description"`
	HierarchyLevel int        `json:"hierarchyLevel" db:"hierarchy_level"`
	Permissions   Permissions `json:"permissions" db:"permissions"`
	IsSystem      bool        `json:"isSystem" db:"is_system"`
	CreatedAt     time.Time   `json:"createdAt" db:"created_at"`
	UpdatedAt     time.Time   `json:"updatedAt" db:"updated_at"`
}
