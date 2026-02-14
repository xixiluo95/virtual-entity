"""
自拍/他拍策略系统
根据平台和用户偏好自动选择拍照风格
"""
import random
from typing import Optional, List, Tuple
from .config import SELFIE_STYLES, OTHER_STYLES, PLATFORM_STRATEGY


class SelfieStrategy:
    """自拍/他拍策略管理器"""

    def __init__(self):
        self.selfie_styles = SELFIE_STYLES.copy()
        self.other_styles = OTHER_STYLES.copy()
        self.platform_config = PLATFORM_STRATEGY.copy()

        # 风格使用历史（用于避免重复）
        self._style_history: List[str] = []
        self._history_max_size = 10

    def select_style(
        self,
        platform: str = "private",
        prefer_selfie: Optional[bool] = None,
        exclude_recent: bool = True
    ) -> str:
        """
        选择拍照风格

        参数:
            platform: 目标平台 (x/xiaohongshu/private)
            prefer_selfie: 是否强制自拍（None 表示根据平台策略）
            exclude_recent: 是否排除最近使用的风格

        返回:
            风格名称字符串
        """
        # 确定是否使用自拍
        use_selfie = prefer_selfie
        if use_selfie is None:
            config = self.platform_config.get(platform, self.platform_config["private"])
            selfie_ratio = config.get("selfie_ratio", 1.0)
            use_selfie = random.random() < selfie_ratio

        # 选择风格池
        style_pool = self.selfie_styles if use_selfie else self.other_styles

        # 排除最近使用的风格
        if exclude_recent and self._style_history:
            available_styles = [s for s in style_pool if s not in self._style_history]
            if not available_styles:
                available_styles = style_pool  # 如果全部用过了就重置
        else:
            available_styles = style_pool

        # 随机选择
        selected = random.choice(available_styles)

        # 记录历史
        self._style_history.append(selected)
        if len(self._style_history) > self._history_max_size:
            self._style_history.pop(0)

        return selected

    def get_selfie_prompt_enhancement(self, style: str) -> str:
        """
        根据自拍风格返回提示词增强

        参数:
            style: 自拍风格名称

        返回:
            用于增强提示词的描述
        """
        enhancements = {
            "镜面自拍": "对着浴室镜子自拍，镜面反射效果",
            "举高自拍": "手机举高向下俯拍角度，显瘦效果",
            "侧脸自拍": "45度侧脸角度，展现脸部轮廓",
            "遮脸自拍": "用手或物品部分遮挡脸部，神秘感",
            "背影自拍": "背对镜头回眸，优雅的背影",
            "对镜微笑": "对着镜子自然微笑，眼神明亮",
            "低头自拍": "微微低头，温柔的眼神",
            "仰望自拍": "抬头仰望，展现颈部线条",
            "闭眼自拍": "闭眼微笑，享受当下的感觉",
            "撩发自拍": "单手撩动头发，自然动作",
            "托腮自拍": "手托下巴，可爱的姿势",
            "比心自拍": "双手比心，青春活力",
            "比V自拍": "剪刀手比V，经典姿势",
            "捧脸自拍": "双手捧脸，可爱表情",
            "戴墨镜自拍": "戴着时尚墨镜，酷飒风格",
            "戴帽子自拍": "戴着帽子，修饰脸型",
            "户外自拍": "户外自然光线下，背景虚化",
            "咖啡厅自拍": "咖啡厅内，温馨氛围",
            "海边自拍": "海边背景，海风吹拂头发",
            "日落自拍": "日落逆光，温暖色调",
        }
        return enhancements.get(style, style)

    def get_other_prompt_enhancement(self, style: str) -> str:
        """
        根据他拍风格返回提示词增强
        """
        enhancements = {
            "专业人像": "专业影棚拍摄，柔和的打光，清晰的面部细节",
            "街拍风格": "街头自然抓拍，动态姿势，城市背景",
            "自然抓拍": "不经意的自然瞬间，真实表情",
            "艺术写真": "艺术感的构图，独特的光影效果",
            "旅行照": "旅行场景中的自然照片，地标背景",
            "运动风格": "运动场景中，活力四射",
            "休闲风格": "休闲日常场景，轻松自在",
            "商务风格": "正式商务场景，专业形象",
        }
        return enhancements.get(style, style)

    def build_full_prompt(
        self,
        character_description: str,
        style: str,
        additional_context: str = "",
        is_selfie: bool = True
    ) -> str:
        """
        构建完整的图片生成提示词

        参数:
            character_description: 角色描述（外貌、服装等）
            style: 拍照风格
            additional_context: 额外场景描述
            is_selfie: 是否为自拍

        返回:
            完整的提示词字符串（单行）
        """
        # 获取风格增强
        if is_selfie:
            style_enhancement = self.get_selfie_prompt_enhancement(style)
        else:
            style_enhancement = self.get_other_prompt_enhancement(style)

        # 组合提示词
        parts = [
            character_description,
            style_enhancement,
            additional_context,
            "高质量照片",
            "自然光线",
            "细节丰富"
        ]

        # 过滤空值并拼接
        prompt = "，".join(p for p in parts if p)

        # 确保单行（API 要求）
        prompt = prompt.replace("\n", " ").strip()

        return prompt


class ReferenceImageManager:
    """参考图管理器"""

    def __init__(self, reference_dir: str):
        self.reference_dir = reference_dir
        self.supported_formats = [".jpg", ".jpeg", ".png", ".webp"]

    def list_references(self) -> List[str]:
        """列出所有参考图"""
        import os
        references = []
        if os.path.exists(self.reference_dir):
            for f in os.listdir(self.reference_dir):
                if any(f.lower().endswith(ext) for ext in self.supported_formats):
                    references.append(os.path.join(self.reference_dir, f))
        return references

    def add_reference(self, source_path: str, name: Optional[str] = None) -> str:
        """添加参考图"""
        import os
        import shutil

        if not os.path.exists(source_path):
            raise FileNotFoundError(f"源文件不存在: {source_path}")

        # 确保目录存在
        os.makedirs(self.reference_dir, exist_ok=True)

        # 生成目标文件名
        ext = os.path.splitext(source_path)[1]
        target_name = name or os.path.basename(source_path)
        if not target_name.endswith(ext):
            target_name += ext

        target_path = os.path.join(self.reference_dir, target_name)
        shutil.copy(source_path, target_path)

        return target_path
