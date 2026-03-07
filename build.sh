#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 创建 server 的 dist 目录
mkdir -p server/dist/cli
mkdir -p server/dist/web

echo "=== Building CLI (multi-platform) ==="
cd "$SCRIPT_DIR/cli"

# 编译各个平台的 CLI 可执行文件
echo "Building CLI for Linux amd64..."
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o "$SCRIPT_DIR/server/dist/cli/vibe-cli-linux-amd64" ./cmd

echo "Building CLI for Darwin amd64..."
GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build -o "$SCRIPT_DIR/server/dist/cli/vibe-cli-darwin-amd64" ./cmd

echo "Building CLI for Darwin arm64..."
GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build -o "$SCRIPT_DIR/server/dist/cli/vibe-cli-darwin-arm64" ./cmd

echo "Building CLI for Windows amd64..."
GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -o "$SCRIPT_DIR/server/dist/cli/vibe-cli-windows-amd64.exe" ./cmd

echo "=== Copying install script ==="
cp "$SCRIPT_DIR/cli/install.sh" "$SCRIPT_DIR/server/dist/cli/install.sh"
chmod +x "$SCRIPT_DIR/server/dist/cli/install.sh"

echo "=== Building frontend ==="
cd "$SCRIPT_DIR/frontend"
npm install
npm run build

echo "=== Copying files to server dist ==="
cp -r dist/* "$SCRIPT_DIR/server/dist/web/"

echo "=== Copying CLI source for Docker build ==="
cp "$SCRIPT_DIR/cli/go.mod" "$SCRIPT_DIR/server/cli-go.mod"
cp "$SCRIPT_DIR/cli/go.sum" "$SCRIPT_DIR/server/cli-go.sum"
cp -r "$SCRIPT_DIR/cli/cmd" "$SCRIPT_DIR/server/cli-cmd"
cp -r "$SCRIPT_DIR/cli/internal" "$SCRIPT_DIR/server/cli-internal"

echo "=== Building Docker image ==="
cd "$SCRIPT_DIR/server"
docker build -t vibe-coding:latest .

echo "=== Build complete ==="
echo "Dist directory: $SCRIPT_DIR/server/dist"
echo "  - Web: $SCRIPT_DIR/server/dist/web"
echo "  - CLI downloads: $SCRIPT_DIR/server/dist/cli"
echo ""
echo "To start the service, run: docker compose up -d"
docker compose up -d
