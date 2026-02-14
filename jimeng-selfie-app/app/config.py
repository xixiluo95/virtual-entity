"""
即梦自拍应用配置

支持从以下位置加载配置（优先级从高到低）:
1. 环境变量
2. ~/.jimeng-selfie/config.env 配置文件
3. 默认值
"""
import os
from pathlib import Path
from typing import Optional


def _get_config_dir() -> Path:
    """获取配置目录路径"""
    # 支持通过环境变量自定义配置目录
    config_dir = os.environ.get("JIMENG_CONFIG_DIR", "")
    if config_dir:
        return Path(config_dir)
    return Path.home() / ".jimeng-selfie"


def _load_config_file() -> dict:
    """从配置文件加载配置"""
    config = {}
    config_file = _get_config_dir() / "config.env"

    if config_file.exists():
        try:
            with open(config_file, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    # 跳过空行和注释
                    if not line or line.startswith("#"):
                        continue
                    # 解析 KEY=VALUE
                    if "=" in line:
                        key, _, value = line.partition("=")
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        config[key] = value
        except Exception as e:
            print(f"[WARN] 无法加载配置文件 {config_file}: {e}")

    return config


def _get_config(key: str, default: str = "") -> str:
    """获取配置值（优先环境变量，其次配置文件）"""
    # 1. 优先使用环境变量
    value = os.environ.get(key, "")
    if value:
        return value

    # 2. 从配置文件获取
    config = _load_config_file()
    return config.get(key, default)


# API 配置
ARK_API_KEY = _get_config("ARK_API_KEY", "")
ARK_API_URL = _get_config("ARK_API_URL", "https://ark.cn-beijing.volces.com/api/v3/images/generations")
MODEL_NAME = _get_config("MODEL_NAME", "doubao-seedream-4-0-250828")


def _get_output_dir() -> str:
    """获取输出目录路径"""
    # 优先使用配置
    config_dir = _get_config("OUTPUT_DIR", "")
    if config_dir:
        return config_dir
    # 默认使用应用目录下的 output
    return str(Path(__file__).parent.parent / "output")


def _get_reference_dir() -> str:
    """获取参考图目录路径"""
    # 优先使用配置
    config_dir = _get_config("REFERENCE_DIR", "")
    if config_dir:
        return config_dir
    # 默认使用应用目录下的 reference_images
    return str(Path(__file__).parent.parent / "reference_images")


# 输出目录
OUTPUT_DIR = _get_output_dir()
REFERENCE_DIR = _get_reference_dir()

# 默认参数
DEFAULT_SIZE = "2048x2048"
DEFAULT_WATERMARK = False
DEFAULT_TIMEOUT = 60

# 自拍风格定义
SELFIE_STYLES = [
    "镜面自拍", "举高自拍", "侧脸自拍", "遮脸自拍",
    "背影自拍", "对镜微笑", "低头自拍", "仰望自拍",
    "闭眼自拍", "撩发自拍", "托腮自拍", "比心自拍",
    "比V自拍", "捧脸自拍", "戴墨镜自拍", "戴帽子自拍",
    "户外自拍", "咖啡厅自拍", "海边自拍", "日落自拍"
]

# 他拍风格定义
OTHER_STYLES = [
    "专业人像", "街拍风格", "自然抓拍", "艺术写真",
    "旅行照", "运动风格", "休闲风格", "商务风格"
]

# 平台策略配置
PLATFORM_STRATEGY = {
    "x": {"selfie_ratio": 0.7},      # Twitter/X
    "xiaohongshu": {"selfie_ratio": 0.7},  # 小红书
    "private": {"selfie_ratio": 1.0},  # 私聊（飞书/Telegram）
}
