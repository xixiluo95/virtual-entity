#!/usr/bin/env python3
"""
即梦自拍图片生成器 - 主入口
"""
import sys
import os

# 确保能找到 app 模块
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.cli import main

if __name__ == "__main__":
    main()
