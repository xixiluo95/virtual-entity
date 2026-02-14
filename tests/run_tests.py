#!/usr/bin/env python3
"""
测试运行脚本
用法：
    python run_tests.py              # 运行所有测试
    python run_tests.py -v           # 详细输出
    python run_tests.py --coverage   # 带覆盖率
    python run_tests.py -k "api"     # 运行包含"api"的测试
"""
import sys
import subprocess
from pathlib import Path


def main():
    """主函数"""
    # 项目根目录
    project_root = Path(__file__).parent.parent
    tests_dir = Path(__file__).parent

    # 基本命令
    cmd = [sys.executable, "-m", "pytest", str(tests_dir)]

    # 添加参数
    args = sys.argv[1:]

    # 如果没有指定参数，添加默认参数
    if not args:
        args = ["-v", "--tb=short"]

    # 检查是否需要覆盖率
    if "--coverage" in args:
        args.remove("--coverage")
        args.extend([
            "--cov=app",
            "--cov-report=term-missing",
            "--cov-report=html:coverage_report"
        ])

    cmd.extend(args)

    # 设置PYTHONPATH
    import os
    env = os.environ.copy()
    env["PYTHONPATH"] = str(project_root / "jimeng-selfie-app")

    # 运行测试
    print(f"运行命令: {' '.join(cmd)}")
    print("-" * 60)

    result = subprocess.run(cmd, env=env, cwd=str(project_root / "jimeng-selfie-app"))

    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
