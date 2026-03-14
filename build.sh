#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

cleanup_cli_sources() {
    rm -f "$SCRIPT_DIR/server/cli-go.mod" "$SCRIPT_DIR/server/cli-go.sum"
    rm -rf "$SCRIPT_DIR/server/cli-cmd" "$SCRIPT_DIR/server/cli-internal"
}

trap cleanup_cli_sources EXIT
cleanup_cli_sources

# 创建 server 的 dist 目录
mkdir -p server/dist/cli
mkdir -p server/dist/web

echo "=== Building CLI (multi-platform) ==="
cd "$SCRIPT_DIR/cli"

build_cli() {
    local goos="$1"
    local goarch="$2"
    local output="$3"
    local host_os host_arch

    host_os="$(go env GOHOSTOS)"
    host_arch="$(go env GOHOSTARCH)"

    # Try CGO-disabled build first (most compatible)
    if CGO_ENABLED=0 GOOS="$goos" GOARCH="$goarch" go build -o "$output" ./cmd; then
        return 0
    fi

    # Skip retry for cross-compilation targets
    if [[ "$goos" != "$host_os" || "$goarch" != "$host_arch" ]]; then
        echo "Error: CGO-disabled build failed for ${goos}/${goarch} (cross-compilation target, cannot retry with CGO enabled)"
        return 1
    fi

    # Retry with CGO enabled on native target only
    echo "Retrying ${goos}/${goarch} build with CGO enabled..."
    GOOS="$goos" GOARCH="$goarch" go build -o "$output" ./cmd
}

# Build CLI for each target platform
build_cli linux amd64 "$SCRIPT_DIR/server/dist/cli/vibe-cli-linux-amd64"
build_cli darwin amd64 "$SCRIPT_DIR/server/dist/cli/vibe-cli-darwin-amd64"
build_cli darwin arm64 "$SCRIPT_DIR/server/dist/cli/vibe-cli-darwin-arm64"
build_cli windows amd64 "$SCRIPT_DIR/server/dist/cli/vibe-cli-windows-amd64.exe"

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
