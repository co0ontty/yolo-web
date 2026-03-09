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
│  │ (port 80│          │  (:3100)     │  │
│  └─────────┘          └──────────────┘  │
│         │                               │
│         ├── / → React frontend (dist/web)│
│         ├── /cli/ → CLI downloads        │
│         └── /ws → proxy to Go server     │
└───────────────────────────────────────────┘
```

**Components:**
- `server/`: Go backend - WebSocket connections, session state management, JSON file persistence
- `cli/`: Go worker that spawns Claude Code CLI to execute tasks
- `frontend/`: React + Vite frontend
- `server/internal/handler/`: WebSocket and HTTP request handlers
- `server/internal/model/`: Data models (Session, Message, ChatRequest, StreamResponse)
- `server/internal/store/`: JSON file-based session storage

## Commands

### Quick Start
```bash
./build.sh           # Build CLI (multi-platform), frontend, Docker image
docker compose up -d # Start service on port 8118
docker compose logs -f
```

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
docker compose up -d                               # Run (port 8118)
docker compose down                                # Stop
```

## Key Conventions

**Message Types (WebSocket):**
- `create_session`, `delete_session`, `chat`, `stop` - frontend → server
- `execute_task`, `stop` - server → CLI
- `stream`, `message_complete`, `permission_request` - CLI → server → frontend
- `sessions` - broadcast from server to all frontends
- `cli_status` - server → frontend (CLI connection status)

**Session Storage:**
- Persisted to `data/sessions.json` (`/app/data` in Docker)
- Tracks: session ID, directory, permission mode, Claude token, message history

**Permission Modes:**
- `default`: Full permission prompts via UI
- `acceptEdits`: Auto-accept file edits, prompt for other operations
- `yolo`: Bypasses all permissions

**CLI Configuration:**
- `YOLO_SERVER_WS`: WebSocket address (e.g., `ws://192.168.0.7:8118/ws/cli`)
- `VIBE_SERVER`: HTTP address (e.g., `http://192.168.0.7:8118`), converted to WebSocket

**Dependencies:**
- Server: `github.com/gorilla/websocket`
- CLI: Requires Claude Code CLI installed (`npm install -g @anthropic-ai/claude-code`)
