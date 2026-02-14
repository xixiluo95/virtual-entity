#!/bin/bash
#
# 即梦自拍图片生成器 - 一键安装脚本
# 支持: Linux, macOS
#
# 使用方法:
#   curl -fsSL https://example.com/install.sh | bash
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
APP_NAME="jimeng-selfie"
CONFIG_DIR="$HOME/.jimeng-selfie"
CONFIG_FILE="$CONFIG_DIR/config.env"
INSTALL_DIR="$HOME/.local/share/jimeng-selfie"
BIN_DIR="$HOME/.local/bin"

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

    # 优先检查 python3
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        error "未找到 Python，请先安装 Python 3.8 或更高版本"
    fi

    # 检查版本
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

# 创建配置目录
create_config_dir() {
    info "创建配置目录..."

    mkdir -p "$CONFIG_DIR"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"

    success "配置目录已创建"
}

# 配置 API Key
configure_api_key() {
    info "配置 API Key..."

    # 检查是否已存在配置
    if [ -f "$CONFIG_FILE" ]; then
        # 读取现有配置
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
        # 创建配置文件
        cat > "$CONFIG_FILE" << EOF
# 即梦自拍图片生成器配置文件
# 生成时间: $(date)

# 火山引擎 ARK API Key
ARK_API_KEY="${API_KEY_INPUT}"

# API 端点 (通常不需要修改)
ARK_API_URL=https://ark.cn-beijing.volces.com/api/v3/images/generations

# 模型名称
MODEL_NAME=doubao-seedream-4-0-250828

# 默认输出目录
OUTPUT_DIR=${INSTALL_DIR}/output

# 参考图目录
REFERENCE_DIR=${INSTALL_DIR}/reference_images
EOF
        chmod 600 "$CONFIG_FILE"
        success "API Key 已保存到 $CONFIG_FILE"
    else
        warn "跳过 API Key 配置"
        # 创建模板配置文件
        cat > "$CONFIG_FILE" << EOF
# 即梦自拍图片生成器配置文件
# 请将您的 API Key 填入下方

# 火山引擎 ARK API Key (必填)
ARK_API_KEY=""

# API 端点
ARK_API_URL=https://ark.cn-beijing.volces.com/api/v3/images/generations

# 模型名称
MODEL_NAME=doubao-seedream-4-0-250828
EOF
        chmod 600 "$CONFIG_FILE"
        info "配置模板已创建，请稍后编辑 $CONFIG_FILE 填入 API Key"
    fi
}

# 安装依赖
install_dependencies() {
    info "安装 Python 依赖..."

    # 获取脚本所在目录
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    APP_DIR="$SCRIPT_DIR/jimeng-selfie-app"
    REQUIREMENTS_FILE="$APP_DIR/requirements.txt"

    if [ -f "$REQUIREMENTS_FILE" ]; then
        $PIP_CMD install -r "$REQUIREMENTS_FILE" --user
    else
        # 如果没有 requirements.txt，安装核心依赖
        $PIP_CMD install requests pillow --user
    fi

    success "依赖安装完成"
}

# 创建命令行工具
create_cli_tool() {
    info "创建命令行工具..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    APP_DIR="$SCRIPT_DIR/jimeng-selfie-app"

    # 创建启动脚本
    cat > "$BIN_DIR/jimeng-selfie" << EOF
#!/bin/bash
# 即梦自拍图片生成器启动脚本

# 加载配置文件
if [ -f "$CONFIG_FILE" ]; then
    export \$(grep -v '^#' "$CONFIG_FILE" | xargs)
fi

# 设置应用路径
APP_DIR="$APP_DIR"

# 运行应用
cd "\$APP_DIR" && $PYTHON_CMD main.py "\$@"
EOF

    chmod +x "$BIN_DIR/jimeng-selfie"

    success "命令行工具已创建: $BIN_DIR/jimeng-selfie"
}

# 配置 PATH
configure_path() {
    info "配置 PATH 环境变量..."

    # 检查 PATH 是否已包含
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        # 检测 shell 配置文件
        if [ -f "$HOME/.bashrc" ]; then
            SHELL_RC="$HOME/.bashrc"
        elif [ -f "$HOME/.zshrc" ]; then
            SHELL_RC="$HOME/.zshrc"
        else
            SHELL_RC="$HOME/.profile"
        fi

        # 添加到配置文件
        echo "" >> "$SHELL_RC"
        echo "# 即梦自拍图片生成器" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$SHELL_RC"

        info "已将 $BIN_DIR 添加到 $SHELL_RC"
        warn "请运行 'source $SHELL_RC' 或重新打开终端以生效"
    fi
}

# 创建必要的目录
create_directories() {
    info "创建应用目录..."

    mkdir -p "$INSTALL_DIR/output"
    mkdir -p "$INSTALL_DIR/reference_images"
    mkdir -p "$INSTALL_DIR/logs"

    success "应用目录已创建"
}

# 显示安装完成信息
show_complete() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}  安装完成!${NC}"
    echo "=========================================="
    echo ""
    echo "使用方法:"
    echo ""
    echo "  1. 配置 API Key (如果尚未配置):"
    echo "     vi $CONFIG_FILE"
    echo ""
    echo "  2. 运行应用:"
    echo "     $BIN_DIR/jimeng-selfie"
    echo ""
    echo "  3. 或者直接使用 Python:"
    echo "     cd $APP_DIR && python main.py"
    echo ""
    echo "  4. 查看帮助:"
    echo "     jimeng-selfie --help"
    echo ""
    echo "配置文件: $CONFIG_FILE"
    echo "输出目录: $INSTALL_DIR/output"
    echo ""
    echo "提示: 如果命令未找到，请运行:"
    echo "  source ~/.bashrc  # 或 source ~/.zshrc"
    echo ""
}

# 主安装流程
main() {
    echo ""
    echo "=========================================="
    echo "  即梦自拍图片生成器 v1.0"
    echo "  一键安装脚本"
    echo "=========================================="
    echo ""

    # 检测环境
    detect_os
    check_python
    check_pip

    # 创建目录
    create_config_dir
    create_directories

    # 安装
    install_dependencies
    create_cli_tool

    # 配置
    configure_api_key
    configure_path

    # 完成
    show_complete
}

# 运行主函数
main "$@"
