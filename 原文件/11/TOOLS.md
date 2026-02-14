# TOOLS.md - 本地环境配置

## 系统信息

- **操作系统**：Linux (Ubuntu/Debian)
- **Shell**：bash
- **OpenClaw 配置文件**：`~/.openclaw/openclaw.json`
- **Gateway 端口**：18789
- **工作区**：`~/.openclaw/workspace`

## 重要路径

| 路径 | 用途 |
|------|------|
| `~/.openclaw/openclaw.json` | OpenClaw 主配置文件 |
| `~/.openclaw/workspace/` | 主 agent 工作区 |
| `~/.openclaw/workspace-*` | 子 agent 工作区 |
| `/home/xixil/项目文件/` | 项目文件目录 |
| `/home/xixil/openclaw专用文件夹/` | Docker 沙箱共享目录 |

## 通道配置

### Telegram
- **Bot Token**：`YOUR_TELEGRAM_BOT_TOKEN` （请替换为实际Token）
- **策略**：开放所有用户 (`allowFrom: ["*"]`)
- **群组**：开放
- **流式**：禁用 (`blockStreaming: true`)

### 飞书 (Feishu)
- **App ID**：`YOUR_FEISHU_APP_ID` （请替换为实际App ID）
- **App Secret**：`YOUR_FEISHU_APP_SECRET` （请替换为实际App Secret）
- **域名**：`feishu`
- **模式**：配对模式 (`dmPolicy: "pairing"`)

## API 密钥

| 服务 | 密钥 | 用途 |
|------|------|------|
| 网络搜索 | `YOUR_BRAVE_API_KEY` | Brave Search / 其他搜索 API |
| 记忆搜索 | `YOUR_MEMORY_API_KEY` | 远程记忆搜索 |
| Gateway 认证 | `YOUR_GATEWAY_PASSWORD` | WebUI 访问密码 |

## Agent 配置

### 主 Agent (main)
- **工作区**：`~/.openclaw/workspace`
- **心跳**：每 30 分钟
- **沙箱**：关闭
- **权限**：最高（所有工具）

### 子 Agent
| Agent | 工作区 | 专长 |
|-------|--------|------|
| database-reviewer | workspace-database-reviewer | 数据库 |
| knowledge-manager | workspace-knowledge-manager | 知识管理 |
| project-manager | workspace-project-manager | 项目管理 |

## Docker 沙箱

- **镜像**：`openclaw-sandbox:chrome-enabled`
- **网络**：`openclaw-network`
- **内存限制**：16GB
- **DNS**：8.8.8.8, 8.8.4.4
- **共享目录**：`/home/xixil/openclaw专用文件夹:/openclaw-shared:rw`

## 浏览器自动化

- **浏览器**：Chromium
- **路径**：`/usr/bin/chromium`
- **显示**：`:1`
- **GPU 支持**：NVIDIA (CUDA)

## 日志

- **位置**：`/tmp/openclaw/`
- **格式**：`openclaw-YYYY-MM-DD.log`
- **级别**：info

## 服务管理

```bash
# 启动服务
systemctl --user start openclaw-gateway.service

# 停止服务
systemctl --user stop openclaw-gateway.service

# 重启服务
systemctl --user restart openclaw-gateway.service

# 查看状态
systemctl --user status openclaw-gateway.service

# 查看日志
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
```

---

_此文件记录本地环境的所有配置和凭证，定期更新_
