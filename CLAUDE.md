# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a "Vibe Coding" application - a Claude Code session manager with a web UI. It allows users to create multiple working sessions, each with a specified directory and permission mode, and interact with Claude Code through a browser-based chat interface.

## Architecture

**Current Unified Architecture (Single Docker Image):**
```
┌─────────────────────────────────────────────────────────┐
│                     Docker Container                      │
│  ┌──────────────┐      ┌──────────────┐                │
│  │   nginx      │ ───► │  Go server   │                │
│  │  (port 80)   │      │  (:3100)     │                │
│  └──────────────┘      └──────────────┘                │
│         │                                        │
│         ├── / → React frontend (dist/web)       │
│         ├── /cli/ → CLI downloads (dist/cli)    │
│         └── /api, /ws → proxy to Go server      │
└─────────────────────────────────────────────────────────┘
```

- **server**: Go backend that handles WebSocket connections, manages session state, persists data to JSON files
- **cli**: Go worker that spawns the Node.js bridge to execute Claude Code tasks (included in the image but typically run separately by users)
- **web**: React frontend with Vite, served by nginx
- **nginx**: Serves frontend, CLI downloads, and proxies API/WebSocket to Go server

**Components:**
- `Dockerfile`: Multi-stage build for the unified image
- `docker-compose.yml`: Single service deployment
- `server/nginx.conf`: nginx configuration for the unified service
- `server/supervisord.conf`: Process manager for nginx and Go server

## Commands

### Quick Start (Recommended)
```bash
# Build and start the unified service
docker compose build && docker compose up -d
```

### build.sh (Local Build)
```bash
# Build CLI (multi-platform) and web frontend into server/dist/
./build.sh
```

### Docker Compose
```bash
# Build image
docker compose build

# Start service (port 8080)
docker compose up -d

# View logs
docker compose logs -f

# Stop service
docker compose down
```

### Individual Components (Legacy/Development)

**Server:**
```bash
cd server
go run cmd/main.go                    # Run server (default port 3100)
go build -o vibe-server ./cmd         # Build binary
```

**CLI Worker:**
```bash
cd cli
go build -o vibe-cli ./cmd            # Build CLI worker
./vibe-cli                            # Run worker
```

**Web Frontend:**
```bash
cd web
npm install
npm run dev         # Start dev server
npm run build       # Production build
```

## Permission Modes

Sessions support three permission modes:
- `default`: Claude Code prompts for permission before each tool use
- `acceptEdits`: Automatically accepts file edits, prompts for other operations
- `yolo`: Bypasses all permissions (full automation)

## WebSocket Protocol

The server exposes two WebSocket endpoints:
- `/ws`: Frontend clients for UI communication
- `/ws/cli`: CLI workers for task execution

Message types flow between components. Key message types:
- `create_session`, `delete_session`, `chat`, `stop` (frontend → server)
- `execute_task`, `stop` (server → CLI)
- `stream`, `message_complete` (CLI → server → frontend)
- `sessions` (broadcast from server to all frontends)

## Data Flow

```
┌─────────┐      WebSocket       ┌─────────┐      WebSocket       ┌─────────┐
│  Web    │ ◄──────────────────► │  Go     │ ◄──────────────────► │  CLI    │
│  (React)│       /ws            │  Server │       /ws/cli        │  Worker │
└─────────┘                      └─────────┘                      └────┬────┘
                                                                     │
                                                                     │ spawn
                                                                     ▼
                                                              ┌─────────────┐
                                                              │  Node.js    │
                                                              │  bridge.mjs │
                                                              │  (claude-   │
                                                              │   code SDK) │
                                                              └─────────────┘
```

## Session Storage

Sessions are persisted to JSON files in the data directory (`./data` by default, `/app/data` in Docker). The `store` package handles:
- Session CRUD operations
- Message history
- Claude session ID tracking for resume
- Status and mode updates

## Permission System

The permission mode controls how Claude Code handles tool executions:
- **default**: Full permission prompts via UI (permission_request → permission_response flow)
- **acceptEdits**: Automatically accepts file edits, prompts for other operations
- **yolo**: Bypasses all permissions (use with caution)

The permission flow for `default` mode:
1. CLI worker sends `permission_request` to server
2. Server forwards to frontend
3. User approves/denies in UI
4. Frontend sends `permission_response`
5. Server forwards to CLI worker
6. CLI resumes execution
