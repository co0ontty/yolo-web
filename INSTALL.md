# Vibe Coding 安装与配置指南

## 快速开始

### 1. 服务器端安装

```bash
# 克隆或进入项目目录
cd /path/to/vibe_coding

# 编辑配置文件
cp .env.example .env
vi .env  # 修改 WEB_AUTH_PASSWORD 等配置

# 构建并启动
./build.sh
```

### 2. 获取 CLI Token

有两种方式获取 CLI Token：

#### 方式一：通过 Web 界面（推荐）

1. 登录 Web 界面：`https://your-server:8443`
2. 点击侧边栏底部的「CLI Token 管理」按钮
3. 输入 Token 名称（例如：`Home-CLI`, `Work-CLI`）
4. 点击「创建 Token」
5. 复制安装命令（包含 SERVER 和 TOKEN 参数）

#### 方式二：使用默认 Token

首次启动服务器时，会自动生成一个默认 CLI Token，显示在服务器日志中：

```bash
docker compose logs | grep "生成默认 CLI Token"
```

### 3. 安装 CLI 工作器

#### 一键安装（推荐）

使用从 Web 界面复制的安装命令，格式如下：

```bash
SERVER=https://your-server:8443 TOKEN=cli_xxx bash -c "$(curl -fsSLk https://your-server:8443/cli/install.sh)"
```

#### 手动安装

```bash
# 1. 下载 CLI 二进制文件
curl -fsSLk https://your-server:8443/cli/vibe-cli-linux-amd64 -o /usr/local/bin/vibe-cli
chmod +x /usr/local/bin/vibe-cli

# 2. 创建配置文件
mkdir -p ~/.vibecli
cat > ~/.vibecli/config << EOF
VIBE_SERVER="https://your-server:8443"
CLI_AUTH_TOKEN="cli_xxx"
INSTALL_DIR="/usr/local/bin"
EOF

# 3. 启动 CLI
VIBE_SERVER=https://your-server:8443 CLI_AUTH_TOKEN=cli_xxx vibe-cli
```

### 4. 验证连接

CLI 启动后，会显示连接状态：

```
连接到服务器：wss://your-server:8443/ws/cli (TLS: true)
使用认证 token: cli_xxx...
已连接到服务器
```

在 Web 界面侧边栏顶部可以看到连接状态：
- 🟢 已连接 - CLI 工作器已连接
- 🟡 CLI 连接中... - 正在尝试连接
- 🔴 连接中... - WebSocket 未连接

## CLI Token 管理

### 创建新 Token

1. 登录 Web 界面
2. 点击侧边栏底部的「CLI Token 管理」
3. 输入 Token 名称
4. 点击「创建 Token」
5. 复制安装命令或 Token

### 查看 Token 状态

在「CLI Token 管理」界面可以查看：
- Token 名称
- Token 值（部分隐藏）
- 最后连接地址
- 创建时间
- 是否正在使用（🟢 绿色指示器）

### 删除 Token

1. 在「CLI Token 管理」界面找到要删除的 Token
2. 点击「删除」按钮
3. 确认删除

**注意：** 正在使用的 Token 不能删除，需要先停止对应的 CLI 工作器。

## 多 CLI 实例管理

可以为不同的服务器或环境创建多个 CLI Token：

```bash
# 家庭服务器
TOKEN=cli_home_xxx SERVER=https://home.example.com:8443 bash -c "$(curl -fsSLk ...)"

# 公司服务器
TOKEN=cli_work_xxx SERVER=https://work.example.com:8443 bash -c "$(curl -fsSLk ...)"

# 测试环境
TOKEN=cli_test_xxx SERVER=https://test.example.com:8443 bash -c "$(curl -fsSLk ...)"
```

每个 Token 都是长期有效的，可以分发给多个服务器使用。

## 故障排查

### CLI 无法连接服务器

1. 检查服务器地址是否正确
2. 检查网络连接
3. 检查防火墙设置
4. 查看 CLI 日志：`cat ~/.vibecli/vibe-cli.log`
5. 查看服务器日志：`docker compose logs`

### Token 无效

1. 确认 Token 未过期（CLI Token 长期有效）
2. 确认 Token 未被删除
3. 在「CLI Token 管理」界面重新生成 Token

### WebSocket 连接失败

1. 检查 nginx 配置
2. 检查 SSL 证书是否有效
3. 确认端口 8443 未被防火墙阻止
4. 尝试使用 `ws://` 而非 `wss://`（仅限测试环境）

## 环境变量说明

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `VIBE_SERVER` | 服务器 HTTPS 地址 | `https://192.168.0.7:8443` |
| `YOLO_SERVER_WS` | WebSocket 地址（优先级高于 VIBE_SERVER） | `wss://192.168.0.7:8443/ws/cli` |
| `CLI_AUTH_TOKEN` | CLI 认证 Token | `cli_xxx` |

## 配置文件说明

CLI 配置文件位于 `~/.vibecli/config`，格式如下：

```bash
VIBE_SERVER="https://your-server:8443"
CLI_AUTH_TOKEN="cli_xxx"
INSTALL_DIR="/usr/local/bin"
```

修改配置后，需要重启 CLI 工作器：

```bash
# 停止旧进程
pkill vibe-cli

# 启动新进程
vibe-cli
```
