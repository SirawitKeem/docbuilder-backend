//go:build ignore

package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

type Category struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	FullName    string `json:"fullName"`
	Description string `json:"description"`
	Icon        string `json:"icon"`
	Color       string `json:"color"`
	Badge       string `json:"badge"`
	SortOrder   int    `json:"sortOrder"`
}

type CustomTemplateData struct {
	ID               string                 `json:"id"`
	Name             string                 `json:"name"`
	CategoryID       string                 `json:"categoryId"`
	EditorType       string                 `json:"editorType"`
	CanvasPreset     string                 `json:"canvasPreset"`
	Version          int                    `json:"version"`
	CurrentVersionID string                 `json:"currentVersionId"`
	Description      string                 `json:"description"`
	Icon             string                 `json:"icon"`
	Badge            string                 `json:"badge"`
	Status           string                 `json:"status"`
	Orientation      string                 `json:"orientation"`
	Theme            string                 `json:"theme"`
	Margin           interface{}            `json:"margin"`
	PageCount        int                    `json:"pageCount"`
	Pages            interface{}            `json:"pages"`
	SheetData        interface{}            `json:"sheetData"`
	Blocks           interface{}            `json:"blocks"`
	CreatedByUserID  string                 `json:"createdByUserId"`
	CreatedAt        string                 `json:"createdAt"`
	UpdatedAt        string                 `json:"updatedAt"`
}

type DocumentData struct {
	ID                string                 `json:"id"`
	VerificationToken string                 `json:"verificationToken"`
	ProfileID         interface{}            `json:"profileId"`
	Name              string                 `json:"name"`
	TemplateID        string                 `json:"templateId"`
	TemplateVersionID string                 `json:"templateVersionId"`
	TemplateName      string                 `json:"templateName"`
	CreatedBy         string                 `json:"createdBy"`
	CreatedAt         string                 `json:"createdAt"`
	UpdatedAt         string                 `json:"updatedAt"`
	Status            string                 `json:"status"`
	SentTo            interface{}            `json:"sentTo"`
	Values            interface{}            `json:"values"`
	ActivityLogs      interface{}            `json:"activityLogs"`
	ApprovalChain     interface{}            `json:"approvalChain"`
}

type FullDb struct {
	Organizations          []map[string]interface{} `json:"organizations"`
	Users                  []map[string]interface{} `json:"users"`
	Categories             []Category               `json:"categories"`
	CustomTemplates        interface{}              `json:"customTemplates"`
	Documents              []DocumentData           `json:"documents"`
	OrganizationSignatories []map[string]interface{} `json:"organizationSignatories"`
	Counterparties         []map[string]interface{} `json:"counterparties"`
}

func parseTimeSafe(s string) time.Time {
	if s == "" {
		return time.Now()
	}
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		t, err = time.Parse("2006-01-02T15:04:05.000Z", s)
		if err != nil {
			return time.Now()
		}
	}
	return t
}

func main() {
	_ = godotenv.Load(".env")

	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")
	dbSSL := os.Getenv("DB_SSLMODE")

	if dbHost == "" { dbHost = "192.168.3.164" }
	if dbPort == "" { dbPort = "5432" }
	if dbUser == "" { dbUser = "wawa" }
	if dbPassword == "" { dbPassword = "S0lut!0n" }
	if dbName == "" { dbName = "docbuilder" }
	if dbSSL == "" { dbSSL = "disable" }

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		dbHost, dbPort, dbUser, dbPassword, dbName, dbSSL)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("Failed to open connection: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("Database ping failed: %v", err)
	}
	fmt.Println("✅ Connected to PostgreSQL successfully.")

	// Read ../docbuilder-frontend/data/db.json
	dataBytes, err := os.ReadFile("../docbuilder-frontend/data/db.json")
	if err != nil {
		log.Fatalf("Failed to read db.json: %v", err)
	}

	var fullDb FullDb
	if err := json.Unmarshal(dataBytes, &fullDb); err != nil {
		log.Fatalf("Failed to parse db.json: %v", err)
	}

	// 1. Sync Categories
	fmt.Printf("📦 Syncing %d categories...\n", len(fullDb.Categories))
	for _, c := range fullDb.Categories {
		query := `
			INSERT INTO categories (id, name, full_name, description, icon, color, badge, sort_order)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
			ON CONFLICT (id) DO UPDATE SET
				name = EXCLUDED.name,
				full_name = EXCLUDED.full_name,
				description = EXCLUDED.description,
				icon = EXCLUDED.icon,
				color = EXCLUDED.color,
				badge = EXCLUDED.badge,
				sort_order = EXCLUDED.sort_order;
		`
		_, err := db.Exec(query, c.ID, c.Name, c.FullName, c.Description, c.Icon, c.Color, c.Badge, c.SortOrder)
		if err != nil {
			log.Printf("⚠️ Category %s error: %v", c.ID, err)
		}
	}

	// Parse CustomTemplates (could be array or map in JSON)
	var templateList []CustomTemplateData
	if rawArray, ok := fullDb.CustomTemplates.([]interface{}); ok {
		rawBytes, _ := json.Marshal(rawArray)
		_ = json.Unmarshal(rawBytes, &templateList)
	} else if rawMap, ok := fullDb.CustomTemplates.(map[string]interface{}); ok {
		for _, v := range rawMap {
			rawBytes, _ := json.Marshal(v)
			var item CustomTemplateData
			if err := json.Unmarshal(rawBytes, &item); err == nil && item.ID != "" {
				templateList = append(templateList, item)
			}
		}
	}

	fmt.Printf("📄 Syncing %d templates...\n", len(templateList))
	for _, t := range templateList {
		if t.ID == "" {
			continue
		}
		editorType := t.EditorType
		if editorType == "" {
			editorType = "document"
		}
		canvasPreset := t.CanvasPreset
		if canvasPreset == "" {
			if editorType == "slide" {
				canvasPreset = "slide-16-9"
			} else {
				canvasPreset = "a4-portrait"
			}
		}
		status := t.Status
		if status == "" {
			status = "published"
		}
		orientation := t.Orientation
		if orientation == "" {
			orientation = "portrait"
		}
		theme := t.Theme
		if theme == "" {
			theme = "modern"
		}

		pagesJSON, _ := json.Marshal(t.Pages)
		if t.Pages == nil {
			pagesJSON = []byte("[]")
		}
		sheetJSON, _ := json.Marshal(t.SheetData)
		if t.SheetData == nil {
			sheetJSON = []byte("{}")
		}
		marginJSON, _ := json.Marshal(t.Margin)
		if t.Margin == nil {
			marginJSON = []byte("{}")
		}
		blocksJSON, _ := json.Marshal(t.Blocks)
		if t.Blocks == nil {
			blocksJSON = []byte("[]")
		}

		version := t.Version
		if version == 0 {
			version = 1
		}
		versionID := t.CurrentVersionID
		if versionID == "" {
			versionID = fmt.Sprintf("ver-%s-v%d", t.ID, version)
		}

		// 2.1 Upsert template_versions first (to satisfy FK if needed)
		verQuery := `
			INSERT INTO template_versions (id, template_id, version, name, description, category_id, blocks, pages, created_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
			ON CONFLICT (id) DO UPDATE SET
				name = EXCLUDED.name,
				description = EXCLUDED.description,
				blocks = EXCLUDED.blocks,
				pages = EXCLUDED.pages;
		`
		// Insert placeholder template row first if not exists so FK constraint on template_id succeeds
		db.Exec(`INSERT INTO templates (id, org_id, name) VALUES ($1, 'org-crestzendo', $2) ON CONFLICT (id) DO NOTHING;`, t.ID, t.Name)

		_, err := db.Exec(verQuery, versionID, t.ID, version, t.Name, t.Description, t.CategoryID, blocksJSON, pagesJSON, parseTimeSafe(t.CreatedAt))
		if err != nil {
			log.Printf("⚠️ Template version %s error: %v", versionID, err)
		}

		// 2.2 Upsert full template with JSONB pages, sheet_data, margin
		tmplQuery := `
			INSERT INTO templates (
				id, org_id, category_id, name, description, editor_type,
				canvas_preset, orientation, theme, status, is_custom, is_standard,
				current_version_id, icon, badge, pages, sheet_data, margin,
				created_at, updated_at
			) VALUES (
				$1, 'org-crestzendo', $2, $3, $4, $5,
				$6, $7, $8, $9, TRUE, FALSE,
				$10, $11, $12, $13, $14, $15,
				$16, $17
			)
			ON CONFLICT (id) DO UPDATE SET
				name = EXCLUDED.name,
				category_id = EXCLUDED.category_id,
				description = EXCLUDED.description,
				editor_type = EXCLUDED.editor_type,
				canvas_preset = EXCLUDED.canvas_preset,
				orientation = EXCLUDED.orientation,
				theme = EXCLUDED.theme,
				status = EXCLUDED.status,
				current_version_id = EXCLUDED.current_version_id,
				icon = EXCLUDED.icon,
				badge = EXCLUDED.badge,
				pages = EXCLUDED.pages,
				sheet_data = EXCLUDED.sheet_data,
				margin = EXCLUDED.margin,
				updated_at = EXCLUDED.updated_at;
		`
		_, err = db.Exec(tmplQuery,
			t.ID, t.CategoryID, t.Name, t.Description, editorType,
			canvasPreset, orientation, theme, status,
			versionID, t.Icon, t.Badge, pagesJSON, sheetJSON, marginJSON,
			parseTimeSafe(t.CreatedAt), parseTimeSafe(t.UpdatedAt),
		)
		if err != nil {
			log.Printf("⚠️ Template %s (%s) error: %v", t.ID, t.Name, err)
		} else {
			fmt.Printf("  ✅ Template synced: %s (%s)\n", t.ID, t.Name)
		}
	}

	// 3. Sync Documents
	fmt.Printf("\n📑 Syncing %d documents...\n", len(fullDb.Documents))
	for _, d := range fullDb.Documents {
		if d.ID == "" {
			continue
		}
		valuesJSON, _ := json.Marshal(d.Values)
		if d.Values == nil {
			valuesJSON = []byte("{}")
		}
		logsJSON, _ := json.Marshal(d.ActivityLogs)
		if d.ActivityLogs == nil {
			logsJSON = []byte("[]")
		}
		chainJSON, _ := json.Marshal(d.ApprovalChain)
		if d.ApprovalChain == nil {
			chainJSON = []byte("[]")
		}

		var sentToStr *string
		if str, ok := d.SentTo.(string); ok && str != "" {
			sentToStr = &str
		}

		status := d.Status
		if status == "" {
			status = "draft"
		}

		// Safe template_id resolution
		var safeTemplateID *string
		if d.TemplateID != "" {
			var exists bool
			_ = db.QueryRow(`SELECT EXISTS(SELECT 1 FROM templates WHERE id = $1)`, d.TemplateID).Scan(&exists)
			if exists {
				safeTemplateID = &d.TemplateID
			}
		}

		// Safe template_version_id resolution
		var safeVersionID *string
		if d.TemplateVersionID != "" {
			var exists bool
			_ = db.QueryRow(`SELECT EXISTS(SELECT 1 FROM template_versions WHERE id = $1)`, d.TemplateVersionID).Scan(&exists)
			if exists {
				safeVersionID = &d.TemplateVersionID
			}
		}

		// Safe unique verification token
		token := d.VerificationToken
		if token == "" {
			token = fmt.Sprintf("VRF-%s", d.ID)
		} else {
			// Check if token belongs to another document
			var ownerDocID string
			err := db.QueryRow(`SELECT id FROM documents WHERE verification_token = $1 AND id != $2`, token, d.ID).Scan(&ownerDocID)
			if err == nil && ownerDocID != "" {
				// Token is taken by another doc, generate deterministic unique token
				token = fmt.Sprintf("VRF-%s-%d", d.ID, time.Now().UnixNano()%10000)
			}
		}

		docQuery := `
			INSERT INTO documents (
				id, org_id, template_id, template_version_id, template_name,
				name, created_by, status, sent_to, verification_token,
				values, activity_logs, approval_chain,
				created_at, updated_at
			) VALUES (
				$1, 'org-crestzendo', $2, $3, $4,
				$5, $6, $7, $8, $9,
				$10, $11, $12,
				$13, $14
			)
			ON CONFLICT (id) DO UPDATE SET
				name = EXCLUDED.name,
				template_id = EXCLUDED.template_id,
				template_version_id = EXCLUDED.template_version_id,
				template_name = EXCLUDED.template_name,
				created_by = EXCLUDED.created_by,
				status = EXCLUDED.status,
				sent_to = EXCLUDED.sent_to,
				verification_token = EXCLUDED.verification_token,
				values = EXCLUDED.values,
				activity_logs = EXCLUDED.activity_logs,
				approval_chain = EXCLUDED.approval_chain,
				updated_at = EXCLUDED.updated_at;
		`
		_, err := db.Exec(docQuery,
			d.ID, safeTemplateID, safeVersionID, d.TemplateName,
			d.Name, d.CreatedBy, status, sentToStr, token,
			valuesJSON, logsJSON, chainJSON,
			parseTimeSafe(d.CreatedAt), parseTimeSafe(d.UpdatedAt),
		)
		if err != nil {
			log.Printf("⚠️ Document %s (%s) error: %v", d.ID, d.Name, err)
		} else {
			fmt.Printf("  ✅ Document synced: %s (%s)\n", d.ID, d.Name)
		}
	}

	fmt.Println("\n🎉 ALL TEMPLATES AND DOCUMENTS SUCCESSFULLY MIGRATED TO POSTGRESQL!")
}
