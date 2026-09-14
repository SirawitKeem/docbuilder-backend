package handler

import (
	"database/sql"
	"encoding/json"
	"net/http"

	"docbuilder-backend/internal/model"
	"docbuilder-backend/internal/repository"
	"docbuilder-backend/pkg/response"
)

type FieldProfileHandler struct {
	repo *repository.FieldProfileRepository
}

func NewFieldProfileHandler(repo *repository.FieldProfileRepository) *FieldProfileHandler {
	return &FieldProfileHandler{repo: repo}
}

func (h *FieldProfileHandler) ListProfiles(w http.ResponseWriter, r *http.Request) {
	profiles, err := h.repo.GetAllFieldProfiles(r.Context())
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to retrieve field profiles: "+err.Error())
		return
	}
	response.Success(w, http.StatusOK, profiles, "Field profiles retrieved successfully")
}

func (h *FieldProfileHandler) GetProfileByID(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		response.Error(w, http.StatusBadRequest, "Profile ID is required")
		return
	}

	profile, err := h.repo.GetFieldProfileByID(r.Context(), id)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to retrieve field profile: "+err.Error())
		return
	}
	if profile == nil {
		response.Error(w, http.StatusNotFound, "Field profile not found")
		return
	}

	response.Success(w, http.StatusOK, profile, "Field profile retrieved successfully")
}

func (h *FieldProfileHandler) CreateProfile(w http.ResponseWriter, r *http.Request) {
	var body model.FieldProfile
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		response.Error(w, http.StatusBadRequest, "Invalid payload: "+err.Error())
		return
	}

	created, err := h.repo.CreateFieldProfile(r.Context(), &body)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to create field profile: "+err.Error())
		return
	}

	response.Success(w, http.StatusCreated, created, "Field profile created successfully")
}

func (h *FieldProfileHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		response.Error(w, http.StatusBadRequest, "Profile ID is required")
		return
	}

	var body model.FieldProfile
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		response.Error(w, http.StatusBadRequest, "Invalid payload: "+err.Error())
		return
	}

	updated, err := h.repo.UpdateFieldProfile(r.Context(), id, &body)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to update field profile: "+err.Error())
		return
	}
	if updated == nil {
		response.Error(w, http.StatusNotFound, "Field profile not found")
		return
	}

	response.Success(w, http.StatusOK, updated, "Field profile updated successfully")
}

func (h *FieldProfileHandler) DeleteProfile(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		response.Error(w, http.StatusBadRequest, "Profile ID is required")
		return
	}

	err := h.repo.DeleteFieldProfile(r.Context(), id)
	if err != nil {
		if err == sql.ErrNoRows {
			response.Error(w, http.StatusNotFound, "Field profile not found")
			return
		}
		response.Error(w, http.StatusInternalServerError, "Failed to delete field profile: "+err.Error())
		return
	}

	response.Success(w, http.StatusOK, map[string]string{"id": id}, "Field profile deleted successfully")
}
