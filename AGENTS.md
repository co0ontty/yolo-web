# Repository Guidelines

## Project Structure & Module Organization

```
vibe-coding/
├── server/          # Go backend (WebSocket, session management, HTTP API)
│   ├── cmd/              # Main entry point
│   ├── internal/         # Core packages
│   │   ├── handler/       # WebSocket and HTTP handlers
│   │   ├── model/         # Data models (Session, Message, ChatRequest)
│   │   ├── store/         # JSON file-based session storage
│   │   └── auth/          # Authentication logic
│   └── Dockerfile         # Production Docker image
├── cli/             # Go CLI worker (spawns Claude Code CLI)
│   ├── cmd/              # Main entry point
│   └── internal/         # CLI internals
├── frontend/        # React + Vite frontend
│   └── src/              # React components and app logic
└── certs/           # SSL certificates (generated)
```

## Build, Test, and Development Commands

**Full Build & Deploy:**
```bash
./build.sh             # Build CLI (multi-platform), frontend, Docker image
docker compose up -d   # Start on port 8118 (HTTP) / 8443 (HTTPS)
```

**Server (Go):**
```bash
cd server
go run cmd/main.go           # Development (port 3100)
go build -o vibe-server ./cmd  # Build binary
```

**CLI Worker (Go):**
```bash
cd cli
go build -o vibe-cli ./cmd
./vibe-cli -server ws://localhost:3100/ws/cli
```

**Frontend (React + Vite):**
```bash
cd frontend
npm install
npm run dev     # Development server
npm run build   # Production build → dist/
```

## Coding Style & Naming Conventions

- **Go:** Standard gofmt formatting; package names are lowercase single words
- **JavaScript/React:** ES6+ syntax; components use PascalCase
- **WebSocket message types:** snake_case (e.g., create_session, message_complete)
- **Environment variables:** UPPER_SNAKE_CASE (e.g., YOLO_SERVER_WS, WEB_AUTH_ENABLED)

## Testing Guidelines

No automated tests currently exist. When adding tests:
- Go: Place *_test.go files alongside source code
- Frontend: Use Vitest (Vite-compatible) with *.test.js or *.spec.js naming

## Commit & Pull Request Guidelines

**Commit Message Format:**
- Use conventional commit prefixes: chore:, docs:, feat:, fix:
- Keep messages concise and descriptive
- Examples from history:
  - chore: 更新子模块引用
  - docs: 更新 HTTPS/SSL 部署文档和配置
  - feat: 添加 Web 认证配置示例

**Pull Requests:**
- Reference related issues when applicable
- Include clear description of changes
- Test both Docker deployment and local development

## Architecture Notes

- **WebSocket Protocol:** Frontend ↔ Server ↔ CLI communication via JSON messages
- **Session Storage:** JSON file at data/sessions.json (or /app/data in Docker)
- **Permission Modes:** default, acceptEdits, yolo (controls Claude Code permission prompts)
- **Authentication:** Token-based session auth (24-hour expiry); configure via WEB_AUTH_ENABLED and WEB_AUTH_PASSWORD
