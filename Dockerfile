# 阶段 1: 构建 Go server（需要 Go 1.22+）
FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY server/go.mod server/go.sum ./
RUN go mod download

COPY server/ .
RUN CGO_ENABLED=0 GOOS=linux go build -o vibe-server ./cmd

# 阶段 2: 最终镜像（只复制已构建文件）
FROM alpine:latest

WORKDIR /app

RUN apk --no-cache add ca-certificates nginx nodejs npm supervisor

# 创建目录结构
RUN mkdir -p /app/data /app/internal /app/dist/web /app/dist/cli

# 从 builder 复制 Go server
COPY --from=builder /build/vibe-server .

# 从 server 目录复制其他已构建文件
COPY server/dist ./dist
COPY server/nginx.conf /etc/nginx/nginx.conf
COPY server/supervisord.conf /etc/supervisord.conf
COPY server/internal ./internal
COPY server/node_modules ./node_modules
COPY server/package.json ./

# 修复文件权限
RUN chmod -R 755 /app/dist
RUN chmod +x /app/vibe-server

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
