package handler

import (
	"database/sql"
	"net/http"

	"docbuilder-backend/internal/repository"
	"docbuilder-backend/pkg/response"
)

type SentHistoryHandler struct {
	repo *repository.SentHistoryRepository
}

func NewSentHistoryHandler(repo *repository.SentHistoryRepository) *SentHistoryHandler {
	return &SentHistoryHandler{repo: repo}
}

func (h *SentHistoryHandler) ListSentHistory(w http.ResponseWriter, r *http.Request) {
	history, err := h.repo.GetAllSentHistory(r.Context())
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to retrieve sent history: "+err.Error())
		return
	}
	response.Success(w, http.StatusOK, history, "Sent history retrieved successfully")
}

func (h *SentHistoryHandler) DeleteSentHistory(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if id == "" {
		id = r.PathValue("id")
	}
	if id == "" {
		response.Error(w, http.StatusBadRequest, "History ID is required")
		return
	}

	err := h.repo.DeleteSentHistory(r.Context(), id)
	if err != nil {
		if err == sql.ErrNoRows {
			response.Error(w, http.StatusNotFound, "Sent history record not found")
			return
		}
		response.Error(w, http.StatusInternalServerError, "Failed to delete history record: "+err.Error())
		return
	}

	response.Success(w, http.StatusOK, map[string]string{"id": id}, "Sent history record deleted successfully")
}
