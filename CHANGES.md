# Vibe Coding 优化总结

## 已完成的改进

### 1. CLI 专用持久化 Token 管理 ✅

**问题：** 之前每次登录生成的 token 是随机的且 24 小时过期，无法统一管理多个 CLI 实例。

**解决方案：**
- 添加了 CLI 专用 token 系统（`cli_tokens` 表）
- CLI token 长期有效，不会过期
- 支持创建多个 token，每个 token 有独立的名称和状态
- 可以查看每个 token 的使用状态（最后连接时间、连接地址、是否活跃）
- 支持删除不需要的 token

**新增 API：**
- `GET /api/cli-tokens` - 获取所有 CLI token 列表
- `POST /api/cli-tokens` - 创建新的 CLI token
- `DELETE /api/cli-tokens` - 删除指定的 CLI token

**代码变更：**
- `server/internal/auth/auth.go` - 添加 CLIToken 模型和相关方法
- `server/cmd/main.go` - 添加 CLI token 管理 API 端点
- `server/internal/handler/hub.go` - 更新 CLI WebSocket 认证逻辑

### 2. 一键安装命令 ✅

**问题：** 之前安装 CLI 需要交互式输入服务器地址和 token，流程复杂。

**解决方案：**
- 简化安装脚本，支持环境变量传入配置
- 一键安装命令格式：
  ```bash
  SERVER=https://server:8443 TOKEN=cli_xxx bash -c "$(curl -fsSLk https://server:8443/cli/install.sh)"
  ```
- 支持历史配置自动加载
- 支持无交互式安装

**代码变更：**
- `server/dist/cli/install.sh` - 重写安装脚本，支持环境变量

### 3. CLI Token 管理界面 ✅

**问题：** 没有可视化的 token 管理界面。

**解决方案：**
- 新增「CLI Token 管理」组件
- 支持创建、查看、删除 token
- 一键复制安装命令
- 显示 token 使用状态

**新增文件：**
- `frontend/src/components/CLITokenManager.jsx` - Token 管理组件
- `frontend/src/components/CLITokenManager.css` - 样式文件

**代码变更：**
- `frontend/src/App.jsx` - 集成 Token 管理组件
- `frontend/src/components/Sidebar.jsx` - 添加 Token 管理入口

### 4. WebSocket 连接优化 ✅

**问题：** CLI 在某些情况下无法正确连接到服务器。

**解决方案：**
- 改进服务器地址解析逻辑
- 正确处理 `https://` → `wss://` 转换
- 添加更详细的连接日志
- 支持多种配置方式（YOLO_SERVER_WS、VIBE_SERVER）

**代码变更：**
- `cli/internal/executor.go` - 改进 Start() 函数，添加详细日志

### 5. 创建会话功能检查 ✅

**检查结果：** 创建会话功能代码逻辑正确，包括：
- 前端 `NewSessionModal` 组件正确发送 `create_session` 消息
- 后端 `hub.go` 正确处理创建会话请求
- `store.go` 正确保存会话到 SQLite 数据库

如果创建会话失败，可能原因：
1. CLI 未连接（需要先安装并启动 CLI）
2. WebSocket 连接问题（检查网络和证书）
3. 数据库权限问题（检查 `data/` 目录权限）

## 文件清单

### 修改的文件
- `server/internal/auth/auth.go` - CLI token 管理
- `server/cmd/main.go` - API 端点
- `server/internal/handler/hub.go` - CLI 认证
- `cli/internal/executor.go` - 连接优化
- `frontend/src/App.jsx` - Token 管理 UI
- `frontend/src/components/Sidebar.jsx` - Token 管理入口
- `server/dist/cli/install.sh` - 安装脚本
- `.env` 和 `.env.example` - 配置说明

### 新增的文件
- `frontend/src/components/CLITokenManager.jsx` - Token 管理组件
- `frontend/src/components/CLITokenManager.css` - 组件样式
- `INSTALL.md` - 安装指南
- `CHANGES.md` - 变更总结（本文件）

## 使用说明

### 首次启动

```bash
# 1. 配置环境变量
cp .env.example .env
vi .env  # 修改 WEB_AUTH_PASSWORD

# 2. 构建并启动
./build.sh

# 3. 获取默认 CLI Token
docker compose logs | grep "生成默认 CLI Token"
```

### 创建新的 CLI Token

1. 登录 Web 界面：`https://your-server:8443`
2. 点击侧边栏底部的「CLI Token 管理」
3. 输入 Token 名称，点击「创建 Token」
4. 复制安装命令

### 安装 CLI 工作器

在目标服务器上执行：

```bash
SERVER=https://your-server:8443 TOKEN=cli_xxx bash -c "$(curl -fsSLk https://your-server:8443/cli/install.sh)"
```

### 验证连接

- Web 界面侧边栏显示 🟢 已连接
- CLI 日志显示 "已连接到服务器"

## 兼容性说明

- **向后兼容：** 现有的 CLI 安装仍然有效，无需重新安装
- **认证兼容：** 支持旧的 token 认证方式（通过 URL 参数）
- **配置兼容：** 支持 `YOLO_SERVER_WS` 和 `VIBE_SERVER` 环境变量

## 安全建议

1. **生产环境：** 使用正式 SSL 证书，不要使用自签名证书
2. **Token 管理：** 定期清理不使用的 CLI token
3. **访问控制：** 启用 Web 认证（`WEB_AUTH_ENABLED=true`）
4. **强密码：** 使用强密码保护 Web 登录

## 故障排查

### CLI 无法连接

1. 检查服务器地址是否正确
2. 检查 Token 是否有效
3. 查看 CLI 日志：`cat ~/.vibecli/vibe-cli.log`
4. 查看服务器日志：`docker compose logs`

### Token 无效

1. 确认 Token 未被删除
2. 在 Web 界面重新生成 Token
3. 检查认证是否启用

### WebSocket 连接失败

1. 检查防火墙设置（端口 8443）
2. 检查 nginx 配置
3. 检查 SSL 证书

## 后续优化建议

1. **Token 过期策略：** 可选地添加 token 过期时间
2. **Token 权限：** 为不同 token 分配不同权限
3. **使用统计：** 显示每个 token 的任务执行次数
4. **告警通知：** CLI 断开连接时发送通知
