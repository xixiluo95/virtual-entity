"""
即梦自拍应用
"""
from .jimeng_api import JimengAPIClient, generate_image
from .strategy import SelfieStrategy, ReferenceImageManager
from .config import (
    SELFIE_STYLES,
    OTHER_STYLES,
    PLATFORM_STRATEGY,
    OUTPUT_DIR,
    REFERENCE_DIR
)

__version__ = "1.0.0"
__all__ = [
    "JimengAPIClient",
    "generate_image",
    "SelfieStrategy",
    "ReferenceImageManager",
    "SELFIE_STYLES",
    "OTHER_STYLES",
    "PLATFORM_STRATEGY",
    "OUTPUT_DIR",
    "REFERENCE_DIR",
]
