package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

func main() {
	db, err := sql.Open("postgres", "postgres://wawa:S0lut!0n@192.168.3.164:5432/docbuilder?sslmode=disable")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	tables := []string{
		"documents",
		"document_field_values",
		"document_tables",
		"document_table_rows",
		"templates",
		"template_versions",
		"template_blocks",
		"categories",
		"organizations",
		"settings",
		"field_profiles",
		"field_profile_values",
		"sent_history",
		"document_activity_logs",
	}

	fmt.Println("=== ROW COUNTS IN POSTGRESQL (SERVER wawa) ===")
	for _, t := range tables {
		var count int
		err := db.QueryRow(fmt.Sprintf("SELECT COUNT(*) FROM %s", t)).Scan(&count)
		if err != nil {
			fmt.Printf("❌ %-25s: Error (%v)\n", t, err)
		} else {
			fmt.Printf("✅ %-25s: %d แถว\n", t, count)
		}
	}
}
