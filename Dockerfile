# 阶段 1: 构建 Go server（需要 Go 1.22+）
FROM golang:1.22-alpine AS builder

WORKDIR /build

COPY server/go.mod server/go.sum ./
RUN go mod download

COPY server/ .
RUN CGO_ENABLED=0 GOOS=linux go build -o vibe-server ./cmd

# 阶段 2: 最终镜像
FROM alpine:latest

WORKDIR /app

RUN apk --no-cache add ca-certificates nginx nodejs npm

# 创建目录结构
RUN mkdir -p /app/data /app/internal /app/dist/web /app/dist/cli

# 从 builder 复制 Go server
COPY --from=builder /build/vibe-server .

# 从 server 目录复制其他已构建文件
COPY server/dist ./dist
COPY server/internal ./internal
COPY server/node_modules ./node_modules
COPY server/package.json ./
COPY server/nginx.conf.docker /etc/nginx/nginx.conf
COPY server/start.sh /app/start.sh

# 修复文件权限
RUN chmod -R 755 /app/dist
RUN chmod +x /app/vibe-server
RUN chmod +x /app/start.sh

EXPOSE 80

CMD ["/app/start.sh"]
