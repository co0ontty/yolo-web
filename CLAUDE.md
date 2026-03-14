# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A "Vibe Coding" application - a Claude Code session manager with a web UI. Users create multiple working sessions (each with a specified directory and permission mode) and interact with Claude Code through a browser-based chat interface.

## Architecture

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

**Git Submodules:** `server/`, `cli/`, `frontend/` are independent git repositories. When making changes, commit within the submodule first, then update the parent repo's submodule reference.

**Components:**
- `server/`: Go backend - WebSocket hub, session state, SQLite persistence
- `cli/`: Go worker - spawns Claude Code CLI to execute tasks
- `frontend/`: React + Vite frontend

**Server Entry Point:** `server/cmd/main.go`
- WebSocket handlers: `/ws` (frontend), `/ws/cli` (worker)
- API endpoints: `/api/login`, `/api/logout`, `/api/check-session`, `/api/list-dirs`, `/health`

**CLI Entry Point:** `cli/cmd/main.go`

## Commands

```bash
# Full build (CLI multi-platform, frontend, Docker image) and start
./build.sh

# Server development
cd server && go run cmd/main.go           # Run on port 3100

# CLI development
cd cli && go build -o vibe-cli ./cmd
./vibe-cli -server ws://localhost:3100/ws/cli

# Frontend development
cd frontend && npm install && npm run dev

# Docker
docker compose up -d      # Start on port 8443 (HTTPS)
docker compose logs -f    # View logs
docker compose down       # Stop
```

## Key Conventions

**WebSocket Message Types:**
- `create_session`, `delete_session`, `chat`, `stop` - frontend → server
- `execute_task`, `stop` - server → CLI
- `stream`, `message_complete`, `permission_request` - CLI → server → frontend
- `sessions` - broadcast to all frontends
- `cli_status` - CLI connection status

**Authentication:**
- Token-based (application layer, not nginx basic auth)
- Enable: `WEB_AUTH_ENABLED=true` + `WEB_AUTH_PASSWORD`
- Token expiry: 24 hours (web session), long-lived (CLI tokens)
- WebSocket auth: URL parameter `?token=xxx`

**Permission Modes:**
- `default`: Full permission prompts via UI
- `acceptEdits`: Auto-accept file edits
- `yolo`: Bypasses all permissions

**CLI Configuration:**
- `VIBE_SERVER`: HTTPS address (e.g., `https://192.168.0.7:8443`)
- `CLI_AUTH_TOKEN`: Auth token for CLI worker

## Coding Style

**Go:** Format with `gofmt`, lowercase package names

**Frontend:** ES modules, React function components, 2-space indent, no semicolons unless required. `PascalCase` for components, `camelCase` for variables, `snake_case` for WebSocket message types.

**Commits:** Use conventional prefixes: `feat:`, `fix:`, `docs:`, `chore:`

## Testing

No automated test suite. Validate changes with focused local runs in the affected app (`server`, `cli`, or `frontend`).

## Dependencies

- **Server:** `gorilla/websocket`, `mattn/go-sqlite3`
- **Frontend:** React 18, Vite 5
- **Runtime:** Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)