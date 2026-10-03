//go:build ignore

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

	tables := []string{"templates", "template_versions", "documents"}
	for _, t := range tables {
		rows, err := db.Query("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name=$1 ORDER BY ordinal_position", t)
		if err != nil {
			log.Fatal(err)
		}
		fmt.Printf("\n=== %s ===\n", t)
		for rows.Next() {
			var col, dt, null string
			rows.Scan(&col, &dt, &null)
			fmt.Printf("  %s (%s, null:%s)\n", col, dt, null)
		}
		rows.Close()
	}
}
