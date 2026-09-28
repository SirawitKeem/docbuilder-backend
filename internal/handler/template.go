package handler

import (
	"encoding/json"
	"net/http"

	"docbuilder-backend/internal/model"
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

// CreateTemplate handles POST /api/v1/templates
func (h *TemplateHandler) CreateTemplate(w http.ResponseWriter, r *http.Request) {
	var req model.CustomTemplate
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Error(w, http.StatusBadRequest, "Invalid request body: "+err.Error())
		return
	}

	if req.Name == "" {
		response.Error(w, http.StatusBadRequest, "Template name is required")
		return
	}

	created, err := h.repo.CreateTemplate(r.Context(), &req)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to create template: "+err.Error())
		return
	}

	response.Success(w, http.StatusCreated, created, "Template created successfully")
}

// UpdateTemplate handles PUT /api/v1/templates/{id}
func (h *TemplateHandler) UpdateTemplate(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		response.Error(w, http.StatusBadRequest, "Template ID is required")
		return
	}

	var req model.CustomTemplate
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Error(w, http.StatusBadRequest, "Invalid request body: "+err.Error())
		return
	}

	updated, err := h.repo.UpdateTemplate(r.Context(), id, &req)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to update template: "+err.Error())
		return
	}
	if updated == nil {
		response.Error(w, http.StatusNotFound, "Template not found")
		return
	}

	response.Success(w, http.StatusOK, updated, "Template updated successfully")
}

// DeleteTemplate handles DELETE /api/v1/templates/{id}
func (h *TemplateHandler) DeleteTemplate(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		response.Error(w, http.StatusBadRequest, "Template ID is required")
		return
	}

	err := h.repo.DeleteTemplate(r.Context(), id)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to delete template: "+err.Error())
		return
	}

	response.Success(w, http.StatusOK, nil, "Template deleted successfully")
}
