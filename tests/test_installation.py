"""
一键安装方案测试用例
测试覆盖：环境检测、安装流程、API Key配置、功能验证
"""
import os
import sys
import json
import tempfile
import shutil
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock, mock_open
import platform

# 添加项目路径
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "jimeng-selfie-app"))


# =============================================================================
# 第一部分：环境检测测试
# =============================================================================

class TestEnvironmentDetection(unittest.TestCase):
    """环境检测测试"""

    def test_python_version_detection(self):
        """测试Python版本检测（需要3.8+）"""
        current_version = sys.version_info
        self.assertGreaterEqual(
            current_version,
            (3, 8),
            f"Python版本需要3.8+，当前版本: {current_version.major}.{current_version.minor}"
        )

    def test_pip_availability(self):
        """测试pip可用性"""
        try:
            result = subprocess.run(
                [sys.executable, "-m", "pip", "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            self.assertEqual(result.returncode, 0, f"pip不可用: {result.stderr}")
        except subprocess.TimeoutExpired:
            self.fail("pip命令超时")
        except FileNotFoundError:
            self.fail("pip未安装")

    def test_network_connection(self):
        """测试网络连接"""
        import socket

        # 测试DNS解析
        try:
            socket.create_connection(("8.8.8.8", 53), timeout=5)
            network_ok = True
        except (socket.timeout, OSError):
            network_ok = False

        self.assertTrue(
            network_ok,
            "网络连接失败，请检查网络设置"
        )

    def test_required_modules_import(self):
        """测试必需模块导入"""
        required_modules = ["requests"]

        for module in required_modules:
            with self.subTest(module=module):
                try:
                    __import__(module)
                except ImportError:
                    self.fail(f"必需模块 {module} 未安装")

    def test_virtual_environment_detection(self):
        """测试虚拟环境检测"""
        in_venv = (
            hasattr(sys, 'real_prefix') or
            (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix)
        )
        # 这是一个信息性测试，不强制要求虚拟环境
        print(f"当前{'在' if in_venv else '不在'}虚拟环境中")


class TestSystemRequirements(unittest.TestCase):
    """系统要求测试"""

    def test_os_compatibility(self):
        """测试操作系统兼容性"""
        current_os = platform.system()
        supported_os = ["Linux", "Darwin", "Windows"]
        self.assertIn(current_os, supported_os, f"不支持的操作系统: {current_os}")

    def test_memory_requirement(self):
        """测试内存要求（最低2GB）"""
        try:
            import psutil
            memory = psutil.virtual_memory()
            min_memory_gb = 2
            self.assertGreaterEqual(
                memory.total / (1024 ** 3),
                min_memory_gb,
                f"内存不足，需要至少{min_memory_gb}GB"
            )
        except ImportError:
            self.skipTest("psutil未安装，跳过内存检测")

    def test_disk_space_requirement(self):
        """测试磁盘空间要求（最低500MB）"""
        total, used, free = shutil.disk_usage("/")
        min_space_mb = 500
        free_mb = free / (1024 ** 2)
        self.assertGreaterEqual(
            free_mb,
            min_space_mb,
            f"磁盘空间不足，需要至少{min_space_mb}MB，当前{free_mb:.0f}MB"
        )


# =============================================================================
# 第二部分：安装流程测试
# =============================================================================

class TestInstallationProcess(unittest.TestCase):
    """安装流程测试"""

    @classmethod
    def setUpClass(cls):
        """设置测试环境"""
        cls.test_dir = tempfile.mkdtemp()
        cls.original_cwd = os.getcwd()

    @classmethod
    def tearDownClass(cls):
        """清理测试环境"""
        os.chdir(cls.original_cwd)
        shutil.rmtree(cls.test_dir, ignore_errors=True)

    def test_fresh_installation_simulated(self):
        """模拟全新安装测试"""
        # 模拟创建安装目录
        install_dir = Path(self.test_dir) / "fresh_install"
        install_dir.mkdir(parents=True, exist_ok=True)

        # 创建模拟的配置文件
        config_file = install_dir / "config.json"
        test_config = {
            "api_key": "",
            "output_dir": str(install_dir / "output"),
            "first_run": True
        }

        with open(config_file, "w", encoding="utf-8") as f:
            json.dump(test_config, f)

        # 验证配置文件创建成功
        self.assertTrue(config_file.exists())

        with open(config_file, encoding="utf-8") as f:
            loaded_config = json.load(f)

        self.assertTrue(loaded_config["first_run"])
        self.assertEqual(loaded_config["api_key"], "")

    def test_upgrade_installation_simulated(self):
        """模拟升级安装测试"""
        install_dir = Path(self.test_dir) / "upgrade_install"
        install_dir.mkdir(parents=True, exist_ok=True)

        # 模拟旧版本配置
        old_config_file = install_dir / "config.json"
        old_config = {
            "api_key": "test-old-key",
            "output_dir": str(install_dir / "output"),
            "version": "1.0.0"
        }

        with open(old_config_file, "w", encoding="utf-8") as f:
            json.dump(old_config, f)

        # 模拟升级：保留用户配置，更新版本
        new_config = old_config.copy()
        new_config["version"] = "1.1.0"

        with open(old_config_file, "w", encoding="utf-8") as f:
            json.dump(new_config, f)

        # 验证配置保留
        with open(old_config_file, encoding="utf-8") as f:
            loaded_config = json.load(f)

        self.assertEqual(loaded_config["api_key"], "test-old-key")
        self.assertEqual(loaded_config["version"], "1.1.0")

    def test_uninstall_and_reinstall_simulated(self):
        """模拟卸载重装测试"""
        install_dir = Path(self.test_dir) / "reinstall"
        install_dir.mkdir(parents=True, exist_ok=True)

        # 创建初始文件
        config_file = install_dir / "config.json"
        data_file = install_dir / "data" / "user_data.json"
        data_file.parent.mkdir(parents=True, exist_ok=True)

        with open(config_file, "w", encoding="utf-8") as f:
            json.dump({"installed": True}, f)

        with open(data_file, "w", encoding="utf-8") as f:
            json.dump({"user": "test"}, f)

        # 模拟卸载（保留用户数据）
        config_file.unlink()
        # data_file 保留

        # 模拟重装
        with open(config_file, "w", encoding="utf-8") as f:
            json.dump({"installed": True, "reinstalled": True}, f)

        # 验证用户数据保留
        self.assertTrue(data_file.exists())
        with open(data_file, encoding="utf-8") as f:
            user_data = json.load(f)

        self.assertEqual(user_data["user"], "test")


class TestDependencyInstallation(unittest.TestCase):
    """依赖安装测试"""

    def test_requests_package_installed(self):
        """测试requests包安装"""
        try:
            import requests
            self.assertIsNotNone(requests.__version__)
        except ImportError:
            self.fail("requests包未安装")

    def test_package_version_compatibility(self):
        """测试包版本兼容性"""
        try:
            import requests
            version_parts = requests.__version__.split(".")
            major = int(version_parts[0])
            # requests 2.x 应该都兼容
            self.assertGreaterEqual(major, 2)
        except (ImportError, ValueError, IndexError):
            self.skipTest("无法验证requests版本")


# =============================================================================
# 第三部分：API Key 配置测试
# =============================================================================

class TestAPIKeyConfiguration(unittest.TestCase):
    """API Key 配置测试"""

    @classmethod
    def setUpClass(cls):
        """设置测试环境"""
        cls.test_dir = tempfile.mkdtemp()
        cls.original_env = os.environ.copy()

    @classmethod
    def tearDownClass(cls):
        """清理测试环境"""
        os.environ.clear()
        os.environ.update(cls.original_env)
        shutil.rmtree(cls.test_dir, ignore_errors=True)

    def setUp(self):
        """每个测试前清理环境变量"""
        if "ARK_API_KEY" in os.environ:
            del os.environ["ARK_API_KEY"]

    def test_environment_variable_configuration(self):
        """测试环境变量配置API Key"""
        test_key = "test-api-key-from-env"

        # 设置环境变量
        os.environ["ARK_API_KEY"] = test_key

        # 导入配置模块
        from app import config

        # 重新加载配置
        import importlib
        importlib.reload(config)

        self.assertEqual(config.ARK_API_KEY, test_key)

    def test_config_file_loading(self):
        """测试配置文件加载"""
        config_file = Path(self.test_dir) / "config.json"
        test_key = "test-api-key-from-file"

        config_data = {
            "ARK_API_KEY": test_key,
            "ARK_API_URL": "https://test.api.url"
        }

        with open(config_file, "w", encoding="utf-8") as f:
            json.dump(config_data, f)

        # 验证配置文件可以正确读取
        with open(config_file, encoding="utf-8") as f:
            loaded_config = json.load(f)

        self.assertEqual(loaded_config["ARK_API_KEY"], test_key)

    def test_interactive_configuration_simulated(self):
        """模拟交互式配置"""
        # 模拟用户输入API Key
        user_input_key = "user-input-api-key-12345"

        # 验证输入格式
        self.assertIsInstance(user_input_key, str)
        self.assertGreater(len(user_input_key), 0)

        # 验证API Key格式（假设格式要求）
        self.assertNotIn(" ", user_input_key, "API Key不应包含空格")

    def test_api_key_validation(self):
        """测试API Key验证"""
        # 有效Key格式
        valid_keys = [
            "abc123def456",
            "sk-test-key-12345",
            "ARK-API-KEY-EXAMPLE"
        ]

        # 无效Key格式
        invalid_keys = [
            "",
            "   ",
            "key with spaces",
            None
        ]

        for key in valid_keys:
            with self.subTest(key=key):
                self.assertTrue(
                    isinstance(key, str) and len(key.strip()) > 0 and " " not in key,
                    f"有效Key验证失败: {key}"
                )

        for key in invalid_keys:
            with self.subTest(key=key):
                is_invalid = (
                    key is None or
                    not isinstance(key, str) or
                    len(key.strip()) == 0 or
                    " " in key
                )
                self.assertTrue(is_invalid, f"无效Key验证失败: {key}")

    def test_api_key_security(self):
        """测试API Key安全性"""
        # API Key不应硬编码在代码中
        source_files = list(PROJECT_ROOT.rglob("*.py"))

        for source_file in source_files:
            if "test_" in str(source_file):
                continue  # 跳过测试文件

            with open(source_file, encoding="utf-8") as f:
                content = f.read()

            # 检查是否有硬编码的API Key（简单检查）
            self.assertNotIn("ARK_API_KEY = \"sk-", content)
            self.assertNotIn("ARK_API_KEY = 'sk-", content)


# =============================================================================
# 第四部分：功能验证测试
# =============================================================================

class TestCommandLineTool(unittest.TestCase):
    """命令行工具测试"""

    @classmethod
    def setUpClass(cls):
        """设置测试环境"""
        cls.cli_path = PROJECT_ROOT / "jimeng-selfie-app" / "main.py"

    def test_cli_help_command(self):
        """测试CLI帮助命令"""
        if not self.cli_path.exists():
            self.skipTest(f"CLI文件不存在: {self.cli_path}")

        try:
            result = subprocess.run(
                [sys.executable, str(self.cli_path), "--help"],
                capture_output=True,
                text=True,
                timeout=10,
                cwd=str(self.cli_path.parent)
            )
            self.assertEqual(result.returncode, 0, f"帮助命令失败: {result.stderr}")
            self.assertIn("usage", result.stdout.lower())
        except subprocess.TimeoutExpired:
            self.fail("CLI帮助命令超时")

    def test_cli_list_styles_command(self):
        """测试CLI风格列表命令"""
        if not self.cli_path.exists():
            self.skipTest(f"CLI文件不存在: {self.cli_path}")

        try:
            result = subprocess.run(
                [sys.executable, str(self.cli_path), "--list-styles"],
                capture_output=True,
                text=True,
                timeout=10,
                cwd=str(self.cli_path.parent)
            )
            self.assertEqual(result.returncode, 0, f"风格列表命令失败: {result.stderr}")
            # 验证输出包含风格名称
            self.assertIn("自拍风格", result.stdout)
            self.assertIn("他拍风格", result.stdout)
        except subprocess.TimeoutExpired:
            self.fail("CLI风格列表命令超时")

    def test_cli_availability(self):
        """测试CLI可用性"""
        self.assertTrue(
            self.cli_path.exists(),
            f"CLI文件不存在: {self.cli_path}"
        )


class TestAPIClient(unittest.TestCase):
    """API客户端测试"""

    def setUp(self):
        """每个测试前的设置"""
        # 保存原始环境变量
        self.original_api_key = os.environ.get("ARK_API_KEY")

    def tearDown(self):
        """每个测试后的清理"""
        # 恢复原始环境变量
        if self.original_api_key:
            os.environ["ARK_API_KEY"] = self.original_api_key
        elif "ARK_API_KEY" in os.environ:
            del os.environ["ARK_API_KEY"]

    def test_api_client_initialization_with_key(self):
        """测试带API Key的客户端初始化"""
        from app.jimeng_api import JimengAPIClient

        test_key = "test-api-key"
        client = JimengAPIClient(api_key=test_key)

        self.assertEqual(client.api_key, test_key)
        self.assertIsNotNone(client.output_dir)

    def test_api_client_initialization_without_key(self):
        """测试不带API Key的客户端初始化"""
        from app.jimeng_api import JimengAPIClient

        # 清除环境变量
        if "ARK_API_KEY" in os.environ:
            del os.environ["ARK_API_KEY"]

        # 使用patch模拟config模块中的ARK_API_KEY为空
        with patch("app.jimeng_api.ARK_API_KEY", ""):
            client = JimengAPIClient()
            self.assertEqual(client.api_key, "")

    def test_api_headers_building(self):
        """测试API请求头构建"""
        from app.jimeng_api import JimengAPIClient

        test_key = "test-key-123"
        client = JimengAPIClient(api_key=test_key)

        headers = client._build_headers()

        self.assertEqual(headers["Content-Type"], "application/json")
        self.assertEqual(headers["Authorization"], f"Bearer {test_key}")

    def test_api_payload_building(self):
        """测试API请求体构建"""
        from app.jimeng_api import JimengAPIClient

        client = JimengAPIClient(api_key="test")
        payload = client._build_payload(
            prompt="test prompt",
            size="1024x1024",
            watermark=False
        )

        self.assertEqual(payload["prompt"], "test prompt")
        self.assertEqual(payload["size"], "1024x1024")
        self.assertEqual(payload["watermark"], False)
        self.assertIn("seed", payload)

    def test_api_generate_without_key(self):
        """测试没有API Key时的生成请求"""
        from app.jimeng_api import JimengAPIClient

        # 清除环境变量
        if "ARK_API_KEY" in os.environ:
            del os.environ["ARK_API_KEY"]

        # 使用patch模拟config模块中的ARK_API_KEY为空
        with patch("app.jimeng_api.ARK_API_KEY", ""):
            client = JimengAPIClient()
            result = client.generate("test prompt", save_to_file=False)

            self.assertFalse(result["success"])
            self.assertIn("API Key", result["error"])

    @patch("app.jimeng_api.requests.post")
    def test_api_call_success_mocked(self, mock_post):
        """测试API调用成功（模拟）"""
        from app.jimeng_api import JimengAPIClient

        # 模拟成功响应
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "data": [{"url": "https://example.com/image.jpg"}]
        }
        mock_post.return_value = mock_response

        client = JimengAPIClient(api_key="test-key")
        result = client.generate("test prompt", save_to_file=False)

        self.assertTrue(result["success"])
        self.assertEqual(result["url"], "https://example.com/image.jpg")

    @patch("app.jimeng_api.requests.post")
    def test_api_call_failure_mocked(self, mock_post):
        """测试API调用失败（模拟）"""
        from app.jimeng_api import JimengAPIClient

        # 模拟失败响应
        mock_response = MagicMock()
        mock_response.status_code = 401
        mock_response.headers = {"content-type": "application/json"}
        mock_response.json.return_value = {
            "error": {"message": "Invalid API key"}
        }
        mock_post.return_value = mock_response

        client = JimengAPIClient(api_key="invalid-key")
        result = client.generate("test prompt", save_to_file=False)

        self.assertFalse(result["success"])
        self.assertIn("401", result["error"])


class TestImageGeneration(unittest.TestCase):
    """图片生成测试"""

    @patch("app.jimeng_api.requests.post")
    @patch("app.jimeng_api.requests.get")
    def test_image_generation_success_mocked(self, mock_get, mock_post):
        """测试图片生成成功（模拟）"""
        from app.jimeng_api import JimengAPIClient

        # 模拟API响应
        mock_api_response = MagicMock()
        mock_api_response.status_code = 200
        mock_api_response.json.return_value = {
            "data": [{"url": "https://example.com/generated.jpg"}]
        }
        mock_post.return_value = mock_api_response

        # 模拟图片下载
        mock_download_response = MagicMock()
        mock_download_response.status_code = 200
        mock_download_response.content = b"fake_image_data"
        mock_get.return_value = mock_download_response

        with tempfile.TemporaryDirectory() as temp_dir:
            client = JimengAPIClient(api_key="test")
            client.output_dir = temp_dir

            result = client.generate("test prompt", save_to_file=True)

            self.assertTrue(result["success"])
            self.assertIsNotNone(result["local_path"])

    def test_selfie_generation_parameters(self):
        """测试自拍生成参数"""
        from app.jimeng_api import JimengAPIClient

        with patch.object(JimengAPIClient, 'generate') as mock_generate:
            mock_generate.return_value = {"success": True}

            client = JimengAPIClient(api_key="test")
            client.generate_selfie(
                character_prompt="25岁女性，黑色长发",
                selfie_style="镜面自拍",
                platform="private"
            )

            # 验证generate被调用
            self.assertTrue(mock_generate.called)

            # 验证传递的参数包含正确的信息
            call_args = mock_generate.call_args
            self.assertIn("镜面自拍", call_args[1]["prompt"])


class TestStrategySystem(unittest.TestCase):
    """策略系统测试"""

    def test_style_selection(self):
        """测试风格选择"""
        from app.strategy import SelfieStrategy

        strategy = SelfieStrategy()

        # 测试自拍风格选择
        selfie_style = strategy.select_style(platform="private", prefer_selfie=True)
        self.assertIn(selfie_style, strategy.selfie_styles)

        # 测试他拍风格选择
        other_style = strategy.select_style(platform="private", prefer_selfie=False)
        self.assertIn(other_style, strategy.other_styles)

    def test_platform_strategy(self):
        """测试平台策略"""
        from app.strategy import SelfieStrategy

        strategy = SelfieStrategy()

        # 测试不同平台的策略配置
        self.assertEqual(strategy.platform_config["private"]["selfie_ratio"], 1.0)
        self.assertEqual(strategy.platform_config["x"]["selfie_ratio"], 0.7)
        self.assertEqual(strategy.platform_config["xiaohongshu"]["selfie_ratio"], 0.7)

    def test_prompt_building(self):
        """测试提示词构建"""
        from app.strategy import SelfieStrategy

        strategy = SelfieStrategy()
        prompt = strategy.build_full_prompt(
            character_description="25岁女性，黑色长发",
            style="镜面自拍",
            is_selfie=True
        )

        # 验证提示词包含必要信息
        self.assertIn("25岁女性", prompt)
        self.assertIn("高质量照片", prompt)
        self.assertNotIn("\n", prompt)  # 必须单行

    def test_style_history(self):
        """测试风格历史记录"""
        from app.strategy import SelfieStrategy

        strategy = SelfieStrategy()

        # 选择多个风格
        selected_styles = []
        for _ in range(5):
            style = strategy.select_style(exclude_recent=True)
            selected_styles.append(style)

        # 验证历史记录
        self.assertEqual(len(strategy._style_history), 5)

    def test_prompt_enhancement(self):
        """测试提示词增强"""
        from app.strategy import SelfieStrategy

        strategy = SelfieStrategy()

        # 测试自拍风格增强
        selfie_enhancement = strategy.get_selfie_prompt_enhancement("镜面自拍")
        self.assertIn("镜子", selfie_enhancement)

        # 测试他拍风格增强
        other_enhancement = strategy.get_other_prompt_enhancement("专业人像")
        self.assertIn("影棚", other_enhancement)


class TestReferenceImageManager(unittest.TestCase):
    """参考图管理器测试"""

    def setUp(self):
        """每个测试前设置独立的测试环境"""
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        """每个测试后清理测试环境"""
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_list_references_empty(self):
        """测试空参考图列表"""
        from app.strategy import ReferenceImageManager

        # 使用一个全新的空目录
        empty_dir = Path(self.test_dir) / "empty_refs"
        empty_dir.mkdir(parents=True, exist_ok=True)

        manager = ReferenceImageManager(str(empty_dir))
        refs = manager.list_references()

        self.assertEqual(refs, [])

    def test_list_references_with_files(self):
        """测试有文件时的参考图列表"""
        from app.strategy import ReferenceImageManager

        # 使用一个全新的独立目录
        refs_dir = Path(self.test_dir) / "test_refs"
        refs_dir.mkdir(parents=True, exist_ok=True)

        # 创建测试图片文件
        test_image = refs_dir / "test.jpg"
        test_image.write_bytes(b"fake image data")

        manager = ReferenceImageManager(str(refs_dir))
        refs = manager.list_references()

        self.assertEqual(len(refs), 1)
        self.assertIn(str(test_image), refs)

    def test_add_reference(self):
        """测试添加参考图"""
        from app.strategy import ReferenceImageManager

        # 创建源文件（在独立的源目录）
        source_dir = Path(self.test_dir) / "source"
        source_dir.mkdir(parents=True, exist_ok=True)
        source_file = source_dir / "source.jpg"
        source_file.write_bytes(b"fake image data")

        # 创建参考图目录（独立的）
        ref_dir = Path(self.test_dir) / "references"
        manager = ReferenceImageManager(str(ref_dir))

        # 添加参考图
        result = manager.add_reference(str(source_file))

        # 验证
        self.assertTrue(Path(result).exists())
        self.assertTrue(ref_dir.exists())


# =============================================================================
# 第五部分：集成测试
# =============================================================================

class TestIntegration(unittest.TestCase):
    """集成测试"""

    def test_full_workflow_simulation(self):
        """模拟完整工作流程"""
        with tempfile.TemporaryDirectory() as temp_dir:
            # 1. 创建配置
            config = {
                "ARK_API_KEY": "test-key",
                "output_dir": temp_dir
            }

            config_file = Path(temp_dir) / "config.json"
            with open(config_file, "w", encoding="utf-8") as f:
                json.dump(config, f)

            # 2. 加载配置
            with open(config_file, encoding="utf-8") as f:
                loaded_config = json.load(f)

            # 3. 初始化组件
            from app.strategy import SelfieStrategy

            strategy = SelfieStrategy()
            style = strategy.select_style()
            prompt = strategy.build_full_prompt("测试角色", style)

            # 4. 验证
            self.assertIsNotNone(style)
            self.assertIsInstance(prompt, str)
            self.assertGreater(len(prompt), 0)


class TestErrorHandling(unittest.TestCase):
    """错误处理测试"""

    def test_missing_api_key_error(self):
        """测试缺少API Key的错误处理"""
        from app.jimeng_api import JimengAPIClient

        # 清除环境变量
        original_key = os.environ.get("ARK_API_KEY")
        if "ARK_API_KEY" in os.environ:
            del os.environ["ARK_API_KEY"]

        try:
            client = JimengAPIClient()
            result = client.generate("test", save_to_file=False)

            self.assertFalse(result["success"])
            self.assertIn("error", result)
        finally:
            if original_key:
                os.environ["ARK_API_KEY"] = original_key

    def test_invalid_style_error(self):
        """测试无效风格的错误处理"""
        from app.strategy import SelfieStrategy

        strategy = SelfieStrategy()

        # 测试不存在的风格（应该返回原始风格名）
        enhancement = strategy.get_selfie_prompt_enhancement("不存在的风格")
        self.assertEqual(enhancement, "不存在的风格")

    def test_network_timeout_handling(self):
        """测试网络超时处理"""
        from app.jimeng_api import JimengAPIClient

        with patch("app.jimeng_api.requests.post") as mock_post:
            import requests
            mock_post.side_effect = requests.exceptions.Timeout()

            client = JimengAPIClient(api_key="test")
            result = client.generate("test", save_to_file=False)

            self.assertFalse(result["success"])
            self.assertIn("超时", result["error"])


# =============================================================================
# 第六部分：性能测试
# =============================================================================

class TestPerformance(unittest.TestCase):
    """性能测试"""

    def test_style_selection_performance(self):
        """测试风格选择性能"""
        from app.strategy import SelfieStrategy
        import time

        strategy = SelfieStrategy()

        start_time = time.time()
        for _ in range(1000):
            strategy.select_style()
        end_time = time.time()

        # 1000次选择应该在1秒内完成
        self.assertLess(end_time - start_time, 1.0)

    def test_prompt_building_performance(self):
        """测试提示词构建性能"""
        from app.strategy import SelfieStrategy
        import time

        strategy = SelfieStrategy()

        start_time = time.time()
        for _ in range(1000):
            strategy.build_full_prompt("测试角色描述", "镜面自拍")
        end_time = time.time()

        # 1000次构建应该在1秒内完成
        self.assertLess(end_time - start_time, 1.0)


# =============================================================================
# 运行测试
# =============================================================================

def run_tests():
    """运行所有测试"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # 添加所有测试类
    test_classes = [
        TestEnvironmentDetection,
        TestSystemRequirements,
        TestInstallationProcess,
        TestDependencyInstallation,
        TestAPIKeyConfiguration,
        TestCommandLineTool,
        TestAPIClient,
        TestImageGeneration,
        TestStrategySystem,
        TestReferenceImageManager,
        TestIntegration,
        TestErrorHandling,
        TestPerformance,
    ]

    for test_class in test_classes:
        tests = loader.loadTestsFromTestCase(test_class)
        suite.addTests(tests)

    # 运行测试
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return result


if __name__ == "__main__":
    # 运行测试并输出结果
    result = run_tests()

    # 输出测试摘要
    print("\n" + "=" * 60)
    print("测试摘要")
    print("=" * 60)
    print(f"运行测试数: {result.testsRun}")
    print(f"成功: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"失败: {len(result.failures)}")
    print(f"错误: {len(result.errors)}")
    print(f"跳过: {len(result.skipped)}")

    # 返回退出码
    sys.exit(0 if result.wasSuccessful() else 1)
