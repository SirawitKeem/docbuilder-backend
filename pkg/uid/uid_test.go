package uid

import (
	"strings"
	"sync"
	"testing"
)

func TestNewIDUnique(t *testing.T) {
	const count = 100000
	seen := make(map[string]struct{}, count)
	for i := 0; i < count; i++ {
		id := NewID()
		if len(id) != 36 {
			t.Fatalf("expected UUID length 36, got %d (%s)", len(id), id)
		}
		if _, dup := seen[id]; dup {
			t.Fatalf("duplicate ID generated at iteration %d: %s", i, id)
		}
		seen[id] = struct{}{}
	}
}

func TestNewIDConcurrent(t *testing.T) {
	const goroutines = 10
	const perGoroutine = 5000
	var mu sync.Mutex
	seen := make(map[string]struct{}, goroutines*perGoroutine)

	var wg sync.WaitGroup
	for g := 0; g < goroutines; g++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := 0; i < perGoroutine; i++ {
				id := NewID()
				mu.Lock()
				if _, dup := seen[id]; dup {
					t.Errorf("duplicate concurrent ID: %s", id)
				}
				seen[id] = struct{}{}
				mu.Unlock()
			}
		}()
	}
	wg.Wait()
}

func TestNewVerificationToken(t *testing.T) {
	seen := make(map[string]struct{}, 10000)
	for i := 0; i < 10000; i++ {
		token := NewVerificationToken()
		if !strings.HasPrefix(token, "VRF-") {
			t.Fatalf("expected VRF- prefix, got: %s", token)
		}
		// "VRF-" (4) + 16 bytes in hex (32) = 36 characters
		if len(token) != 36 {
			t.Fatalf("expected token length 36, got %d (%s)", len(token), token)
		}
		if _, dup := seen[token]; dup {
			t.Fatalf("duplicate token at %d: %s", i, token)
		}
		seen[token] = struct{}{}
	}
}
