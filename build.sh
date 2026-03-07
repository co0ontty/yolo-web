#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 创建 server 的 dist 目录
mkdir -p server/dist/cli
mkdir -p server/dist/web

echo "=== Building CLI (multi-platform) ==="
cd "$SCRIPT_DIR/cli"
npm install

# 编译各个平台的 CLI 可执行文件
echo "Building CLI for Linux amd64..."
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o "$SCRIPT_DIR/server/dist/cli/vibe-cli-linux-amd64" ./cmd

echo "Building CLI for Darwin amd64..."
GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build -o "$SCRIPT_DIR/server/dist/cli/vibe-cli-darwin-amd64" ./cmd

echo "Building CLI for Darwin arm64..."
GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build -o "$SCRIPT_DIR/server/dist/cli/vibe-cli-darwin-arm64" ./cmd

echo "Building CLI for Windows amd64..."
GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -o "$SCRIPT_DIR/server/dist/cli/vibe-cli-windows-amd64.exe" ./cmd

echo "=== Building frontend ==="
cd "$SCRIPT_DIR/frontend"
npm install
npm run build

echo "=== Copying files to server dist ==="
cp -r dist/* "$SCRIPT_DIR/server/dist/web/"

echo "=== Copying CLI runtime files to server ==="
cp -r "$SCRIPT_DIR/cli/internal" "$SCRIPT_DIR/server/"
cp "$SCRIPT_DIR/cli/package.json" "$SCRIPT_DIR/server/"
cp -r "$SCRIPT_DIR/cli/node_modules" "$SCRIPT_DIR/server/"

echo "=== Build complete ==="
echo "Dist directory: $SCRIPT_DIR/server/dist"
echo "  - Web: $SCRIPT_DIR/server/dist/web"
echo "  - CLI downloads: $SCRIPT_DIR/server/dist/cli"
echo ""
echo "Starting service..."
cd "$SCRIPT_DIR"
docker compose up -d