"""
即梦图片生成 API 客户端
基于火山方舟 Seedream 4.0 API
"""
import requests
import os
import time
import random
from typing import Optional, List, Dict, Any

from .config import (
    ARK_API_KEY, ARK_API_URL, MODEL_NAME,
    DEFAULT_SIZE, DEFAULT_WATERMARK, DEFAULT_TIMEOUT, OUTPUT_DIR
)


class JimengAPIClient:
    """即梦图片生成 API 客户端"""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or ARK_API_KEY
        self.api_url = ARK_API_URL
        self.model = MODEL_NAME
        self.output_dir = OUTPUT_DIR

        # 确保输出目录存在
        os.makedirs(self.output_dir, exist_ok=True)

    def _build_headers(self) -> Dict[str, str]:
        """构建请求头"""
        return {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}"
        }

    def _build_payload(
        self,
        prompt: str,
        size: str = DEFAULT_SIZE,
        watermark: bool = DEFAULT_WATERMARK,
        reference_images: Optional[List[str]] = None,
        n: int = 1,
        seed: Optional[int] = None
    ) -> Dict[str, Any]:
        """构建请求体"""
        payload = {
            "model": self.model,
            "prompt": prompt.replace("\n", " ").strip(),  # 必须单行
            "response_format": "url",
            "size": size,
            "watermark": watermark,
            "n": n
        }

        # 添加参考图（图生图模式）
        if reference_images:
            payload["image"] = reference_images
            payload["sequential_image_generation"] = "disabled"

        # 添加随机种子（可复现）
        if seed is not None:
            payload["seed"] = seed
        else:
            payload["seed"] = random.randint(1, 999999)

        return payload

    def generate(
        self,
        prompt: str,
        size: str = DEFAULT_SIZE,
        watermark: bool = DEFAULT_WATERMARK,
        reference_images: Optional[List[str]] = None,
        save_to_file: bool = True,
        filename_prefix: str = "jimeng"
    ) -> Dict[str, Any]:
        """
        生成图片

        参数:
            prompt: 图片描述（必须单行）
            size: 图片尺寸，如 "2048x2048"
            watermark: 是否添加水印
            reference_images: 参考图 URL 列表（最多10张）
            save_to_file: 是否保存到文件
            filename_prefix: 文件名前缀

        返回:
            {
                "success": bool,
                "url": str,          # 图片 URL
                "local_path": str,   # 本地保存路径
                "prompt": str,       # 使用的提示词
                "seed": int,         # 随机种子
                "error": str         # 错误信息（如果有）
            }
        """
        result = {
            "success": False,
            "url": None,
            "local_path": None,
            "prompt": prompt,
            "seed": None,
            "error": None
        }

        if not self.api_key:
            result["error"] = "未配置 API Key，请设置 ARK_API_KEY 环境变量"
            return result

        try:
            # 构建请求
            payload = self._build_payload(prompt, size, watermark, reference_images)
            result["seed"] = payload.get("seed")

            # 发送请求
            response = requests.post(
                self.api_url,
                headers=self._build_headers(),
                json=payload,
                timeout=DEFAULT_TIMEOUT
            )

            # 检查响应
            if response.status_code != 200:
                error_data = response.json() if response.headers.get("content-type", "").startswith("application/json") else {}
                result["error"] = f"API 请求失败 ({response.status_code}): {error_data.get('error', {}).get('message', response.text)}"
                return result

            data = response.json()

            # 获取图片 URL
            if "data" in data and len(data["data"]) > 0:
                result["url"] = data["data"][0].get("url")
                result["success"] = True

                # 下载并保存图片
                if save_to_file and result["url"]:
                    result["local_path"] = self._download_image(
                        result["url"],
                        filename_prefix,
                        result["seed"]
                    )
            else:
                result["error"] = "API 返回数据格式异常"

        except requests.exceptions.Timeout:
            result["error"] = f"请求超时（{DEFAULT_TIMEOUT}秒）"
        except requests.exceptions.RequestException as e:
            result["error"] = f"网络请求错误: {str(e)}"
        except Exception as e:
            result["error"] = f"未知错误: {str(e)}"

        return result

    def _download_image(
        self,
        url: str,
        prefix: str = "jimeng",
        seed: Optional[int] = None
    ) -> Optional[str]:
        """下载图片到本地"""
        try:
            timestamp = int(time.time())
            seed_suffix = f"_{seed}" if seed else ""
            filename = f"{prefix}{seed_suffix}_{timestamp}.jpg"
            filepath = os.path.join(self.output_dir, filename)

            response = requests.get(url, timeout=30)
            if response.status_code == 200:
                with open(filepath, "wb") as f:
                    f.write(response.content)
                return filepath
        except Exception as e:
            print(f"下载图片失败: {e}")

        return None

    def generate_selfie(
        self,
        character_prompt: str,
        selfie_style: str = None,
        reference_images: Optional[List[str]] = None,
        platform: str = "private"
    ) -> Dict[str, Any]:
        """
        生成自拍图片

        参数:
            character_prompt: 角色描述（外貌、服装等）
            selfie_style: 自拍风格（可选，会自动选择）
            reference_images: 参考图 URL 列表
            platform: 目标平台 (x/xiaohongshu/private)

        返回:
            生成结果
        """
        from .strategy import SelfieStrategy

        # 使用策略系统选择风格
        strategy = SelfieStrategy()
        style = selfie_style or strategy.select_style(platform)

        # 构建完整提示词
        full_prompt = f"{character_prompt}，{style}，高质量照片，自然光线"

        return self.generate(
            prompt=full_prompt,
            reference_images=reference_images,
            filename_prefix=f"selfie_{style.replace(' ', '_')}"
        )


# 便捷函数
def generate_image(prompt: str, **kwargs) -> Dict[str, Any]:
    """快速生成图片的便捷函数"""
    client = JimengAPIClient()
    return client.generate(prompt, **kwargs)
