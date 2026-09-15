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

	var count int
	err = db.QueryRow("SELECT COUNT(*) FROM organization_signatories").Scan(&count)
	if err != nil {
		fmt.Printf("organization_signatories error: %v\n", err)
		return
	}
	fmt.Printf("organization_signatories count: %d\n", count)

	rows, err := db.Query("SELECT id, org_id, signatory_name, signatory_title FROM organization_signatories")
	if err != nil {
		fmt.Printf("query error: %v\n", err)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var id, orgID, name, title string
		rows.Scan(&id, &orgID, &name, &title)
		fmt.Printf("Row: id=%s, name=%s, title=%s\n", id, name, title)
	}
}
