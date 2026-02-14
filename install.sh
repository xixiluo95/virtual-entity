#!/bin/bash
#
# 虚拟实体 (Virtual Entity) - OpenClaw 集成安装脚本
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
    else
        error "未找到 pip"
    fi
    success "pip 已就绪"
}

# 检查 OpenClaw
check_openclaw() {
    info "检查 OpenClaw 环境..."
    mkdir -p "$OPENCLAW_DIR"
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

    success "Skill 安装完成"
}

# 安装依赖（包括 playwright）
install_dependencies() {
    info "安装 Python 依赖..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REQUIREMENTS_FILE="$SCRIPT_DIR/jimeng-selfie-app/requirements.txt"

    # 安装基础依赖
    $PIP_CMD install requests pillow playwright --break-system-packages

    # 安装 playwright 浏览器（用于自动保存 Cookie）
    python3 -m playwright install chromium 2>/dev/null || true

    success "依赖安装完成"
}

# API 配置
configure_api() {
    echo ""
    echo "=========================================="
    echo "  API 配置"
    echo "=========================================="
    echo ""

    # 即梦 API
    echo -e "${BLUE}[1/2] 即梦 API (火山方舟)${NC}"
    echo "    获取: https://console.volcengine.com/ark"
    echo "    价格: ¥0.25-0.32/张"
    read -p "    是否使用即梦 API? [y/N] " -n 1 -r
    echo
    USE_JIMENG_API=false
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        USE_JIMENG_API=true
        read -p "    请输入即梦 API Key: " JIMENG_KEY
    fi

    # Grok API
    echo ""
    echo -e "${BLUE}[2/2] Grok API (fal.ai)${NC}"
    echo "    获取: https://fal.ai/dashboard/keys"
    echo "    价格: \$0.035/张"
    read -p "    是否使用 Grok API? [y/N] " -n 1 -r
    echo
    USE_GROK_API=false
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        USE_GROK_API=true
        read -p "    请输入 Grok API Key: " GROK_KEY
    fi

    # 保存配置
    cat > "$CONFIG_FILE" << EOF
# 虚拟实体配置文件
# 生成时间: $(date)

# 即梦 API
ARK_API_KEY="${JIMENG_KEY:-}"

# Grok API
FAL_API_KEY="${GROK_KEY:-}"

# API 端点
ARK_API_URL=https://ark.cn-beijing.volces.com/api/v3/images/generations
MODEL_NAME=doubao-seedream-4-0-250828

# 输出目录
OUTPUT_DIR=${CONFIG_DIR}/output

# 社交媒体
JIMENG_WEB_ENABLED=false
TWITTER_ENABLED=false
XIAOHONGSHU_ENABLED=false

# 自动发布
AUTO_POST_ENABLED=true
AUTO_POST_INTERVAL_HOURS=6
EOF
    chmod 600 "$CONFIG_FILE"

    echo ""
    success "API 配置完成"
}

# 统一 CDP 登录配置
setup_cdp_logins() {
    echo ""
    echo "=========================================="
    echo "  网页登录配置"
    echo "=========================================="
    echo ""

    # 判断是否需要使用网页版
    NEED_WEB_LOGIN=false
    if [ "$USE_JIMENG_API" = false ] && [ "$USE_GROK_API" = false ]; then
        echo -e "${YELLOW}你未配置任何 API，需要使用即梦网页版生成图片${NC}"
        NEED_WEB_LOGIN=true
    fi

    echo "是否需要记录以下网站的登录状态？"
    echo ""

    # 即梦网页版
    USE_JIMENG_WEB=false
    if [ "$USE_JIMENG_API" = false ]; then
        read -p "  记录即梦网页版登录? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            USE_JIMENG_WEB=true
            NEED_WEB_LOGIN=true
        fi
    fi

    # Twitter
    read -p "  记录 Twitter/X 登录? [y/N] " -n 1 -r
    echo
    USE_TWITTER=false
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        USE_TWITTER=true
        NEED_WEB_LOGIN=true
    fi

    # 小红书
    read -p "  记录小红书登录? [y/N] " -n 1 -r
    echo
    USE_XIAOHONGSHU=false
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        USE_XIAOHONGSHU=true
        NEED_WEB_LOGIN=true
    fi

    # 如果需要登录，执行统一登录流程
    if [ "$NEED_WEB_LOGIN" = true ]; then
        do_cdp_login
    else
        info "跳过网页登录配置"
    fi

    # 更新配置文件
    sed -i "s/JIMENG_WEB_ENABLED=false/JIMENG_WEB_ENABLED=$USE_JIMENG_WEB/" "$CONFIG_FILE" 2>/dev/null || true
    sed -i "s/TWITTER_ENABLED=false/TWITTER_ENABLED=$USE_TWITTER/" "$CONFIG_FILE" 2>/dev/null || true
    sed -i "s/XIAOHONGSHU_ENABLED=false/XIAOHONGSHU_ENABLED=$USE_XIAOHONGSHU/" "$CONFIG_FILE" 2>/dev/null || true
}

# 创建自动保存 Cookie 的脚本
create_cookie_saver() {
    cat > /tmp/virtual_entity_save_cookies.py << 'COOKIE_SAVER_EOF'
#!/usr/bin/env python3
"""通过 Playwright 保存 Cookie（不关闭浏览器）"""
import json
import sys
import os

def save_cookies_playwright(cdp_port, output_dir):
    """连接到已打开的 Chrome 并保存所有 Cookie"""
    try:
        from playwright.sync_api import sync_playwright

        with sync_playwright() as p:
            # 连接到已有的浏览器
            browser = p.chromium.connect_over_cdp(f"http://localhost:{cdp_port}")

            # 获取所有上下文的 Cookie
            all_cookies = []
            for context in browser.contexts:
                cookies = context.cookies()
                all_cookies.extend(cookies)

            # 按 domain 分组保存
            domains = {}
            for cookie in all_cookies:
                domain = cookie.get('domain', 'unknown')
                if domain not in domains:
                    domains[domain] = []
                domains[domain].append(cookie)

            # 保存到对应文件
            saved_count = 0
            for domain, cookies in domains.items():
                # 清理 domain 名称
                clean_domain = domain.replace('.', '_').replace(':', '_')
                cookie_file = os.path.join(output_dir, f"{clean_domain}_cookies.json")

                with open(cookie_file, 'w') as f:
                    json.dump(cookies, f, indent=2)
                print(f"✅ {domain}: {len(cookies)} 个 Cookie")
                saved_count += 1

            # 不关闭浏览器！只是断开连接
            # browser.close()  # 注释掉，不关闭

            print(f"\n✅ 共保存 {saved_count} 个域名的 Cookie 到 {output_dir}")
            return True

    except Exception as e:
        print(f"❌ 保存失败: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: save_cookies.py <cdp_port> [output_dir]")
        sys.exit(1)

    cdp_port = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.expanduser("~/.openclaw/credentials")

    os.makedirs(output_dir, exist_ok=True)
    save_cookies_playwright(cdp_port, output_dir)
COOKIE_SAVER_EOF
    chmod +x /tmp/virtual_entity_save_cookies.py
}

# 找到可用端口
find_available_port() {
    for port in 9222 9223 9224 9225 9226; do
        if ! netstat -tlnp 2>/dev/null | grep -q ":$port " && ! ss -tlnp 2>/dev/null | grep -q ":$port "; then
            echo $port
            return
        fi
    done
    echo 9229
}

# 执行 CDP 登录
do_cdp_login() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  开始网页登录流程${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # 创建 Cookie 保存脚本
    create_cookie_saver

    # 找到可用端口
    CDP_PORT=$(find_available_port)
    info "使用端口: $CDP_PORT"

    CHROME_DATA_DIR="/tmp/chrome-virtual-entity-$CDP_PORT"

    # 构建要打开的 URL
    URLS=""
    SITES=""

    if [ "$USE_JIMENG_WEB" = true ]; then
        URLS="$URLS https://jimeng.jianying.com"
        SITES="$SITES jimeng"
    fi
    if [ "$USE_TWITTER" = true ]; then
        URLS="$URLS https://twitter.com"
        SITES="$SITES twitter"
    fi
    if [ "$USE_XIAOHONGSHU" = true ]; then
        URLS="$URLS https://www.xiaohongshu.com"
        SITES="$SITES xiaohongshu"
    fi

    echo "将启动 Chrome 浏览器，请在浏览器中完成以下登录："
    echo ""
    if [ "$USE_JIMENG_WEB" = true ]; then
        echo "  - 即梦网页版: https://jimeng.jianying.com"
    fi
    if [ "$USE_TWITTER" = true ]; then
        echo "  - Twitter/X: https://twitter.com"
    fi
    if [ "$USE_XIAOHONGSHU" = true ]; then
        echo "  - 小红书: https://www.xiaohongshu.com"
    fi
    echo ""
    echo -e "${YELLOW}登录完成后，Cookie 会自动保存${NC}"
    echo ""
    read -p "按 Enter 启动浏览器..."

    # 启动 Chrome
    info "启动 Chrome 浏览器..."
    rm -rf "$CHROME_DATA_DIR"
    google-chrome --remote-debugging-port=$CDP_PORT --user-data-dir="$CHROME_DATA_DIR" $URLS &
    CHROME_PID=$!

    echo ""
    echo "浏览器已启动 (PID: $CHROME_PID)"
    echo ""
    echo "请在浏览器中完成所有网站的登录"
    echo ""
    read -p "全部登录完成后按 Enter 自动保存 Cookie..."

    # 自动保存 Cookie
    echo ""
    info "正在保存 Cookie..."

    python3 /tmp/virtual_entity_save_cookies.py "$CDP_PORT" "$CREDENTIALS_DIR"

    # 询问是否关闭浏览器
    echo ""
    read -p "是否关闭浏览器? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kill $CHROME_PID 2>/dev/null || true
        info "浏览器已关闭"
    else
        info "浏览器保持运行，可继续使用"
    fi

    success "网页登录配置完成"
}

# 自动重启 OpenClaw
restart_openclaw() {
    echo ""
    echo "=========================================="
    echo "  重启 OpenClaw"
    echo "=========================================="
    echo ""

    read -p "是否立即重启 OpenClaw? [Y/n] " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        info "正在重启 OpenClaw..."

        # 查找并停止现有的 OpenClaw 进程
        pkill -f "openclaw" 2>/dev/null || true
        pkill -f "claude.*openclaw" 2>/dev/null || true
        sleep 2

        # 重新启动（假设有启动脚本）
        if [ -f "$OPENCLAW_DIR/start.sh" ]; then
            cd "$OPENCLAW_DIR" && bash start.sh &
        elif [ -f "$HOME/.openclaw/scripts/start.sh" ]; then
            bash "$HOME/.openclaw/scripts/start.sh" &
        else
            warn "未找到 OpenClaw 启动脚本，请手动重启"
        fi

        success "OpenClaw 重启完成"
    else
        warn "请手动重启 OpenClaw 以生效"
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
    echo "  Skill: $SKILL_DIR"
    echo "  配置: $CONFIG_FILE"
    echo "  Cookie: $CREDENTIALS_DIR"
    echo ""

    if [ "$USE_JIMENG_API" = true ] || [ "$USE_GROK_API" = true ]; then
        echo -e "${YELLOW}API 模式已启用${NC}"
    else
        echo -e "${YELLOW}网页版模式已启用${NC}"
    fi

    if [ "$USE_TWITTER" = true ] || [ "$USE_XIAOHONGSHU" = true ]; then
        echo -e "${YELLOW}社交媒体已配置${NC}"
    fi
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
    configure_api
    setup_cdp_logins
    restart_openclaw
    show_complete
}

main "$@"
