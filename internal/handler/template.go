package handler

import (
	"net/http"

	"docbuilder-backend/internal/repository"
	"docbuilder-backend/pkg/response"
)

type TemplateHandler struct {
	repo *repository.TemplateRepository
}

func NewTemplateHandler(repo *repository.TemplateRepository) *TemplateHandler {
	return &TemplateHandler{repo: repo}
}

// ListTemplates handles GET /api/v1/templates
func (h *TemplateHandler) ListTemplates(w http.ResponseWriter, r *http.Request) {
	templates, err := h.repo.GetAllTemplates(r.Context())
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to retrieve templates: "+err.Error())
		return
	}
	response.Success(w, http.StatusOK, templates, "Templates retrieved successfully")
}

// GetTemplateByID handles GET /api/v1/templates/{id}
func (h *TemplateHandler) GetTemplateByID(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		response.Error(w, http.StatusBadRequest, "Template ID is required")
		return
	}

	tmpl, err := h.repo.GetTemplateByID(r.Context(), id)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to retrieve template: "+err.Error())
		return
	}
	if tmpl == nil {
		response.Error(w, http.StatusNotFound, "Template not found")
		return
	}

	response.Success(w, http.StatusOK, tmpl, "Template retrieved successfully")
}
