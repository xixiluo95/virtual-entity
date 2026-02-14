#!/bin/bash
#
# 虚拟实体 (Virtual Entity) - OpenClaw 集成安装脚本
# 支持: Linux, macOS
#
# 使用方法:
#   curl -fsSL https://raw.githubusercontent.com/xixiluo95/virtual-entity/main/install.sh | bash
#   或
#   ./install.sh
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
SKILL_NAME="virtual-entity"
OPENCLAW_DIR="$HOME/.openclaw"
AGENTS_SKILLS_DIR="$HOME/.agents/skills"
SKILL_DIR="$AGENTS_SKILLS_DIR/$SKILL_NAME"
CONFIG_DIR="$HOME/.$SKILL_NAME"
CONFIG_FILE="$CONFIG_DIR/config.env"

# 打印函数
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# 检测操作系统
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="linux";;
        Darwin*)    OS="macos";;
        CYGWIN*)    OS="cygwin";;
        MINGW*)     OS="mingw";;
        *)          OS="unknown";;
    esac
    echo "检测到操作系统: $OS"
}

# 检查 Python 版本
check_python() {
    info "检查 Python 版本..."

    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        error "未找到 Python，请先安装 Python 3.8 或更高版本"
    fi

    PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

    if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
        error "Python 版本过低 (当前: $PYTHON_VERSION)，需要 3.8 或更高版本"
    fi

    success "Python 版本: $PYTHON_VERSION"
}

# 检查 pip
check_pip() {
    info "检查 pip..."

    if $PYTHON_CMD -m pip --version &> /dev/null; then
        PIP_CMD="$PYTHON_CMD -m pip"
    elif command -v pip3 &> /dev/null; then
        PIP_CMD="pip3"
    elif command -v pip &> /dev/null; then
        PIP_CMD="pip"
    else
        error "未找到 pip，请先安装 pip"
    fi

    success "pip 已就绪"
}

# 检查 OpenClaw
check_openclaw() {
    info "检查 OpenClaw 环境..."

    if [ ! -d "$OPENCLAW_DIR" ]; then
        warn "未检测到 OpenClaw 目录 (~/.openclaw)"
        info "将创建必要的目录结构..."
        mkdir -p "$OPENCLAW_DIR"
    fi

    # 创建 .agents/skills 目录
    mkdir -p "$AGENTS_SKILLS_DIR"
    mkdir -p "$OPENCLAW_DIR/skills"

    success "OpenClaw 目录结构已准备"
}

# 创建配置目录
create_config_dir() {
    info "创建配置目录..."

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR/output"
    mkdir -p "$CONFIG_DIR/reference_images"

    success "配置目录已创建: $CONFIG_DIR"
}

# 安装 Skill 到 OpenClaw
install_skill() {
    info "安装 Skill 到 OpenClaw..."

    # 获取脚本所在目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # 创建 Skill 目录
    mkdir -p "$SKILL_DIR"
    mkdir -p "$SKILL_DIR/scripts"

    # 复制 SKILL.md
    if [ -f "$SCRIPT_DIR/skills/virtual-entity/SKILL.md" ]; then
        cp "$SCRIPT_DIR/skills/virtual-entity/SKILL.md" "$SKILL_DIR/"
        success "已复制 SKILL.md"
    else
        warn "未找到 SKILL.md，跳过"
    fi

    # 复制 jimeng-selfie-app 到 scripts
    if [ -d "$SCRIPT_DIR/jimeng-selfie-app" ]; then
        cp -r "$SCRIPT_DIR/jimeng-selfie-app/app" "$SKILL_DIR/scripts/"
        cp "$SCRIPT_DIR/jimeng-selfie-app/main.py" "$SKILL_DIR/scripts/generate.py" 2>/dev/null || true
        success "已复制应用脚本"
    fi

    # 复制 social-media-automation skill
    if [ -d "$SCRIPT_DIR/skills/social-media-automation" ]; then
        cp -r "$SCRIPT_DIR/skills/social-media-automation" "$SKILL_DIR/"
        success "已复制社交媒体自动化模块"
    fi

    # 创建符号链接到 OpenClaw skills 目录（不覆盖现有链接）
    if [ ! -e "$OPENCLAW_DIR/skills/$SKILL_NAME" ]; then
        ln -sf "$SKILL_DIR" "$OPENCLAW_DIR/skills/$SKILL_NAME"
        success "已创建符号链接: $OPENCLAW_DIR/skills/$SKILL_NAME"
    else
        info "符号链接已存在，跳过"
    fi

    success "Skill 安装完成: $SKILL_DIR"
}

# 安装依赖
install_dependencies() {
    info "安装 Python 依赖..."

    # 获取脚本所在目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REQUIREMENTS_FILE="$SCRIPT_DIR/jimeng-selfie-app/requirements.txt"

    if [ -f "$REQUIREMENTS_FILE" ]; then
        $PIP_CMD install -r "$REQUIREMENTS_FILE" --user --break-system-packages 2>/dev/null || \
        $PIP_CMD install -r "$REQUIREMENTS_FILE" --break-system-packages
    else
        $PIP_CMD install requests pillow --break-system-packages
    fi

    success "依赖安装完成"
}

# 配置 API Key
configure_api_key() {
    info "配置 API Key..."

    # 检查是否已存在配置
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
        if [ -n "$ARK_API_KEY" ]; then
            warn "检测到已有 API Key 配置"
            read -p "是否要更新 API Key? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                info "保留现有配置"
                return
            fi
        fi
    fi

    echo ""
    echo "=========================================="
    echo "  API Key 配置"
    echo "=========================================="
    echo ""
    echo "请输入您的火山引擎 ARK API Key"
    echo "(可从 https://console.volcengine.com/ark 获取)"
    echo ""
    echo "提示: 按 Enter 跳过，稍后手动配置"
    echo ""

    read -p "ARK API Key: " API_KEY_INPUT

    if [ -n "$API_KEY_INPUT" ]; then
        cat > "$CONFIG_FILE" << EOF
# 虚拟实体配置文件
# 生成时间: $(date)

# 火山引擎 ARK API Key（即梦 API）
ARK_API_KEY="${API_KEY_INPUT}"

# fal.ai API Key（Grok API，可选）
FAL_API_KEY=""

# API 端点
ARK_API_URL=https://ark.cn-beijing.volces.com/api/v3/images/generations

# 模型名称
MODEL_NAME=doubao-seedream-4-0-250828

# 输出目录
OUTPUT_DIR=${CONFIG_DIR}/output

# 自动发布设置
AUTO_POST_ENABLED=true
AUTO_POST_INTERVAL_HOURS=6
EOF
        chmod 600 "$CONFIG_FILE"
        success "API Key 已保存到 $CONFIG_FILE"
    else
        cat > "$CONFIG_FILE" << EOF
# 虚拟实体配置文件
# 请填入您的 API Key

# 火山引擎 ARK API Key（必填）
ARK_API_KEY=""

# fal.ai API Key（可选）
FAL_API_KEY=""

# API 端点
ARK_API_URL=https://ark.cn-beijing.volces.com/api/v3/images/generations

# 模型名称
MODEL_NAME=doubao-seedream-4-0-250828

# 自动发布设置
AUTO_POST_ENABLED=true
AUTO_POST_INTERVAL_HOURS=6
EOF
        chmod 600 "$CONFIG_FILE"
        warn "跳过 API Key 配置，请稍后编辑 $CONFIG_FILE"
    fi
}

# 注入角色设定（可选，追加而非覆盖）
inject_persona() {
    echo ""
    echo "=========================================="
    echo "  角色设定注入（可选）"
    echo "=========================================="
    echo ""
    echo "是否要将虚拟角色的自拍能力注入到现有 Agent？"
    echo ""
    echo "注意：这是【追加】操作，不会删除现有配置！"
    echo ""

    # 查找现有的 workspace
    WORKSPACES=$(find "$OPENCLAW_DIR" -maxdepth 1 -type d -name "workspace-*" 2>/dev/null | head -5)

    if [ -z "$WORKSPACES" ]; then
        info "未检测到现有的 OpenClaw workspace，跳过角色注入"
        return
    fi

    echo "检测到以下 workspace："
    echo ""
    i=1
    for ws in $WORKSPACES; do
        name=$(basename "$ws")
        echo "  $i. $name"
        ((i++))
    done
    echo ""

    read -p "是否要注入角色设定? [y/N] " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "跳过角色注入"
        return
    fi

    echo ""
    read -p "请输入要注入的 workspace 编号 (1-$((i-1))): " ws_num

    # 获取选中的 workspace
    selected_ws=$(echo "$WORKSPACES" | sed -n "${ws_num}p")
    if [ -z "$selected_ws" ]; then
        warn "无效的选择，跳过"
        return
    fi

    SOUL_FILE="$selected_ws/SOUL.md"

    if [ ! -f "$SOUL_FILE" ]; then
        warn "未找到 $SOUL_FILE，跳过"
        return
    fi

    # 检查是否已经注入过
    if grep -q "virtual-entity" "$SOUL_FILE" 2>/dev/null; then
        warn "检测到已注入过，跳过"
        return
    fi

    # 追加角色设定（不覆盖原有内容）
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

    success "已追加角色设定到: $SOUL_FILE"
    warn "请重新启动 OpenClaw 以生效"
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
    echo "  符号链接: $OPENCLAW_DIR/skills/$SKILL_NAME"
    echo "  配置文件: $CONFIG_FILE"
    echo ""
    echo -e "${YELLOW}三种图片生成方式:${NC}"
    echo ""
    echo -e "${BLUE}方式一: 即梦 API (推荐)${NC}"
    echo "  获取: https://console.volcengine.com/ark"
    echo "  配置: vi $CONFIG_FILE"
    echo ""
    echo -e "${BLUE}方式二: Grok API (Clawra 兼容)${NC}"
    echo "  获取: https://fal.ai/dashboard/keys"
    echo ""
    echo -e "${BLUE}方式三: 即梦网页版 (免费)${NC}"
    echo "  启动: google-chrome --remote-debugging-port=9222"
    echo "  登录: https://jimeng.jianying.com/"
    echo ""
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}OpenClaw 触发词:${NC}"
    echo "  \"发自拍\" - 生成自拍"
    echo "  \"想你了\" - 生成想念风格自拍"
    echo "  \"发到推特\" - 发布到 Twitter"
    echo "  \"心里空落落的\" - 自动检测情绪"
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

    # 检测环境
    detect_os
    check_python
    check_pip
    check_openclaw

    # 创建目录
    create_config_dir

    # 安装
    install_dependencies
    install_skill

    # 配置
    configure_api_key

    # 可选：注入角色设定
    inject_persona

    # 完成
    show_complete
}

# 运行主函数
main "$@"
