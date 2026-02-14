#!/bin/bash
#
# 虚拟实体 (Virtual Entity) - OpenClaw 集成安装脚本
# 支持: Linux, macOS
#

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
CREDENTIALS_DIR="$OPENCLAW_DIR/credentials"

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
    mkdir -p "$CREDENTIALS_DIR"
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

    [ -f "$SCRIPT_DIR/skills/virtual-entity/SKILL.md" ] && cp "$SCRIPT_DIR/skills/virtual-entity/SKILL.md" "$SKILL_DIR/"
    [ -d "$SCRIPT_DIR/jimeng-selfie-app" ] && cp -r "$SCRIPT_DIR/jimeng-selfie-app/app" "$SKILL_DIR/scripts/"
    [ -d "$SCRIPT_DIR/skills/social-media-automation" ] && cp -r "$SCRIPT_DIR/skills/social-media-automation" "$SKILL_DIR/"
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

    echo -e "${BLUE}[1/2] 即梦 API (火山方舟)${NC}"
    echo "    获取地址: https://console.volcengine.com/ark"
    echo "    价格: ¥0.25-0.32/张"
    read -p "    请输入即梦 API Key (按 Enter 跳过): " JIMENG_KEY

    echo ""
    echo -e "${BLUE}[2/2] Grok API (fal.ai)${NC}"
    echo "    获取地址: https://fal.ai/dashboard/keys"
    echo "    价格: \$0.035/张"
    read -p "    请输入 Grok API Key (按 Enter 跳过): " GROK_KEY

    JIMENG_KEY="${JIMENG_KEY:-}"
    GROK_KEY="${GROK_KEY:-}"

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

# ============ 社交媒体配置 ============

TWITTER_ENABLED=false
XIAOHONGSHU_ENABLED=false

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
    fi
}

# 注入角色设定
inject_persona() {
    info "自动注入角色设定到现有 workspace..."

    declare -A WS_NAMES
    WS_NAMES["workspace-database-administrator"]="数据库管理员"
    WS_NAMES["workspace-database-administrator-8"]="数据库管理员-8"
    WS_NAMES["workspace-database-administrator-1"]="数据库管理员-1"
    WS_NAMES["workspace-diary-sync"]="日记同步"
    WS_NAMES["workspace-backend-engineer"]="后端工程师"
    WS_NAMES["workspace-frontend-luoming"]="前端工程师-洛明"
    WS_NAMES["workspace-secretary-xiaoyue"]="文秘小月"
    WS_NAMES["workspace-magazine-editor"]="杂志编辑"

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

        if grep -q "virtual-entity" "$SOUL_FILE" 2>/dev/null; then
            info "已注入过: $cn_name，跳过"
            continue
        fi

        cat >> "$SOUL_FILE" << 'PERSONA_EOF'

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
PERSONA_EOF

        success "已注入: $cn_name"
        injected_count=$((injected_count + 1))
    done

    if [ $injected_count -gt 0 ]; then
        echo ""
        warn "请重新启动 OpenClaw 以生效"
    fi
}

# 保存 Cookie 的 Python 脚本
save_cookies_script() {
    cat << 'SAVE_COOKIE_EOF'
import json
import sys

def save_cookies(cookies, filepath):
    with open(filepath, 'w') as f:
        json.dump(cookies, f, indent=2)
    print(f"Cookie 已保存到: {filepath}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("用法: save_cookies.py <cookie_json> <filepath>")
        sys.exit(1)
    cookies = json.loads(sys.argv[1])
    save_cookies(cookies, sys.argv[2])
SAVE_COOKIE_EOF
}

# 引导注册 Twitter
setup_twitter() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Twitter/X 账号登录引导${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "将启动 Chrome 浏览器，请登录你的 Twitter/X 账号"
    echo "登录成功后，Cookie 将自动保存"
    echo ""
    read -p "按 Enter 启动浏览器..."

    # 启动 Chrome
    info "启动 Chrome 浏览器..."
    google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-virtual-entity-twitter https://twitter.com/login &
    CHROME_PID=$!

    echo ""
    echo "浏览器已启动，请在浏览器中完成登录"
    echo ""
    read -p "登录完成后按 Enter 继续..."

    # 保存 Cookie 的提示
    echo ""
    success "Twitter 登录完成"
    echo ""
    echo "请手动导出 Cookie 并保存到:"
    echo "  $CREDENTIALS_DIR/twitter_cookies.json"
    echo ""
    echo "方法："
    echo "  1. 在 Chrome 中按 F12 打开开发者工具"
    echo "  2. 切换到 Application 标签"
    echo "  3. 左侧选择 Cookies > https://twitter.com"
    echo "  4. 复制所有 Cookie 到 JSON 文件"
    echo ""

    # 创建 Cookie 目录
    mkdir -p "$CREDENTIALS_DIR"

    # 更新配置
    sed -i "s/TWITTER_ENABLED=false/TWITTER_ENABLED=true/" "$CONFIG_FILE" 2>/dev/null || true
    success "Twitter 配置已启用"
}

# 引导注册小红书
setup_xiaohongshu() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  小红书账号登录引导${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "将启动 Chrome 浏览器，请扫码登录你的小红书账号"
    echo "登录成功后，Cookie 将自动保存"
    echo ""
    read -p "按 Enter 启动浏览器..."

    # 启动 Chrome
    info "启动 Chrome 浏览器..."
    google-chrome --remote-debugging-port=9223 --user-data-dir=/tmp/chrome-virtual-entity-xiaohongshu https://www.xiaohongshu.com &
    CHROME_PID=$!

    echo ""
    echo "浏览器已启动，请在浏览器中完成扫码登录"
    echo ""
    read -p "登录完成后按 Enter 继续..."

    # 保存 Cookie 的提示
    echo ""
    success "小红书登录完成"
    echo ""
    echo "请手动导出 Cookie 并保存到:"
    echo "  $CREDENTIALS_DIR/xiaohongshu_cookies.json"
    echo ""
    echo "方法："
    echo "  1. 在 Chrome 中按 F12 打开开发者工具"
    echo "  2. 切换到 Application 标签"
    echo "  3. 左侧选择 Cookies > https://www.xiaohongshu.com"
    echo "  4. 复制所有 Cookie 到 JSON 文件"
    echo ""

    # 创建 Cookie 目录
    mkdir -p "$CREDENTIALS_DIR"

    # 更新配置
    sed -i "s/XIAOHONGSHU_ENABLED=false/XIAOHONGSHU_ENABLED=true/" "$CONFIG_FILE" 2>/dev/null || true
    success "小红书配置已启用"
}

# 引导注册社交媒体
setup_social_media() {
    echo ""
    echo "=========================================="
    echo "  社交媒体账号配置（可选）"
    echo "=========================================="
    echo ""
    echo "是否需要配置角色社交媒体账号登录？"
    echo ""

    SETUP_TWITTER=false
    SETUP_XIAOHONGSHU=false

    # Twitter 配置
    read -p "是否需要配置角色推特 (Twitter/X) 登录? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SETUP_TWITTER=true
    fi

    # 小红书配置
    read -p "是否需要配置角色小红书登录? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SETUP_XIAOHONGSHU=true
    fi

    # 执行配置
    if [ "$SETUP_TWITTER" = true ]; then
        setup_twitter
    fi

    if [ "$SETUP_XIAOHONGSHU" = true ]; then
        setup_xiaohongshu
    fi

    # 如果都不需要
    if [ "$SETUP_TWITTER" = false ] && [ "$SETUP_XIAOHONGSHU" = false ]; then
        info "跳过社交媒体配置，稍后可手动配置"
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
    echo "  Cookie 目录: $CREDENTIALS_DIR"
    echo ""
    echo -e "${YELLOW}三种图片生成方式:${NC}"
    echo ""
    echo "  1. 即梦 API (推荐)"
    echo "     获取: https://console.volcengine.com/ark"
    echo ""
    echo "  2. Grok API (Clawra 兼容)"
    echo "     获取: https://fal.ai/dashboard/keys"
    echo ""
    echo "  3. 即梦网页版 (免费)"
    echo "     启动: google-chrome --remote-debugging-port=9222"
    echo "     登录: https://jimeng.jianying.com/"
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
    inject_persona
    configure_api_key
    setup_social_media
    show_complete
}

main "$@"
