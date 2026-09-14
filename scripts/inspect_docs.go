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

	rows, err := db.Query("SELECT id, watermark, status FROM documents")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()

	for rows.Next() {
		var id, wm, st sql.NullString
		rows.Scan(&id, &wm, &st)
		fmt.Printf("id: %s | watermark: [%s] (valid:%v) | status: [%s] (valid:%v)\n",
			id.String, wm.String, wm.Valid, st.String, st.Valid)
	}
}
