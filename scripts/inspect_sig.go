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

	rows, err := db.Query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name='organization_signatories' ORDER BY ordinal_position")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	fmt.Println("=== Columns in organization_signatories ===")
	for rows.Next() {
		var col, dt string
		rows.Scan(&col, &dt)
		fmt.Printf("  %s (%s)\n", col, dt)
	}

	rows2, err := db.Query("SELECT * FROM organization_signatories")
	if err != nil {
		log.Fatal(err)
	}
	defer rows2.Close()
	cols, _ := rows2.Columns()
	fmt.Println("\n=== Rows in organization_signatories ===")
	for rows2.Next() {
		vals := make([]interface{}, len(cols))
		ptrs := make([]interface{}, len(cols))
		for i := range vals {
			ptrs[i] = &vals[i]
		}
		rows2.Scan(ptrs...)
		for i, c := range cols {
			fmt.Printf("  %s: %v\n", c, vals[i])
		}
	}
}
