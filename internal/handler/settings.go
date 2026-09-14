package handler

import (
	"encoding/json"
	"net/http"

	"docbuilder-backend/internal/repository"
	"docbuilder-backend/pkg/response"
)

type SettingsHandler struct {
	repo *repository.SettingsRepository
}

func NewSettingsHandler(repo *repository.SettingsRepository) *SettingsHandler {
	return &SettingsHandler{repo: repo}
}

func (h *SettingsHandler) GetSettings(w http.ResponseWriter, r *http.Request) {
	settings, err := h.repo.GetSettings(r.Context(), "org-crestzendo")
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to retrieve settings: "+err.Error())
		return
	}
	response.Success(w, http.StatusOK, settings, "Settings retrieved successfully")
}

func (h *SettingsHandler) UpdateSettings(w http.ResponseWriter, r *http.Request) {
	var patch map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
		response.Error(w, http.StatusBadRequest, "Invalid settings payload: "+err.Error())
		return
	}

	updated, err := h.repo.UpdateSettings(r.Context(), "org-crestzendo", patch)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to update settings: "+err.Error())
		return
	}

	response.Success(w, http.StatusOK, updated, "Settings updated successfully")
}
