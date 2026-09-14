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

	fmt.Println("=== Organizations ===")
	orgRows, err := db.Query("SELECT id, name FROM organizations")
	if err == nil {
		for orgRows.Next() {
			var id, name string
			orgRows.Scan(&id, &name)
			fmt.Printf("org: %s (%s)\n", id, name)
		}
		orgRows.Close()
	}

	fmt.Println("\n=== Documents org_ids ===")
	docRows, err := db.Query("SELECT DISTINCT org_id FROM documents")
	if err == nil {
		for docRows.Next() {
			var orgID sql.NullString
			docRows.Scan(&orgID)
			fmt.Printf("doc org_id: %s (valid:%v)\n", orgID.String, orgID.Valid)
		}
		docRows.Close()
	}
}
