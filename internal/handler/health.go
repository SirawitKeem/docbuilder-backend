package handler

import (
	"net/http"
	"time"

	"docbuilder-backend/pkg/response"
)

type HealthHandler struct {
	StartTime time.Time
}

func NewHealthHandler() *HealthHandler {
	return &HealthHandler{StartTime: time.Now()}
}

func (h *HealthHandler) HealthCheck(w http.ResponseWriter, r *http.Request) {
	response.Success(w, http.StatusOK, map[string]interface{}{
		"status":    "healthy",
		"service":   "docbuilder-backend",
		"version":   "1.0.0",
		"uptime":    time.Since(h.StartTime).String(),
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	}, "DocBuilder Go Backend Service is running smoothly")
}
