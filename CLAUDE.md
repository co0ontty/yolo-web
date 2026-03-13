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
- `server/`: Go backend - WebSocket connections, session state management, JSON file persistence
- `cli/`: Go worker that spawns Claude Code CLI to execute tasks
- `frontend/`: React + Vite frontend
- `server/internal/handler/`: WebSocket and HTTP request handlers
- `server/internal/model/`: Data models (Session, Message, ChatRequest, StreamResponse)
- `server/internal/store/`: JSON file-based session storage

## Commands

### Quick Start

**首次启动（生成自签名证书）:**
```bash
./server/gen-cert.sh   # 生成自签名证书（仅首次）
./build.sh             # Build CLI (multi-platform), frontend, Docker image
docker compose up -d   # Start service on port 8118 (HTTP) / 8443 (HTTPS)
docker compose logs -f
```

**访问地址:**
- HTTPS: `https://localhost:8443` 或 `https://你的IP:8443`
- HTTP: `http://localhost:8118` (自动重定向到 HTTPS)

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

**Authentication (前后端认证):**
- 认证方式：基于 Session 的 Token 认证（不再使用 nginx 基本认证）
- 登录 API: `POST /api/login` (body: `{ username, password }`)
- 登出 API: `POST /api/logout`
- 检查会话：`GET /api/check-session`
- Token 存储：localStorage
- WebSocket 认证：通过 URL 参数 `?token=xxx` 传递
- Token 有效期：24 小时
- 启用认证：设置 `WEB_AUTH_ENABLED=true` 和 `WEB_AUTH_PASSWORD`

**Session Storage:**
- Persisted to `data/sessions.json` (`/app/data` in Docker)
- Tracks: session ID, directory, permission mode, Claude token, message history

**Permission Modes:**
- `default`: Full permission prompts via UI
- `acceptEdits`: Auto-accept file edits, prompt for other operations
- `yolo`: Bypasses all permissions

**CLI Configuration:**
- `YOLO_SERVER_WS`: WebSocket address (e.g., `wss://192.168.0.7:8443/ws/cli`)
- `VIBE_SERVER`: HTTPS address (e.g., `https://192.168.0.7:8443`), automatically converted to WSS

**自签名证书支持:**
- CLI 已配置 `InsecureSkipVerify: true`，支持自签名证书
- 开发环境可正常使用，生产环境建议替换为正式证书

**Dependencies:**
- Server: `github.com/gorilla/websocket`
- CLI: Requires Claude Code CLI installed (`npm install -g @anthropic-ai/claude-code`)
