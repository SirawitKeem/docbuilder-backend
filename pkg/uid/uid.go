// Package uid provides application-wide helpers for generating IDs and secure tokens.
//
// ID strategy:
//   - NewID()                → UUIDv7 string (time-ordered, globally unique, safe for varchar(64) columns)
//   - NewVerificationToken() → 128-bit crypto/rand hex with "VRF-" prefix (unpredictable, safe for public links)
//
// UUIDv7 is used instead of v4 because it embeds a millisecond timestamp in the first 48 bits,
// so rows INSERT in time-order, keeping B-tree indexes tight and range scans fast.
// Within the same millisecond, google/uuid applies a monotonic counter so IDs never collide
// even under high concurrency inside a single process.
//
// VerificationToken must NOT use UUIDv7 — the time prefix is guessable.
// crypto/rand gives 128 bits of true entropy which is sufficient for document verification links.
package uid

import (
	cryptorand "crypto/rand"
	"encoding/hex"
	"fmt"

	"github.com/google/uuid"
)

// NewID returns a new UUIDv7 string (e.g. "018f3c5e-7b2a-7000-8000-abcdef012345").
// It panics only if the OS random source is broken, which should never happen in production.
func NewID() string {
	return uuid.Must(uuid.NewV7()).String()
}

// NewVerificationToken returns a cryptographically random 128-bit token
// formatted as "VRF-<32 uppercase hex chars>" (e.g. "VRF-A3F1...").
// Total entropy: 128 bits — suitable for document verification URLs.
func NewVerificationToken() string {
	b := make([]byte, 16)
	if _, err := cryptorand.Read(b); err != nil {
		// OS-level failure — nothing we can do, panic is correct here.
		panic(fmt.Sprintf("uid: crypto/rand unavailable: %v", err))
	}
	return "VRF-" + hex.EncodeToString(b)
}
