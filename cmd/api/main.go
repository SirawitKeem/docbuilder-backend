package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"docbuilder-backend/internal/config"
	"docbuilder-backend/internal/handler"
	"docbuilder-backend/internal/middleware"
	"docbuilder-backend/internal/repository"
)

func main() {
	cfg := config.Load()

	mux := http.NewServeMux()

	// Handlers
	healthHandler := handler.NewHealthHandler()

	// Health check routes
	mux.HandleFunc("GET /health", healthHandler.HealthCheck)
	mux.HandleFunc("GET /api/v1/health", healthHandler.HealthCheck)
	mux.HandleFunc("GET /api/health", healthHandler.HealthCheck)

	// Connect to PostgreSQL Database
	db, err := repository.ConnectDB(cfg.DatabaseURL)
	if err != nil {
		log.Printf("⚠️ Warning: PostgreSQL connection failed: %v", err)
		log.Println("💡 Please configure your DB credentials in docbuilder-backend/.env")
	} else {
		defer db.Close()

		tmplRepo := repository.NewTemplateRepository(db)
		docRepo := repository.NewDocumentRepository(db)
		profileRepo := repository.NewFieldProfileRepository(db)
		settingsRepo := repository.NewSettingsRepository(db)
		sentRepo := repository.NewSentHistoryRepository(db)

		tmplHandler := handler.NewTemplateHandler(tmplRepo)
		docHandler := handler.NewDocumentHandler(docRepo)
		profileHandler := handler.NewFieldProfileHandler(profileRepo)
		settingsHandler := handler.NewSettingsHandler(settingsRepo)
		sentHandler := handler.NewSentHistoryHandler(sentRepo)

		// Document Routes (Supporting both /api/v1/... and /api/...)
		mux.HandleFunc("GET /api/v1/documents", docHandler.ListDocuments)
		mux.HandleFunc("GET /api/documents", docHandler.ListDocuments)

		mux.HandleFunc("GET /api/v1/documents/{id}", docHandler.GetDocumentByID)
		mux.HandleFunc("GET /api/documents/{id}", docHandler.GetDocumentByID)

		mux.HandleFunc("POST /api/v1/documents", docHandler.CreateDocument)
		mux.HandleFunc("POST /api/documents", docHandler.CreateDocument)

		mux.HandleFunc("PUT /api/v1/documents/{id}", docHandler.UpdateDocument)
		mux.HandleFunc("PUT /api/documents/{id}", docHandler.UpdateDocument)

		mux.HandleFunc("DELETE /api/v1/documents/{id}", docHandler.DeleteDocument)
		mux.HandleFunc("DELETE /api/documents/{id}", docHandler.DeleteDocument)

		mux.HandleFunc("POST /api/v1/documents/{id}/actions", docHandler.RecordAction)
		mux.HandleFunc("POST /api/documents/{id}/actions", docHandler.RecordAction)

		// Template Routes
		mux.HandleFunc("GET /api/v1/templates", tmplHandler.ListTemplates)
		mux.HandleFunc("GET /api/templates", tmplHandler.ListTemplates)

		mux.HandleFunc("GET /api/v1/templates/{id}", tmplHandler.GetTemplateByID)
		mux.HandleFunc("GET /api/templates/{id}", tmplHandler.GetTemplateByID)

		// Field Profile (Data Presets) Routes
		mux.HandleFunc("GET /api/v1/field-profiles", profileHandler.ListProfiles)
		mux.HandleFunc("GET /api/field-profiles", profileHandler.ListProfiles)

		mux.HandleFunc("GET /api/v1/field-profiles/{id}", profileHandler.GetProfileByID)
		mux.HandleFunc("GET /api/field-profiles/{id}", profileHandler.GetProfileByID)

		mux.HandleFunc("POST /api/v1/field-profiles", profileHandler.CreateProfile)
		mux.HandleFunc("POST /api/field-profiles", profileHandler.CreateProfile)

		mux.HandleFunc("PUT /api/v1/field-profiles/{id}", profileHandler.UpdateProfile)
		mux.HandleFunc("PUT /api/field-profiles/{id}", profileHandler.UpdateProfile)

		mux.HandleFunc("DELETE /api/v1/field-profiles/{id}", profileHandler.DeleteProfile)
		mux.HandleFunc("DELETE /api/field-profiles/{id}", profileHandler.DeleteProfile)

		// Settings Routes
		mux.HandleFunc("GET /api/v1/settings", settingsHandler.GetSettings)
		mux.HandleFunc("GET /api/settings", settingsHandler.GetSettings)

		mux.HandleFunc("PATCH /api/v1/settings", settingsHandler.UpdateSettings)
		mux.HandleFunc("PATCH /api/settings", settingsHandler.UpdateSettings)

		// Sent History Routes
		mux.HandleFunc("GET /api/v1/sent-history", sentHandler.ListSentHistory)
		mux.HandleFunc("GET /api/sent-history", sentHandler.ListSentHistory)

		mux.HandleFunc("DELETE /api/v1/sent-history", sentHandler.DeleteSentHistory)
		mux.HandleFunc("DELETE /api/sent-history", sentHandler.DeleteSentHistory)
	}

	// Wrap with CORS Middleware
	corsHandler := middleware.EnableCORS(cfg.FrontendURL, mux)

	server := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      corsHandler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown channel
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("🚀 DocBuilder Go Backend Server is starting on port %s (%s)", cfg.Port, cfg.Environment)
		log.Printf("🔗 Health check available at: http://localhost:%s/health", cfg.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("❌ Server listen error: %s\n", err)
		}
	}()

	<-stop
	log.Println("🛑 Shutting down server gracefully...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("❌ Server forced shutdown: %s\n", err)
	}

	fmt.Println("✅ Server gracefully stopped.")
}
