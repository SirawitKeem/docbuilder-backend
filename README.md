# DocBuilder Backend (Golang)

High-performance Go API Server for the DocBuilder Enterprise Document Management Platform.

## 📁 Architecture Overview

```text
docbuilder-backend/
├── cmd/
│   └── api/
│       └── main.go          # Server entry point
├── internal/
│   ├── config/              # Environment config loader
│   ├── handler/             # HTTP Route Handlers (Controller layer)
│   ├── middleware/          # CORS, Auth, Logger middlewares
│   ├── model/               # Data Structs & Entities
│   ├── repository/          # Database Query & Store Abstraction
│   └── service/             # Business Logic Layer
├── pkg/
│   └── response/            # Standard JSON Response Helper
├── migrations/              # PostgreSQL DDL Migrations
├── .env.example             # Configuration Template
└── go.mod                   # Go Module definition
```

## 🚀 Getting Started

### Prerequisites
- Go 1.22+ (Installed: Go 1.26)
- PostgreSQL (or Supabase / Neon connection)

### Running Locally
```bash
# 1. Run server directly
go run cmd/api/main.go

# 2. Or compile binary
go build -o bin/server.exe cmd/api/main.go
./bin/server.exe
```

### Healthcheck
- `GET http://localhost:8080/health`
- `GET http://localhost:8080/api/v1/health`
