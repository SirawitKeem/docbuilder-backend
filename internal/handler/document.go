package handler

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"docbuilder-backend/internal/model"
	"docbuilder-backend/internal/repository"
	"docbuilder-backend/pkg/response"
)

type DocumentHandler struct {
	repo *repository.DocumentRepository
}

func NewDocumentHandler(repo *repository.DocumentRepository) *DocumentHandler {
	return &DocumentHandler{repo: repo}
}

// ListDocuments handles GET /api/v1/documents and /api/documents
func (h *DocumentHandler) ListDocuments(w http.ResponseWriter, r *http.Request) {
	docs, err := h.repo.GetAllDocuments(r.Context())
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to retrieve documents: "+err.Error())
		return
	}
	response.Success(w, http.StatusOK, docs, "Documents retrieved successfully")
}

// GetDocumentByID handles GET /api/v1/documents/{id}
func (h *DocumentHandler) GetDocumentByID(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		response.Error(w, http.StatusBadRequest, "Document ID is required")
		return
	}

	doc, err := h.repo.GetDocumentByID(r.Context(), id)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to retrieve document: "+err.Error())
		return
	}
	if doc == nil {
		response.Error(w, http.StatusNotFound, "Document not found")
		return
	}

	response.Success(w, http.StatusOK, doc, "Document retrieved successfully")
}

// CreateDocument handles POST /api/v1/documents and /api/documents
func (h *DocumentHandler) CreateDocument(w http.ResponseWriter, r *http.Request) {
	var body model.Document
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		response.Error(w, http.StatusBadRequest, "Invalid request payload: "+err.Error())
		return
	}

	created, err := h.repo.CreateDocument(r.Context(), &body)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to create document: "+err.Error())
		return
	}

	response.Success(w, http.StatusCreated, created, "Document created successfully")
}

// UpdateDocument handles PUT /api/v1/documents/{id}
func (h *DocumentHandler) UpdateDocument(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		response.Error(w, http.StatusBadRequest, "Document ID is required")
		return
	}

	var body model.Document
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		response.Error(w, http.StatusBadRequest, "Invalid request payload: "+err.Error())
		return
	}

	updated, err := h.repo.UpdateDocument(r.Context(), id, &body)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to update document: "+err.Error())
		return
	}
	if updated == nil {
		response.Error(w, http.StatusNotFound, "Document not found")
		return
	}

	response.Success(w, http.StatusOK, updated, "Document updated successfully")
}

// DeleteDocument handles DELETE /api/v1/documents/{id}
func (h *DocumentHandler) DeleteDocument(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		response.Error(w, http.StatusBadRequest, "Document ID is required")
		return
	}

	err := h.repo.DeleteDocument(r.Context(), id)
	if err != nil {
		if err == sql.ErrNoRows {
			response.Error(w, http.StatusNotFound, "Document not found")
			return
		}
		response.Error(w, http.StatusInternalServerError, "Failed to delete document: "+err.Error())
		return
	}

	response.Success(w, http.StatusOK, map[string]string{"id": id}, "Document deleted successfully")
}

// RecordAction handles POST /api/v1/documents/{id}/actions
func (h *DocumentHandler) RecordAction(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	var body struct {
		Action    string `json:"action"`
		Format    string `json:"format"`
		Recipient string `json:"recipientEmail"`
	}
	_ = json.NewDecoder(r.Body).Decode(&body)

	err := h.repo.RecordAction(r.Context(), id, body.Action, body.Format, body.Recipient)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to record action: "+err.Error())
		return
	}

	response.Success(w, http.StatusOK, true, "Action recorded successfully")
}
