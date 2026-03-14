# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A "Vibe Coding" application - a Claude Code session manager with a web UI. Users create multiple working sessions (each with a specified directory and permission mode) and interact with Claude Code through a browser-based chat interface.

## Architecture

**Unified Architecture (Single Docker Image):**
```
┌───────────────────────────────────────────┐
│              Docker Container             │
│  ┌─────────┐          ┌──────────────┐  │
│  │  nginx  │ ───────► │  Go server   │  │
│  │(port 80 │          │  (:3100)     │  │
│  │ 443 ssl)│          └──────────────┘  │
│  └─────────┘                            │
│         │                               │
│         ├── / → React frontend (dist/web)│
│         ├── /cli/ → CLI downloads        │
│         └── /ws → proxy to Go server     │
└───────────────────────────────────────────┘
```

**Components:**
- `server/`: Go backend - WebSocket connections, session state management, SQLite persistence
- `cli/`: Go worker that spawns Claude Code CLI to execute tasks
- `frontend/`: React + Vite frontend
- `server/internal/handler/`: WebSocket and HTTP request handlers
- `server/internal/model/`: Data models (Session, Message, ChatRequest, StreamResponse)
- `server/internal/store/`: SQLite-based session storage
- `server/internal/auth/`: Token-based authentication management

**Server Entry Point:** `server/cmd/main.go`
- Initializes auth manager with session cleanup (every 10 minutes)
- Sets up WebSocket handlers (`/ws`, `/ws/cli`)
- API endpoints: `/api/login`, `/api/logout`, `/api/check-session`, `/api/list-dirs`, `/health`

**CLI Entry Point:** `cli/cmd/main.go`
- Supports `version`, `help` commands
- Connects to server via WebSocket and executes tasks

## Commands

### Quick Start

**首次启动（生成自签名证书）:**
```bash
./server/gen-cert.sh   # 生成自签名证书（仅首次）
./build.sh             # Build CLI (multi-platform), frontend, Docker image
docker compose up -d   # Start service on port 8443 (HTTPS)
docker compose logs -f
```

**访问地址:**
- HTTPS: `https://localhost:8443` 或 `https://你的 IP:8443`

**注意:** 自签名证书会在浏览器显示安全警告，点击"继续访问"即可。生产环境请替换为正式证书。

### Development

**Server:**
```bash
cd server
go run cmd/main.go           # Run server (port 3100 or $PORT)
go build -o vibe-server ./cmd
```

**CLI Worker:**
```bash
cd cli
go build -o vibe-cli ./cmd
./vibe-cli -server ws://localhost:3100/ws/cli
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev     # Vite dev server
npm run build   # Production build → dist/
```

**Docker:**
```bash
cd server && docker build -t vibe-coding:latest .  # Build image
docker compose up -d                               # Run (port 8443)
docker compose down                                # Stop
```

## Key Conventions

**Message Types (WebSocket):**
- `create_session`, `delete_session`, `chat`, `stop` - frontend → server
- `execute_task`, `stop` - server → CLI
- `stream`, `message_complete`, `permission_request` - CLI → server → frontend
- `sessions` - broadcast from server to all frontends
- `cli_status` - server → frontend (CLI connection status)

**Authentication:**
- Token-based authentication (Session layer, not nginx basic auth)
- Login API: `POST /api/login` (body: `{ username, password }`)
- Logout API: `POST /api/logout`
- Check session: `GET /api/check-session`
- Token storage: localStorage
- WebSocket auth: URL parameter `?token=xxx`
- Token expiry: 24 hours
- Enable auth: Set `WEB_AUTH_ENABLED=true` and `WEB_AUTH_PASSWORD`

**Session Storage:**
- Persisted to `data/sessions.db` (SQLite database)
- Tracks: session ID, directory, permission mode, Claude token, message history

**Permission Modes:**
- `default`: Full permission prompts via UI
- `acceptEdits`: Auto-accept file edits, prompt for other operations
- `yolo`: Bypasses all permissions

**CLI Configuration:**
- `YOLO_SERVER_WS`: WebSocket address (e.g., `wss://192.168.0.7:8443/ws/cli`)
- `VIBE_SERVER`: HTTPS address (e.g., `https://192.168.0.7:8443`), automatically converted to WSS
- `CLI_AUTH_TOKEN`: Auth token (if server has auth enabled)

**自签名证书支持:**
- CLI configured with `InsecureSkipVerify: true` for self-signed certificates
- Suitable for development; replace with production certificates for deployment

## Coding Style

**Go:**
- Format with `gofmt`
- Lowercase package names, single-word where practical

**Frontend:**
- ES modules, React function components
- 2-space indentation, no semicolons unless required
- `PascalCase` for components, `camelCase` for variables/functions
- `snake_case` for WebSocket message types

**Environment Variables:**
- Use `UPPER_SNAKE_CASE`: `WEB_AUTH_ENABLED`, `WEB_AUTH_PASSWORD`, `CLAUDE_TOKEN`

## Dependencies

**Server:** `github.com/gorilla/websocket`, `github.com/mattn/go-sqlite3`
**CLI:** `github.com/gorilla/websocket`
**Frontend:** React 18, Vite 5
**Runtime:** Claude Code CLI required (`npm install -g @anthropic-ai/claude-code`)
