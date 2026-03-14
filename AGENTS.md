# Repository Guidelines

## Project Structure & Module Organization

- `server/` contains the Go backend. Use `cmd/` for the entrypoint and `internal/{auth,handler,model,store}` for application logic.
- `cli/` contains the Go worker that connects to the server WebSocket; keep executable startup in `cmd/` and reusable logic in `internal/`.
- `frontend/` is the React + Vite app. Put UI code in `frontend/src/`; treat `frontend/dist/` as generated output.
- `server/dist/`, `server/data/`, `certs/`, and `frontend/node_modules/` are build/runtime artifacts. Do not hand-edit generated files unless the task specifically requires it.

## Build, Test, and Development Commands

- `./build.sh` builds the CLI binaries, frontend bundle, Docker image, and then starts `docker compose`.
- `cd server && go run cmd/main.go` runs the backend locally on port `3100`.
- `cd server && go build -o vibe-server ./cmd` builds the server binary.
- `cd cli && go build -o vibe-cli ./cmd && ./vibe-cli -server ws://localhost:3100/ws/cli` builds and runs the worker.
- `cd frontend && npm run dev` starts the Vite dev server; `npm run build` creates the production bundle.

## Coding Style & Naming Conventions

- Format Go code with `gofmt`; keep package names lowercase and single-word where practical.
- Follow the existing frontend style: ES modules, React function components, 2-space indentation, and no semicolons unless required.
- Use `PascalCase` for React components, `camelCase` for variables/functions, `snake_case` for WebSocket message types such as `create_session`.
- Keep environment variables in `UPPER_SNAKE_CASE`, for example `WEB_AUTH_ENABLED` and `WEB_AUTH_PASSWORD`.

## Testing Guidelines

- No automated test suite is currently maintained. Validate changes with focused local runs in the affected app (`server`, `cli`, or `frontend`).
- When adding tests, place Go tests beside the source as `*_test.go` and frontend tests as `*.test.js` or `*.spec.js` using Vitest-compatible patterns.

## Commit & Pull Request Guidelines

- Follow conventional prefixes used in history: `feat:`, `fix:`, `docs:`, `chore:`.
- Keep commits small and descriptive, for example `fix: handle websocket reconnect on auth expiry`.
- PRs should summarize the user-facing change, list local verification steps, and link related issues when available. Include screenshots for frontend changes.

## Security & Configuration Tips

- Authentication is token-based; review `WEB_AUTH_ENABLED` and `WEB_AUTH_PASSWORD` before deploying.
- CLI tokens are managed via `/api/cli-tokens` endpoints; use the Web UI "CLI Token Management" to create and revoke tokens.
- Session data is stored in `server/data/`; avoid committing secrets, tokens, or generated certificates.
- One-line CLI installation: `SERVER=https://server:8443 TOKEN=cli_xxx bash -c "$(curl -fsSLk https://server:8443/cli/install.sh)"`
