"""
即梦自拍应用 CLI 交互界面
"""
import os
import sys
import argparse
from typing import Optional, List

# 添加项目路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.jimeng_api import JimengAPIClient
from app.strategy import SelfieStrategy, ReferenceImageManager
from app.config import OUTPUT_DIR, REFERENCE_DIR, SELFIE_STYLES, OTHER_STYLES


class SelfieAppCLI:
    """即梦自拍应用 CLI"""

    def __init__(self):
        self.client = JimengAPIClient()
        self.strategy = SelfieStrategy()
        self.ref_manager = ReferenceImageManager(REFERENCE_DIR)

    def run_interactive(self):
        """运行交互式界面"""
        print("=" * 60)
        print("  即梦自拍图片生成器 v1.0")
        print("  基于 Seedream 4.0 API")
        print("=" * 60)
        print()

        # 检查 API Key
        if not self.client.api_key:
            print("[!] 警告: 未配置 ARK_API_KEY 环境变量")
            print("    请设置: export ARK_API_KEY='your-api-key'")
            print()
            return

        while True:
            print("\n请选择操作:")
            print("  1. 生成自拍图片")
            print("  2. 生成他拍图片")
            print("  3. 自定义生成（输入完整提示词）")
            print("  4. 查看自拍风格列表")
            print("  5. 查看他拍风格列表")
            print("  6. 管理参考图")
            print("  0. 退出")
            print()

            try:
                choice = input("请输入选项 [0-6]: ").strip()
            except (EOFError, KeyboardInterrupt):
                print("\n再见!")
                break

            if choice == "0":
                print("再见!")
                break
            elif choice == "1":
                self._generate_selfie()
            elif choice == "2":
                self._generate_other()
            elif choice == "3":
                self._generate_custom()
            elif choice == "4":
                self._list_styles(selfie=True)
            elif choice == "5":
                self._list_styles(selfie=False)
            elif choice == "6":
                self._manage_references()
            else:
                print("[!] 无效选项，请重新输入")

    def _generate_selfie(self):
        """生成交互：自拍"""
        print("\n--- 生成自拍 ---")

        # 获取角色描述
        character = input("请输入角色描述 (如: 25岁女性，黑色长发，白色连衣裙): ").strip()
        if not character:
            print("[!] 角色描述不能为空")
            return

        # 选择风格
        print("\n可选自拍风格:")
        for i, style in enumerate(SELFIE_STYLES, 1):
            print(f"  {i}. {style}")
        print("  0. 随机选择")

        try:
            style_choice = input("请选择风格 [0-{}]: ".format(len(SELFIE_STYLES))).strip()
            if style_choice == "0" or style_choice == "":
                style = None  # 自动选择
            else:
                style_idx = int(style_choice) - 1
                if 0 <= style_idx < len(SELFIE_STYLES):
                    style = SELFIE_STYLES[style_idx]
                else:
                    print("[!] 无效选择，使用随机风格")
                    style = None
        except ValueError:
            print("[!] 无效输入，使用随机风格")
            style = None

        # 选择平台
        print("\n目标平台:")
        print("  1. 私聊 (100% 自拍)")
        print("  2. X/Twitter (70% 自拍)")
        print("  3. 小红书 (70% 自拍)")
        platform_choice = input("请选择 [1-3, 默认1]: ").strip() or "1"

        platform_map = {"1": "private", "2": "x", "3": "xiaohongshu"}
        platform = platform_map.get(platform_choice, "private")

        # 执行生成
        print("\n正在生成图片...")
        result = self.client.generate_selfie(
            character_prompt=character,
            selfie_style=style,
            platform=platform
        )

        self._display_result(result)

    def _generate_other(self):
        """生成交互：他拍"""
        print("\n--- 生成他拍 ---")

        # 获取角色描述
        character = input("请输入角色描述: ").strip()
        if not character:
            print("[!] 角色描述不能为空")
            return

        # 选择风格
        print("\n可选他拍风格:")
        for i, style in enumerate(OTHER_STYLES, 1):
            print(f"  {i}. {style}")
        print("  0. 随机选择")

        try:
            style_choice = input("请选择风格 [0-{}]: ".format(len(OTHER_STYLES))).strip()
            if style_choice == "0" or style_choice == "":
                style = self.strategy.select_style(platform="private", prefer_selfie=False)
            else:
                style_idx = int(style_choice) - 1
                if 0 <= style_idx < len(OTHER_STYLES):
                    style = OTHER_STYLES[style_idx]
                else:
                    print("[!] 无效选择，使用随机风格")
                    style = self.strategy.select_style(platform="private", prefer_selfie=False)
        except ValueError:
            style = self.strategy.select_style(platform="private", prefer_selfie=False)

        # 构建提示词
        prompt = self.strategy.build_full_prompt(
            character_description=character,
            style=style,
            is_selfie=False
        )

        # 执行生成
        print(f"\n使用风格: {style}")
        print("正在生成图片...")
        result = self.client.generate(prompt, filename_prefix=f"other_{style.replace(' ', '_')}")

        self._display_result(result)

    def _generate_custom(self):
        """自定义生成"""
        print("\n--- 自定义生成 ---")

        prompt = input("请输入完整提示词: ").strip()
        if not prompt:
            print("[!] 提示词不能为空")
            return

        print("\n正在生成图片...")
        result = self.client.generate(prompt, filename_prefix="custom")

        self._display_result(result)

    def _list_styles(self, selfie: bool = True):
        """显示风格列表"""
        styles = SELFIE_STYLES if selfie else OTHER_STYLES
        title = "自拍风格" if selfie else "他拍风格"

        print(f"\n--- {title}列表 ---")
        for i, style in enumerate(styles, 1):
            enhancement = (
                self.strategy.get_selfie_prompt_enhancement(style)
                if selfie else
                self.strategy.get_other_prompt_enhancement(style)
            )
            print(f"  {i}. {style}: {enhancement}")

    def _manage_references(self):
        """管理参考图"""
        print("\n--- 参考图管理 ---")

        refs = self.ref_manager.list_references()
        if refs:
            print(f"当前参考图 ({len(refs)} 张):")
            for ref in refs:
                print(f"  - {os.path.basename(ref)}")
        else:
            print("当前没有参考图")

        print("\n操作:")
        print("  1. 添加参考图")
        print("  0. 返回")

        choice = input("请选择: ").strip()
        if choice == "1":
            source = input("请输入源图片路径: ").strip()
            if os.path.exists(source):
                try:
                    target = self.ref_manager.add_reference(source)
                    print(f"[+] 已添加: {target}")
                except Exception as e:
                    print(f"[!] 添加失败: {e}")
            else:
                print("[!] 文件不存在")

    def _display_result(self, result: dict):
        """显示生成结果"""
        print("\n" + "-" * 40)
        if result["success"]:
            print("[+] 生成成功!")
            print(f"    图片 URL: {result['url']}")
            if result.get("local_path"):
                print(f"    本地路径: {result['local_path']}")
            print(f"    随机种子: {result.get('seed')}")
        else:
            print(f"[-] 生成失败: {result.get('error', '未知错误')}")
        print("-" * 40)


def main():
    """CLI 入口"""
    parser = argparse.ArgumentParser(
        description="即梦自拍图片生成器",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                    # 交互式界面
  %(prog)s --prompt "..."     # 直接生成
  %(prog)s --list-styles      # 显示风格列表
        """
    )

    parser.add_argument(
        "--prompt", "-p",
        help="直接使用提示词生成图片"
    )
    parser.add_argument(
        "--selfie", "-s",
        action="store_true",
        help="生成自拍（需要配合 --prompt 使用角色描述）"
    )
    parser.add_argument(
        "--style",
        help="指定拍照风格"
    )
    parser.add_argument(
        "--platform",
        choices=["private", "x", "xiaohongshu"],
        default="private",
        help="目标平台（影响自拍/他拍比例）"
    )
    parser.add_argument(
        "--list-styles",
        action="store_true",
        help="显示所有风格列表"
    )
    parser.add_argument(
        "--output", "-o",
        help="输出目录"
    )

    args = parser.parse_args()

    # 显示风格列表
    if args.list_styles:
        print("自拍风格:")
        for style in SELFIE_STYLES:
            print(f"  - {style}")
        print("\n他拍风格:")
        for style in OTHER_STYLES:
            print(f"  - {style}")
        return

    # 直接生成模式
    if args.prompt:
        client = JimengAPIClient()
        if args.output:
            client.output_dir = args.output

        if args.selfie:
            strategy = SelfieStrategy()
            style = args.style or strategy.select_style(args.platform)
            prompt = strategy.build_full_prompt(args.prompt, style, is_selfie=True)
            print(f"使用风格: {style}")
        else:
            prompt = args.prompt

        print(f"提示词: {prompt}")
        print("正在生成...")

        result = client.generate(prompt, filename_prefix="cli_gen")
        if result["success"]:
            print(f"[+] 成功: {result.get('local_path') or result['url']}")
        else:
            print(f"[-] 失败: {result.get('error')}")

        return

    # 交互式模式
    cli = SelfieAppCLI()
    cli.run_interactive()


if __name__ == "__main__":
    main()
