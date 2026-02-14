#!/bin/bash
#
# 虚拟实体 (Virtual Entity) - OpenClaw 集成安装脚本
# 支持: Linux, macOS
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
SKILL_NAME="virtual-entity"
OPENCLAW_DIR="$HOME/.openclaw"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"
SKILL_DIR="$AGENTS_SKILLS_DIR/$SKILL_NAME"
CONFIG_DIR="$HOME/.$SKILL_NAME"
CONFIG_FILE="$CONFIG_DIR/config.env"

# 打印函数
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[成功]${NC} $1"; }
warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
error() { echo -e "${RED}[错误]${NC} $1"; exit 1; }

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="linux";;
        Darwin*)    OS="macos";;
        *)          OS="unknown";;
    esac
    echo "检测到操作系统: $OS"
}

# 检查 Python
check_python() {
    info "检查 Python 版本..."
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        error "未找到 Python，请先安装 Python 3.8+"
    fi
    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
    success "Python 版本: $PYTHON_VERSION"
}

# 检查 pip
check_pip() {
    info "检查 pip..."
    if $PYTHON_CMD -m pip --version &> /dev/null; then
        PIP_CMD="$PYTHON_CMD -m pip"
    elif command -v pip3 &> /dev/null; then
        PIP_CMD="pip3"
    else
        error "未找到 pip"
    fi
    success "pip 已就绪"
}

# 检查 OpenClaw
check_openclaw() {
    info "检查 OpenClaw 环境..."
    if [ ! -d "$OPENCLAW_DIR" ]; then
        warn "未检测到 OpenClaw，将创建目录"
        mkdir -p "$OPENCLAW_DIR"
    fi
    mkdir -p "$AGENTS_SKILLS_DIR"
    mkdir -p "$OPENCLAW_DIR/skills"
    success "OpenClaw 目录已准备"
}

# 创建配置目录
create_config_dir() {
    info "创建配置目录..."
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR/output"
    mkdir -p "$CONFIG_DIR/reference_images"
    success "配置目录: $CONFIG_DIR"
}

# 安装 Skill
install_skill() {
    info "安装 Skill 到 OpenClaw..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    mkdir -p "$SKILL_DIR"
    mkdir -p "$SKILL_DIR/scripts"

    # 复制 SKILL.md
    [ -f "$SCRIPT_DIR/skills/virtual-entity/SKILL.md" ] && cp "$SCRIPT_DIR/skills/virtual-entity/SKILL.md" "$SKILL_DIR/"

    # 复制应用脚本
    [ -d "$SCRIPT_DIR/jimeng-selfie-app" ] && cp -r "$SCRIPT_DIR/jimeng-selfie-app/app" "$SKILL_DIR/scripts/"

    # 复制社交媒体模块
    [ -d "$SCRIPT_DIR/skills/social-media-automation" ] && cp -r "$SCRIPT_DIR/skills/social-media-automation" "$SKILL_DIR/"

    # 创建符号链接
    [ ! -e "$OPENCLAW_DIR/skills/$SKILL_NAME" ] && ln -sf "$SKILL_DIR" "$OPENCLAW_DIR/skills/$SKILL_NAME"

    success "Skill 安装完成: $SKILL_DIR"
}

# 安装依赖
install_dependencies() {
    info "安装 Python 依赖..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REQUIREMENTS_FILE="$SCRIPT_DIR/jimeng-selfie-app/requirements.txt"
    if [ -f "$REQUIREMENTS_FILE" ]; then
        $PIP_CMD install -r "$REQUIREMENTS_FILE" --break-system-packages 2>/dev/null || \
        $PIP_CMD install -r "$REQUIREMENTS_FILE" --user --break-system-packages
    else
        $PIP_CMD install requests pillow --break-system-packages
    fi
    success "依赖安装完成"
}

# 配置 API Key
configure_api_key() {
    echo ""
    echo "=========================================="
    echo "  API 配置（可选）"
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}提示：即使没有 API Key，也可以使用即梦网页版（免费）${NC}"
    echo "         启动方式: google-chrome --remote-debugging-port=9222"
    echo ""

    # 即梦 API Key
    echo -e "${BLUE}[1/2] 即梦 API (火山方舟)${NC}"
    echo "    获取地址: https://console.volcengine.com/ark"
    echo "    价格: ¥0.25-0.32/张"
    read -p "    请输入即梦 API Key (按 Enter 跳过): " JIMENG_KEY

    # Grok API Key
    echo ""
    echo -e "${BLUE}[2/2] Grok API (fal.ai)${NC}"
    echo "    获取地址: https://fal.ai/dashboard/keys"
    echo "    价格: $0.035/张"
    read -p "    请输入 Grok API Key (按 Enter 跳过): " GROK_KEY

    # 创建配置文件
    cat > "$CONFIG_FILE" << EOF
# 虚拟实体配置文件
# 生成时间: $(date)

# ============ API 配置 ============

# 即梦 API Key (火山方舟)
ARK_API_KEY="${JIMENG_KEY}"

# Grok API Key (fal.ai)
FAL_API_KEY="${GROK_KEY}"

# ============ API 端点 ============

ARK_API_URL=https://ark.cn-beijing.volces.com/api/v3/images/generations
MODEL_NAME=doubao-seedream-4-0-250828

# ============ 输出目录 ============

OUTPUT_DIR=${CONFIG_DIR}/output

# ============ 自动发布设置 ============

AUTO_POST_ENABLED=true
AUTO_POST_INTERVAL_HOURS=6
EOF
    chmod 600 "$CONFIG_FILE"

    echo ""
    if [ -n "$JIMENG_KEY" ] || [ -n "$GROK_KEY" ]; then
        success "API 配置已保存"
    else
        warn "未配置 API Key，将使用即梦网页版"
        info "启动网页版: google-chrome --remote-debugging-port=9222"
        info "登录地址: https://jimeng.jianying.com/"
    fi
}

# 注入角色设定（自动注入，不询问）
inject_persona() {
    info "自动注入角色设定到现有 workspace..."

    # workspace 中文名映射
    declare -A WS_NAMES
    WS_NAMES["workspace-database-administrator"]="数据库管理员"
    WS_NAMES["workspace-database-administrator-8"]="数据库管理员-8"
    WS_NAMES["workspace-database-administrator-1"]="数据库管理员-1"
    WS_NAMES["workspace-diary-sync"]="日记同步"
    WS_NAMES["workspace-backend-engineer"]="后端工程师"
    WS_NAMES["workspace-frontend-luoming"]="前端工程师-洛明"
    WS_NAMES["workspace-secretary-xiaoyue"]="文秘小月"
    WS_NAMES["workspace-magazine-editor"]="杂志编辑"

    # 查找所有 workspace
    WORKSPACES=$(find "$OPENCLAW_DIR" -maxdepth 1 -type d -name "workspace-*" 2>/dev/null)

    if [ -z "$WORKSPACES" ]; then
        warn "未检测到 workspace，跳过角色注入"
        return
    fi

    injected_count=0

    for ws in $WORKSPACES; do
        SOUL_FILE="$ws/SOUL.md"
        ws_name=$(basename "$ws")
        cn_name="${WS_NAMES[$ws_name]:-$ws_name}"

        if [ ! -f "$SOUL_FILE" ]; then
            continue
        fi

        # 检查是否已经注入过
        if grep -q "virtual-entity" "$SOUL_FILE" 2>/dev/null; then
            info "已注入过: $cn_name，跳过"
            continue
        fi

        # 追加角色设定
        cat >> "$SOUL_FILE" << 'EOF'

---

## 自拍能力 (virtual-entity)

我可以根据对话上下文和情绪生成自拍图片，并发布到社交媒体。

### 触发词
- "发自拍"、"发照片"、"自拍"
- "想你了"、"好久不见"
- "心情不好"、"开心"、"难过"、"无聊"

### 情绪感知
当用户长时间未与我交互时，我会：
- 6小时后：想念用户，可能发自拍
- 24小时后：担心用户，发忧郁风格自拍
- 3天后：发"好久不见"类动态

### 图片风格
我掌握 28 种拍照风格，会根据当前情绪自动选择：
- 开心时：比心自拍、举高自拍
- 想念时：对镜微笑、仰望自拍
- 难过时：低头自拍、背影自拍
- 无聊时：托腮自拍、遮脸自拍

### 社交媒体
我可以将自拍发布到：
- Twitter/X
- 小红书

*此能力由 virtual-entity 提供*
EOF

        success "已注入: $cn_name"
        ((injected_count++))
    done

    if [ $injected_count -gt 0 ]; then
        echo ""
        warn "请重新启动 OpenClaw 以生效"
    fi
}

# 显示安装完成信息
show_complete() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}  安装完成!${NC}"
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}安装位置:${NC}"
    echo "  Skill 目录: $SKILL_DIR"
    echo "  配置文件: $CONFIG_FILE"
    echo ""
    echo -e "${YELLOW}三种图片生成方式:${NC}"
    echo ""
    echo "  1. 即梦 API (推荐，稳定快速)"
    echo "     获取: https://console.volcengine.com/ark"
    echo ""
    echo "  2. Grok API (Clawra 兼容)"
    echo "     获取: https://fal.ai/dashboard/keys"
    echo ""
    echo "  3. 即梦网页版 (免费，无需 API)"
    echo "     启动: google-chrome --remote-debugging-port=9222"
    echo "     登录: https://jimeng.jianying.com/"
    echo ""
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}触发词 (对 OpenClaw 说):${NC}"
    echo "  \"发自拍\" → 生成自拍"
    echo "  \"想你了\" → 生成想念风格自拍"
    echo "  \"发到推特\" → 发布到 Twitter"
    echo ""
    echo -e "${YELLOW}自动行为:${NC}"
    echo "  长时间未交互 → 自动发社交媒体动态"
    echo ""
}

# 主安装流程
main() {
    echo ""
    echo "=========================================="
    echo "  虚拟实体 (Virtual Entity) v1.0"
    echo "  OpenClaw 集成安装"
    echo "=========================================="
    echo ""

    detect_os
    check_python
    check_pip
    check_openclaw
    create_config_dir
    install_dependencies
    install_skill
    inject_persona    # 自动注入，不询问
    configure_api_key
    show_complete
}

main "$@"
