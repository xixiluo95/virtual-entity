# 自动媒体项目 (Auto Media Project)

基于 OpenClaw 和即梦 API 的自动媒体内容生成与发布系统。

## 项目概述

本项目是一个完整的自动媒体内容生成解决方案，类似 Clawra 但使用即梦（火山方舟）API。支持自拍/他拍图片生成、社交媒体自动发布等功能。

## 目录结构

```
自动媒体项目/
├── jimeng-selfie-app/          # 即梦自拍应用主程序
│   ├── app/                    # 应用核心代码
│   │   ├── jimeng_api.py       # 即梦 API 客户端
│   │   ├── strategy.py         # 自拍策略系统
│   │   ├── cli.py              # CLI 交互界面
│   │   └── config.py           # 配置文件
│   ├── output/                 # 生成的图片输出目录
│   ├── reference_images/       # 参考图存储目录
│   ├── main.py                 # 主入口
│   └── README.md               # 应用说明文档
│
├── jimeng-image-generator/     # 即梦图片生成 Skill
│   └── SKILL.md                # OpenClaw 技能定义
│
├── jimeng-selfie-planner-team/ # 即梦自拍规划团队配置
│   ├── config.json             # 团队成员配置
│   ├── inboxes/                # Agent 收件箱
│   └── tasks/                  # 任务列表
│
├── skills/                     # 相关技能
│   └── social-media-automation/# 社交媒体自动化
│
├── docs/                       # 文档
│   ├── 最终实施方案.md         # 技术架构和实施方案
│   ├── 即梦API集成方案.md      # API 集成详细说明
│   ├── 即梦测试报告.md         # 测试结果报告
│   ├── 自动化方案可行性评估报告.md
│   ├── 方案优化分析.md
│   └── AGENTS.md               # Agent 配置文档
│
├── 原文件/                     # 原始配置文件
│   ├── AGENTS.md
│   ├── IDENTITY.md
│   ├── SOUL.md
│   ├── 11/                     # 版本备份
│   └── 记忆/                   # 记忆文件
│
└── openclaw-config/            # OpenClaw 配置
    └── agents/                 # Agent 定义

```

## 核心功能

### 1. 自拍图片生成
- **20+ 自拍风格**：镜面自拍、举高自拍、侧脸自拍等
- **8 种他拍风格**：专业人像、街拍风格、自然抓拍等
- **平台策略**：
  - 私聊：100% 自拍
  - X/小红书：70% 自拍，30% 他拍

### 2. API 集成
- 火山方舟 Seedream 4.0/4.5 API
- 支持参考图上传（最多 10 张）
- 自动下载和保存图片

### 3. 社交媒体发布
- Twitter/X 自动发布
- 小红书笔记创建
- Cookie 持久化登录

## 快速开始

### 方式一：一键安装（推荐）

```bash
# 克隆项目
git clone https://github.com/your-repo/auto-media-project.git
cd auto-media-project

# 运行安装脚本
./install.sh
```

安装脚本会自动：
- ✅ 检测 Python 环境
- ✅ 安装依赖
- ✅ 引导配置 API Key
- ✅ 创建命令行工具 `jimeng-selfie`

### 方式二：pip 安装

```bash
cd jimeng-selfie-app
pip install .
jimeng-selfie --help
```

### 方式三：手动安装

```bash
# 1. 配置 API Key
export ARK_API_KEY="your-volcano-api-key"

# 2. 安装依赖
cd jimeng-selfie-app
pip install -r requirements.txt

# 3. 运行
python main.py
```

### 使用示例

```bash
# 交互式界面
jimeng-selfie

# 直接生成
jimeng-selfie --prompt "25岁女性，黑色长发" --selfie

# 查看风格列表
jimeng-selfie --list-styles

# 检查配置
jimeng-selfie --check-config
```

## 技术栈

| 组件 | 技术 |
|-----|------|
| 图片生成 | 火山方舟 Seedream API |
| 浏览器自动化 | Patchright + Camoufox |
| 反检测 | BrowserForge 指纹伪造 |
| 语言 | Python 3.11+ |
| 异步框架 | asyncio |

## 相关文档

- [最终实施方案](docs/最终实施方案.md) - 完整的技术架构设计
- [即梦API集成方案](docs/即梦API集成方案.md) - API 使用说明
- [jimeng-selfie-app README](jimeng-selfie-app/README.md) - 应用详细文档
- [相关项目调研](docs/相关项目调研.md) - OpenClaw 生态项目分析

## 相关项目

| 项目 | 描述 | 地址 |
|------|------|------|
| **Clawra** | OpenClaw 官方自拍技能（原版） | https://github.com/SumeLabs/clawra |

### 与 Clawra 原版对比

| 功能 | Clawra 原版 | 本项目 |
|------|------------|--------|
| 图像生成 API | fal.ai (xAI Grok) | 即梦 (火山方舟) ✅ |
| 自拍风格 | 2 种 | **28 种** ✅ |
| 社交媒体发布 | ❌ | **Twitter/X + 小红书** ✅ |
| 参考图支持 | 1 张固定 | **最多 10 张** ✅ |
| 平台策略 | ❌ | **智能分配** ✅ |

### 核心功能（保留！）

- **即梦 API 集成** - 火山方舟 Seedream 4.0/4.5，国内稳定
- **Twitter/X 发布** - Cookie 登录自动发布
- **小红书发布** - 笔记创建功能

## 注意事项

1. **提示词必须单行**：API 不支持换行符，用逗号分隔
2. **图片 URL 有效期**：24 小时，需要及时下载
3. **参考图限制**：最多 10 张
4. **Cookie 管理**：首次使用需要手动登录

## 版本历史

- **v1.0** (2026-02-14) - 初始版本，包含完整的自拍生成功能

---

**项目来源**：OpenClaw 自动化系统
**创建日期**：2026-02-14
