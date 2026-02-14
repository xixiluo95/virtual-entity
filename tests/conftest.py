"""
pytest 配置文件
共享fixtures和配置
"""
import os
import sys
import tempfile
import shutil
import pytest
from pathlib import Path

# 添加项目路径
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "jimeng-selfie-app"))


@pytest.fixture
def temp_dir():
    """临时目录fixture"""
    test_dir = tempfile.mkdtemp()
    yield test_dir
    shutil.rmtree(test_dir, ignore_errors=True)


@pytest.fixture
def mock_api_key():
    """模拟API Key"""
    original_key = os.environ.get("ARK_API_KEY")
    os.environ["ARK_API_KEY"] = "test-mock-api-key-12345"
    yield "test-mock-api-key-12345"
    if original_key:
        os.environ["ARK_API_KEY"] = original_key
    elif "ARK_API_KEY" in os.environ:
        del os.environ["ARK_API_KEY"]


@pytest.fixture
def no_api_key():
    """清除API Key环境"""
    original_key = os.environ.get("ARK_API_KEY")
    if "ARK_API_KEY" in os.environ:
        del os.environ["ARK_API_KEY"]
    yield
    if original_key:
        os.environ["ARK_API_KEY"] = original_key


@pytest.fixture
def sample_config():
    """示例配置"""
    return {
        "ARK_API_KEY": "test-key",
        "ARK_API_URL": "https://ark.cn-beijing.volces.com/api/v3/images/generations",
        "MODEL_NAME": "doubao-seedream-4-0-250828",
        "DEFAULT_SIZE": "2048x2048",
        "DEFAULT_WATERMARK": False,
        "DEFAULT_TIMEOUT": 60
    }


@pytest.fixture
def sample_character_prompt():
    """示例角色提示词"""
    return "25岁女性，黑色长发，白色连衣裙，温柔的表情"


@pytest.fixture
def sample_selfie_styles():
    """示例自拍风格列表"""
    return [
        "镜面自拍", "举高自拍", "侧脸自拍", "遮脸自拍",
        "背影自拍", "对镜微笑", "低头自拍", "仰望自拍"
    ]


@pytest.fixture
def sample_other_styles():
    """示例他拍风格列表"""
    return [
        "专业人像", "街拍风格", "自然抓拍", "艺术写真",
        "旅行照", "运动风格", "休闲风格", "商务风格"
    ]


# pytest 配置选项
def pytest_configure(config):
    """pytest配置"""
    config.addinivalue_line(
        "markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')"
    )
    config.addinivalue_line(
        "markers", "integration: marks tests as integration tests"
    )
    config.addinivalue_line(
        "markers", "network: marks tests that require network access"
    )
