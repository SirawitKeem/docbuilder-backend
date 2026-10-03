package model

import (
	"time"

	"github.com/google/uuid"
)

// User represents a user in the system
type User struct {
	ID               uuid.UUID  `json:"id" db:"id"`
	OrgID            uuid.UUID  `json:"orgId" db:"org_id"`
	FullName         string     `json:"fullName" db:"full_name"`
	Email            string     `json:"email" db:"email"`
	Role             string     `json:"role" db:"role"`
	RoleID           uuid.UUID  `json:"roleId" db:"role_id"`
	Avatar           *string    `json:"avatar" db:"avatar"`
	TwoFactorEnabled bool       `json:"twoFactorEnabled" db:"two_factor_enabled"`
	CreatedAt        time.Time  `json:"createdAt" db:"created_at"`
	UpdatedAt        time.Time  `json:"updatedAt" db:"updated_at"`

	// Joined fields
	RoleDetails *Role `json:"roleDetails,omitempty"`
}
