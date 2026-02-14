---
name: social-media-automation
description: "OpenClaw社交媒体自动化Skill。用于AI图片生成(即梦)、X平台(Twitter)发布、完整工作流程自动化。触发词：生成图片、发布推文、社交媒体、即梦、AI作图、发帖、X平台。"
---

# OpenClaw 社交媒体自动化 Skill

## 概述

本Skill为OpenClaw提供完整的社交媒体自动化能力，包括：
- **即梦平台**：AI图片生成与下载
- **X平台(Twitter)**：推文发布与图片上传
- **完整工作流**：从图片生成到社交媒体发布的端到端自动化

### 技术栈

| 组件 | 说明 |
|------|------|
| 内置模型 | GLM-4.7 (智谱AI) |
| 浏览器连接 | Chrome CDP (端口9222) |
| Python环境 | `~/.openclaw/openclaw-env` |

### 适用场景

- 自动生成AI图片并发布到社交媒体
- 批量内容创作与分发
- 社交媒体账号运营自动化
- 图文内容自动化生产

---

## 浏览器管理（重要！）

### 核心原则

**检测浏览器状态 → 复用已打开的浏览器 → 避免重复打开**

### Chrome调试模式启动

```bash
# 启动Chrome调试模式（首次使用）
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug
```

### 浏览器连接代码

```python
import os
import json
from playwright.sync_api import sync_playwright

def connect_browser():
    """
    连接到Chrome浏览器（复用已打开的浏览器）

    返回:
        browser, context, page
    """
    p = sync_playwright().start()

    try:
        # 尝试连接到已运行的Chrome
        browser = p.chromium.connect_over_cdp("http://localhost:9222")

        # 获取现有上下文和页面
        contexts = browser.contexts
        if contexts:
            context = contexts[0]
        else:
            context = browser.new_context()

        pages = context.pages
        if pages:
            page = pages[0]
        else:
            page = context.new_page()

        return browser, context, page

    except Exception as e:
        print(f"无法连接到Chrome，请确保已启动调试模式: {e}")
        return None, None, None

def navigate_to(page, url):
    """
    智能导航：如果当前不在目标页面，则跳转

    参数:
        page: 页面对象
        url: 目标URL
    """
    current_url = page.url

    # 如果已经在目标页面，直接返回
    if url in current_url:
        print(f"已在目标页面: {current_url}")
        return

    # 否则导航到目标页面
    print(f"导航到: {url}")
    page.goto(url, timeout=60000)
```

### 使用示例

```python
# 连接浏览器（复用已打开的）
browser, context, page = connect_browser()

if page:
    # 智能导航（不会重复打开）
    navigate_to(page, "https://jimeng.jianying.com/")

    # 执行操作...
```

---

## 即梦平台操作指南

### 平台信息

| 项目 | 信息 |
|------|------|
| URL | https://jimeng.jianying.com/ |
| 登录方式 | 扫码登录 (抖音/头条账号) |
| 图片生成时间 | 约10-30秒 |

### 打开即梦平台

```python
# 使用Camoufox浏览器
from camoufox.sync_api import Camoufox

# 启动浏览器
browser = Camoufox(headless=False)
page = browser.new_page()

# 访问即梦
page.goto("https://jimeng.jianying.com/")
```

### 登录流程

1. **首次登录**：需要用户扫码
   - 访问网站后会显示登录二维码
   - 使用抖音App或头条App扫码
   - 登录成功后保存Cookie

2. **后续登录**：使用Cookie持久化

```python
# 保存Cookie
import json

def save_cookies(page, filepath="~/.openclaw/credentials/jimeng_cookies.json"):
    cookies = page.context.cookies()
    with open(filepath, 'w') as f:
        json.dump(cookies, f)

def load_cookies(page, filepath="~/.openclaw/credentials/jimeng_cookies.json"):
    import os
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            cookies = json.load(f)
        page.context.add_cookies(cookies)
        return True
    return False

# 使用示例
load_cookies(page)
page.goto("https://jimeng.jianying.com/")
# 检查是否登录成功
```

### 生成图片

#### 基本流程

```
1. 进入图片生成页面
2. 输入提示词
3. 选择风格（可选）
4. 点击生成
5. 等待完成（10-30秒）
6. 下载图片
```

#### Python代码示例

```python
import time
from camoufox.sync_api import Camoufox

def generate_image_jimeng(prompt: str, output_path: str, style: str = None):
    """
    在即梦平台生成AI图片

    参数:
        prompt: 图片描述提示词
        output_path: 图片保存路径
        style: 风格名称（可选）
    """
    browser = Camoufox(headless=False)
    page = browser.new_page()

    try:
        # 1. 加载Cookie并访问
        load_cookies(page)
        page.goto("https://jimeng.jianying.com/ai-image")

        # 2. 等待页面加载
        page.wait_for_selector("textarea", timeout=30000)

        # 3. 输入提示词
        input_box = page.query_selector("textarea")
        input_box.fill(prompt)

        # 4. 选择风格（如果指定）
        if style:
            # 点击风格选择器
            style_button = page.query_selector(f"text={style}")
            if style_button:
                style_button.click()

        # 5. 点击生成按钮
        generate_btn = page.query_selector("button:has-text('生成')")
        generate_btn.click()

        # 6. 等待生成完成（观察生成状态变化）
        time.sleep(5)  # 初始等待
        # 等待生成完成的标志（如图片出现或进度条完成）
        page.wait_for_selector(".generated-image", timeout=60000)

        # 7. 下载图片
        image = page.query_selector(".generated-image img")
        image_url = image.get_attribute("src")

        # 使用Playwright下载
        import urllib.request
        urllib.request.urlretrieve(image_url, output_path)

        return True, output_path

    except Exception as e:
        return False, str(e)
    finally:
        browser.close()
```

### 提示词技巧

#### 有效提示词结构

```
[主体] + [动作/状态] + [环境/背景] + [风格] + [质量词]
```

#### 示例提示词

| 类型 | 提示词示例 |
|------|-----------|
| 风景 | "金色夕阳下的海边悬崖，远处有帆船，油画风格，高细节，8k画质" |
| 人物 | "身穿白色连衣裙的女孩，站在樱花树下，动漫风格，柔和光线" |
| 产品 | "现代简约风格的咖啡杯，放在木质桌面上，专业摄影，商品展示" |
| 抽象 | "科技感十足的数据流动效果，蓝紫色调，未来主义风格" |

#### 风格建议

| 风格 | 适用场景 |
|------|---------|
| 写实摄影 | 产品展示、真实场景 |
| 动漫风格 | 社交媒体、年轻受众 |
| 油画风格 | 艺术氛围、高端品牌 |
| 水彩风格 | 文艺清新、生活方式 |
| 3D渲染 | 科技产品、游戏相关 |

### 常见问题处理

| 问题 | 解决方案 |
|------|---------|
| 生成失败 | 重试或更换提示词 |
| 图片模糊 | 添加"高清晰"、"8k"、"细节丰富"等质量词 |
| 风格不符 | 明确指定风格关键词 |
| 登录过期 | 重新扫码登录并保存Cookie |

---

## X平台(Twitter)发布指南

### 平台信息

| 项目 | 信息 |
|------|------|
| URL | https://x.com/ |
| 登录方式 | Cookie持久化 / 用户名密码 |
| Cookie路径 | `~/.openclaw/credentials/twitter_cookies.json` |

### 发帖流程（实测）

```
1. 连接Chrome (CDP端口9222)
       ↓
2. 加载Twitter Cookie
       ↓
3. 检查是否在Twitter页面
   ├─ 是 → 继续
   └─ 否 → 访问 https://x.com/
       ↓
4. 检查登录状态
   ├─ 已登录 → 继续
   └─ 未登录 → 提示用户登录（登录后Cookie自动保存）
       ↓
5. 点击发帖按钮（左侧导航栏）
       ↓
6. 在弹出的对话框中输入文字
       ↓
7. [可选] 点击图片图标上传图片
       ↓
8. 点击"发布"按钮
```

### Cookie持久化登录

```python
import json
import os

X_COOKIES_PATH = "~/.openclaw/credentials/twitter_cookies.json"

def save_x_cookies(context):
    """保存X平台Cookie"""
    os.makedirs(os.path.dirname(X_COOKIES_PATH), exist_ok=True)
    cookies = context.cookies()
    # 筛选Twitter相关的cookie
    twitter_cookies = [c for c in cookies if 'twitter' in c.get('domain', '').lower() or 'x.com' in c.get('domain', '').lower()]
    with open(X_COOKIES_PATH, 'w') as f:
        json.dump(twitter_cookies, f, indent=2)
    print(f"已保存 {len(twitter_cookies)} 个Twitter Cookie")

def load_x_cookies(context):
    """加载X平台Cookie"""
    if os.path.exists(X_COOKIES_PATH):
        with open(X_COOKIES_PATH, 'r') as f:
            cookies = json.load(f)
        context.add_cookies(cookies)
        print("Twitter Cookie已加载")
        return True
    return False

def check_x_login(page):
    """检查是否已登录X平台"""
    try:
        # 检查是否存在发帖按钮或用户头像
        post_btn = page.query_selector('[data-testid="SideNav_NewTweet_Button"]')
        if post_btn:
            return True
        # 备用检查：用户头像
        avatar = page.query_selector('[data-testid="UserAvatar"]')
        return avatar is not None
    except:
        return False
```

### 发布推文代码

```python
import time
import os

def post_tweet(page, text: str, image_path: str = None):
    """
    发布推文到X平台

    参数:
        page: Playwright页面对象
        text: 推文内容
        image_path: 图片路径（可选，使用~/图片/目录）
    """
    # 1. 确保在Twitter页面
    if "x.com" not in page.url:
        page.goto("https://x.com/", timeout=60000)
        time.sleep(2)

    # 2. 点击发帖按钮
    print("点击发帖按钮...")
    post_btn = page.query_selector('[data-testid="SideNav_NewTweet_Button"]')
    if not post_btn:
        # 尝试其他选择器
        post_btn = page.query_selector('a[href="/compose/tweet"]')
    if post_btn:
        post_btn.click()
        time.sleep(1)
    else:
        print("未找到发帖按钮，可能未登录")
        return False

    # 3. 等待编辑框出现
    print("输入推文内容...")
    page.wait_for_selector('[data-testid="tweetTextarea_0"]', timeout=10000)

    # 4. 输入文字
    textarea = page.query_selector('[data-testid="tweetTextarea_0"]')
    textarea.click()
    time.sleep(0.3)
    textarea.fill(text)
    time.sleep(0.5)

    # 5. 上传图片（如果有）
    if image_path and os.path.exists(image_path):
        print(f"上传图片: {image_path}")
        file_input = page.query_selector('input[type="file"][data-testid="fileInput"]')
        if not file_input:
            # 查找隐藏的文件输入
            file_input = page.query_selector('input[type="file"]')
        if file_input:
            file_input.set_input_files(image_path)
            time.sleep(3)  # 等待图片上传
        else:
            print("未找到文件上传输入框")

    # 6. 点击发布按钮
    print("发布推文...")
    publish_btn = page.query_selector('[data-testid="tweetButtonInline"]')
    if not publish_btn:
        publish_btn = page.query_selector('[data-testid="tweetButton"]')
    if publish_btn:
        publish_btn.click()
        time.sleep(2)
        print("推文已发布!")
        return True
    else:
        print("未找到发布按钮")
        return False
```

### 完整发帖脚本

```python
#!/usr/bin/env python3
"""
Twitter发帖脚本
"""
import os
import sys
import json
import time

sys.path.insert(0, '~/.openclaw/openclaw-env/lib/python3.12/site-packages')

X_URL = "https://x.com/"
X_COOKIES_PATH = "~/.openclaw/credentials/twitter_cookies.json"
IMAGE_DIR = "~/图片"

def post_tweet(text: str, image_path: str = None):
    """发布推文"""
    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        # 连接到已运行的Chrome
        browser = p.chromium.connect_over_cdp("http://localhost:9222")
        context = browser.contexts[0] if browser.contexts else browser.new_context()

        # 加载Cookie
        if os.path.exists(X_COOKIES_PATH):
            with open(X_COOKIES_PATH, 'r') as f:
                cookies = json.load(f)
            context.add_cookies(cookies)
            print("Cookie已加载")

        page = context.pages[0] if context.pages else context.new_page()

        # 导航到Twitter
        if "x.com" not in page.url:
            page.goto(X_URL, timeout=60000)
            time.sleep(2)

        # 检查登录
        if not page.query_selector('[data-testid="SideNav_NewTweet_Button"]'):
            print("未登录，请先登录Twitter")
            return False

        # 发帖逻辑...
        # （使用上面的post_tweet函数）
```

### 发布推文

#### 纯文字推文

```python
def post_text_tweet(page, text: str):
    """
    发布纯文字推文

    参数:
        page: Playwright页面对象
        text: 推文内容（最多280字符）
    """
    # 1. 点击发帖按钮
    post_btn = page.query_selector('[data-testid="SideNav_NewTweet_Button"]')
    post_btn.click()

    # 2. 等待编辑框出现
    page.wait_for_selector('[data-testid="tweetTextarea_0"]', timeout=10000)

    # 3. 输入推文内容
    textarea = page.query_selector('[data-testid="tweetTextarea_0"]')
    textarea.fill(text)

    # 4. 点击发布按钮
    publish_btn = page.query_selector('[data-testid="tweetButtonInline"]')
    publish_btn.click()

    # 5. 等待发布完成
    page.wait_for_selector('[data-testid="toast"]', timeout=10000)

    print(f"推文已发布: {text[:50]}...")
```

#### 图文推文

```python
import time

def post_image_tweet(page, text: str, image_path: str):
    """
    发布图文推文

    参数:
        page: Playwright页面对象
        text: 推文内容
        image_path: 图片文件路径
    """
    # 1. 点击发帖按钮
    post_btn = page.query_selector('[data-testid="SideNav_NewTweet_Button"]')
    post_btn.click()

    # 2. 等待编辑框出现
    page.wait_for_selector('[data-testid="tweetTextarea_0"]', timeout=10000)

    # 3. 上传图片
    file_input = page.query_selector('[data-testid="fileInput"]')
    file_input.set_input_files(image_path)

    # 4. 等待图片上传完成
    time.sleep(3)  # 等待图片处理

    # 5. 输入推文内容
    textarea = page.query_selector('[data-testid="tweetTextarea_0"]')
    textarea.fill(text)

    # 6. 点击发布按钮
    publish_btn = page.query_selector('[data-testid="tweetButtonInline"]')
    publish_btn.click()

    # 7. 等待发布完成
    page.wait_for_selector('[data-testid="toast"]', timeout=15000)

    print(f"图文推文已发布")
```

### 防封号注意事项

#### 发布频率限制

| 账号类型 | 建议频率 | 说明 |
|---------|---------|------|
| 新账号 | 每天1-3条 | 逐步增加 |
| 老账号 | 每天5-10条 | 稳定运营 |
| 认证账号 | 每天10-20条 | 权限更高 |

#### 行为模拟建议

```python
import random
import time

def human_like_delay():
    """模拟人类行为延迟"""
    delay = random.uniform(2, 8)
    time.sleep(delay)

def random_scroll(page):
    """随机滚动页面"""
    scroll_amount = random.randint(100, 500)
    page.evaluate(f"window.scrollBy(0, {scroll_amount})")
    time.sleep(random.uniform(0.5, 2))

def simulate_browsing(page, duration=30):
    """
    模拟浏览行为

    参数:
        page: 页面对象
        duration: 浏览时长（秒）
    """
    start_time = time.time()
    while time.time() - start_time < duration:
        random_scroll(page)
        human_like_delay()
```

#### 内容多样化

```python
# 避免重复内容的策略
content_templates = [
    "今日分享: {topic} #hashtag",
    "发现一个有趣的事: {content}",
    "{topic} - 你怎么看?",
    "分享一张图片，关于{topic}",
]

import random

def get_varied_content(topic: str, content: str):
    """生成多样化内容"""
    template = random.choice(content_templates)
    return template.format(topic=topic, content=content)
```

---

## 完整工作流程

### 从图片生成到发布

```
┌─────────────────────────────────────────────────────────────┐
│                    完整自动化工作流                           │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   ┌─────────┐        ┌─────────┐        ┌─────────┐
   │  即梦   │        │   下载   │        │   X平台  │
   │ 图片生成 │───────>│  图片   │───────>│  发布   │
   └─────────┘        └─────────┘        └─────────┘
        │                   │                   │
        ▼                   ▼                   ▼
   ┌─────────┐        ┌─────────┐        ┌─────────┐
   │失败重试 │        │存储管理 │        │发布验证 │
   └─────────┘        └─────────┘        └─────────┘
```

### 完整代码示例

```python
import os
import time
import random
from datetime import datetime
from camoufox.sync_api import Camoufox

class SocialMediaAutomation:
    """社交媒体自动化类"""

    def __init__(self):
        self.browser = None
        self.page = None
        self.image_dir = "~/.openclaw/media/generated"
        os.makedirs(self.image_dir, exist_ok=True)

    def start(self):
        """启动浏览器"""
        self.browser = Camoufox(headless=False)
        self.page = self.browser.new_page()

    def stop(self):
        """关闭浏览器"""
        if self.browser:
            self.browser.close()

    def generate_image(self, prompt: str) -> str:
        """
        在即梦生成图片

        返回:
            图片文件路径
        """
        # 生成文件名
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        image_path = os.path.join(self.image_dir, f"jimeng_{timestamp}.png")

        # 加载Cookie
        load_cookies(self.page, "jimeng")

        # 访问即梦
        self.page.goto("https://jimeng.jianying.com/ai-image")
        self.page.wait_for_selector("textarea", timeout=30000)

        # 输入提示词
        textarea = self.page.query_selector("textarea")
        textarea.fill(prompt)

        # 点击生成
        generate_btn = self.page.query_selector("button:has-text('生成')")
        generate_btn.click()

        # 等待生成完成
        self.page.wait_for_selector(".generated-image", timeout=60000)

        # 下载图片
        time.sleep(2)  # 等待图片稳定
        img = self.page.query_selector(".generated-image img")
        if img:
            img_url = img.get_attribute("src")
            # 下载图片逻辑...
            print(f"图片已生成: {image_path}")
            return image_path

        raise Exception("图片生成失败")

    def post_to_x(self, text: str, image_path: str = None) -> bool:
        """
        发布到X平台

        返回:
            是否成功
        """
        # 加载Cookie
        load_x_cookies(self.page)

        # 访问X平台
        self.page.goto("https://x.com/")

        # 检查登录状态
        if not check_x_login(self.page):
            print("请先登录X平台")
            return False

        # 点击发帖
        post_btn = self.page.query_selector('[data-testid="SideNav_NewTweet_Button"]')
        post_btn.click()

        # 等待编辑框
        self.page.wait_for_selector('[data-testid="tweetTextarea_0"]', timeout=10000)

        # 上传图片（如果有）
        if image_path and os.path.exists(image_path):
            file_input = self.page.query_selector('[data-testid="fileInput"]')
            file_input.set_input_files(image_path)
            time.sleep(3)

        # 输入文字
        textarea = self.page.query_selector('[data-testid="tweetTextarea_0"]')
        textarea.fill(text)

        # 发布
        publish_btn = self.page.query_selector('[data-testid="tweetButtonInline"]')
        publish_btn.click()

        # 等待完成
        time.sleep(3)
        print("推文已发布")
        return True

    def run_workflow(self, prompt: str, caption: str):
        """
        执行完整工作流

        参数:
            prompt: 图片生成提示词
            caption: 推文配文
        """
        try:
            self.start()

            # 1. 生成图片
            print("步骤1: 生成图片...")
            image_path = self.generate_image(prompt)

            # 2. 模拟人类行为
            print("步骤2: 模拟浏览...")
            time.sleep(random.uniform(5, 15))

            # 3. 发布到X
            print("步骤3: 发布到X平台...")
            success = self.post_to_x(caption, image_path)

            if success:
                print("工作流完成!")
            else:
                print("发布失败，请检查")

        except Exception as e:
            print(f"工作流出错: {e}")
        finally:
            self.stop()


# 使用示例
if __name__ == "__main__":
    automation = SocialMediaAutomation()

    # 执行完整工作流
    automation.run_workflow(
        prompt="金色夕阳下的海边悬崖，远处有帆船，油画风格，高细节",
        caption="夕阳无限好，只是近黄昏 #日落 #风景"
    )
```

### 错误处理与重试

```python
import time
from functools import wraps

def retry(max_attempts=3, delay=5):
    """重试装饰器"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise
                    print(f"尝试 {attempt + 1} 失败: {e}")
                    time.sleep(delay * (attempt + 1))
            return None
        return wrapper
    return decorator

@retry(max_attempts=3, delay=10)
def generate_image_with_retry(prompt: str):
    """带重试的图片生成"""
    return generate_image_jimeng(prompt, "output.png")
```

---

## Cookie管理

### Cookie存储位置

```
~/.openclaw/credentials/
├── jimeng_cookies.json    # 即梦平台Cookie
├── x_cookies.json         # X平台Cookie
└── ...
```

### Cookie刷新策略

```python
def refresh_cookies(platform: str, page):
    """
    刷新平台Cookie

    参数:
        platform: 平台名称 (jimeng/x)
        page: 页面对象
    """
    cookies = page.context.cookies()

    if platform == "jimeng":
        filepath = "~/.openclaw/credentials/jimeng_cookies.json"
    elif platform == "x":
        filepath = "~/.openclaw/credentials/x_cookies.json"
    else:
        raise ValueError(f"未知平台: {platform}")

    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    with open(filepath, 'w') as f:
        json.dump(cookies, f)

    print(f"{platform} Cookie已更新")
```

---

## 安全与合规

### 重要提醒

1. **遵守平台规则**：各平台都有自动化使用条款，请确保合规使用
2. **频率控制**：避免高频操作导致账号风险
3. **内容合规**：确保发布内容符合平台内容政策
4. **账号安全**：定期检查账号状态，及时处理异常

### 风险提示

| 风险类型 | 说明 | 应对措施 |
|---------|------|---------|
| 账号封禁 | 频繁自动化操作 | 降低频率、模拟人类行为 |
| Cookie过期 | 登录状态失效 | 定期刷新、监控状态 |
| 内容审核 | 内容违规被删 | 遵守平台规则、内容审核 |
| IP封禁 | 同IP大量请求 | 使用代理、分散请求 |

---

## 相关Skills

- **agent-browser**: 通用浏览器自动化
- **twitter-automation**: Twitter API自动化
- **social-content**: 社交媒体内容策略

---

---

## 实测UI交互模式（2026-02-12更新）

### 即梦平台实测要点

#### UI元素位置

| 元素 | 位置/方法 | 说明 |
|------|----------|------|
| 提示词输入框 | `textarea` 选择器，位置约 (283, 488) | 直接定位textarea元素 |
| 发送按钮 | 右下角 (~839, 596) | **方形=生成中，非方形=可点击** |
| 参考图上传 | `input[type="file"]` | 隐藏的文件输入框 |
| 删除参考图 | 悬停图片→左上角X按钮 | 需要先悬停才能看到X |
| 缩略图 | ~195x195，位置 (~140, -94) | 点击查看大图 |
| 大图下载 | width > 300 的img元素 | 从src属性下载 |
| 关闭弹窗 | ESC键 或 X按钮 | 生成完成后要关闭详情弹窗 |
| 返回主页 | 左上角 (~30, 30) | 返回即梦主页 |

#### 生成状态检测代码

```python
# 通过发送按钮判断生成状态
# 关键：按钮位置在右下角 (~839, 596)
# 生成中：方形（黑白），禁用状态
# 生成完成：非方形（向上箭头），灰色

def check_generation_status(page):
    """检查即梦生成状态"""
    btns = page.query_selector_all('button')
    for btn in btns:
        try:
            box = btn.bounding_box()
            if box and 800 < box['x'] < 950 and 580 < box['y'] < 700:
                is_square = abs(box['width'] - box['height']) < 5
                is_disabled = btn.is_disabled()

                if is_square and is_disabled:
                    return "generating"  # 生成中：方形+禁用
                elif not is_square:
                    return "complete"    # 生成完成：非方形（箭头）
                else:
                    return "idle"        # 空闲
        except:
            pass
    return "unknown"
```

#### 判断发送成功的方法

```python
def send_and_verify(page):
    """发送并验证是否成功"""
    # 1. 记录发送前状态
    old_text = page.query_selector('textarea').input_value()

    # 2. 点击发送
    btn.click()
    time.sleep(1)

    # 3. 验证成功标志
    new_text = page.query_selector('textarea').input_value()

    # 成功标志：输入框被清空 或 按钮变成方形+禁用
    is_cleared = (old_text and not new_text)
    status = check_generation_status(page)
    is_generating = status == "generating"

    return is_cleared or is_generating
```

### Twitter/X平台实测要点

#### 发帖流程

| 步骤 | 选择器/方法 |
|------|------------|
| 发帖按钮 | `button:has-text("发帖")` |
| 文本框 | `[data-testid="tweetTextarea_0"]` |
| 上传图片 | `input[type="file"]` |
| 发布按钮 | `button:has-text("发帖")`（底部） |
| 关闭成功弹窗 | `button:has-text("知道了")` |

#### 个人资料设置

| 功能 | 按钮/方法 | 位置 |
|------|----------|------|
| 进入编辑 | `a:has-text("编辑个人资料")` | 个人主页右侧 |
| 更换背景图 | 点击上方中间按钮 | (409-537, 163) |
| 更换头像 | `button:has-text("编辑照片")` | 右侧 (~643, 309) |
| 简介输入框 | `textarea` | 页面中部 |
| 保存 | `button:has-text("保存")` | 页面下方 |

#### 导航栏按钮

| 功能 | 选择器 |
|------|--------|
| 主页 | `[data-testid="AppTabBar_Home_Link"]` |
| 探索 | `[data-testid="AppTabBar_Explore_Link"]` |
| 通知 | `[data-testid="AppTabBar_Notifications_Link"]` |
| 私信 | `[data-testid="AppTabBar_DirectMessage_Link"]` |
| 个人资料 | `[data-testid="AppTabBar_Profile_Link"]` |

#### 私信功能

- 首次使用需设置4位数字密码（输入两次确认）
- 私信端到端加密

### 重要注意事项

1. **即梦弹窗关闭时机**：**每次下载完成后必须立即关闭图片详情弹窗**，不要等到下次生成时才关闭
2. **关闭方法**：按ESC键或点击X按钮
3. **多标签页操作**：浏览器可能打开多个标签页，需要先找到即梦页面的标签页再操作
4. **文件对话框**：点击「编辑照片」会打开系统文件选择对话框
5. **隐私保护**：简介不要包含可识别信息（学校名、公司名等）
6. **判断生成结果**：生成的图片上方有「意图分析」和「任务规划」文字，可以阅读确认是否符合提示词要求

### 即梦图片下载完整流程

```
生成完成 → 点击缩略图查看大图 → 点击"下载"按钮 → 【立即关闭弹窗】
                                              ↑
                                        关键步骤！不要遗漏
```

#### 下载并关闭弹窗的代码

```python
def download_and_close_popup(page):
    """
    下载图片并关闭弹窗

    重要：下载完成后必须立即关闭弹窗，不要等到下次操作
    """
    import time
    import requests
    from datetime import datetime

    # 1. 找到大图
    imgs = page.query_selector_all('img')
    large_img = None
    for img in imgs:
        try:
            box = img.bounding_box()
            if box and box['width'] > 300:
                large_img = img
                break
        except:
            pass

    if not large_img:
        print("未找到大图")
        return None

    # 2. 下载图片
    img_url = large_img.get_attribute('src')
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_path = f"~/图片/即梦生成_{timestamp}.png"

    response = requests.get(img_url)
    with open(output_path, 'wb') as f:
        f.write(response.content)
    print(f"图片已下载: {output_path}")

    # 3. 【关键】立即关闭弹窗
    time.sleep(0.5)
    page.keyboard.press("Escape")
    print("弹窗已关闭")

    return output_path
```

#### 多标签页操作代码

```python
def find_jimeng_page(context):
    """
    在多个标签页中找到即梦页面

    返回:
        即梦页面对象，如果找不到返回None
    """
    for page in context.pages:
        if 'jimeng' in page.url:
            page.bring_to_front()  # 将页面带到前台
            return page
    return None

# 使用示例
browser = p.chromium.connect_over_cdp("http://localhost:9222")
context = browser.contexts[0]

jimeng_page = find_jimeng_page(context)
if jimeng_page:
    # 在即梦页面上操作
    jimeng_page.keyboard.press("Escape")
```

---

---

## 即梦生成检测改进（2026-02-12实测）

### 问题诊断

| 问题 | 原因 | 改进方案 |
|------|------|---------|
| 生成完成检测延迟 | 检测间隔3秒太长 | 缩短到1秒 |
| 未及时发现问题 | URL比较在页面导航后失效 | 使用文本提示+状态检查 |
| 缩略图vs高清图 | 直接下载img src是缩略图 | 点开预览后下载高清版 |

### 改进的检测代码

```python
def wait_for_generation_improved(driver, max_wait=60):
    """
    改进的生成完成检测方法

    关键改进：
    1. 检测间隔缩短到1秒
    2. 使用"已为您生成"文本提示
    3. 同时检测图片数量变化
    """
    from selenium.webdriver.common.by import By
    import time

    start_time = time.time()

    while time.time() - start_time < max_wait:
        elapsed = int(time.time() - start_time)

        # 方法1: 检测文本提示
        hints = driver.find_elements(By.XPATH, "//*[contains(text(), '已为您生')]")
        visible_hints = [h for h in hints if h.is_displayed()]

        # 方法2: 检测新图片URL
        imgs = driver.find_elements(By.XPATH, "//img[contains(@src, 'tos-cn')]")

        print(f"[{elapsed}s] 提示: {len(visible_hints)}, 图片: {len(imgs)}")

        if visible_hints:
            print(f"✅ 检测到生成完成: '{visible_hints[0].text[:50]}...'")
            return True

        time.sleep(1)  # 缩短间隔到1秒

    return False
```

### 下载高清图片

```python
def download_hd_image(driver, save_dir="~/图片"):
    """
    下载高清图片（非缩略图）

    关键：点开预览后才能获取高清URL
    """
    import requests
    from datetime import datetime

    # 找到大尺寸图片（高清版）
    imgs = driver.find_elements(By.XPATH, "//img[contains(@src, 'tos-cn')]")

    for img in imgs:
        try:
            size = img.size
            src = img.get_attribute("src")

            # 高清图通常尺寸较大
            if size['width'] >= 500 and src:
                print(f"找到高清图: {size}")

                # 下载
                headers = {
                    'User-Agent': 'Mozilla/5.0',
                    'Referer': 'https://jimeng.jianying.com/'
                }
                response = requests.get(src, headers=headers, timeout=30)

                if response.status_code == 200:
                    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                    filepath = f"{save_dir}/即梦高清_{timestamp}.webp"

                    with open(filepath, 'wb') as f:
                        f.write(response.content)

                    print(f"已保存: {filepath}")
                    return filepath
        except Exception as e:
            print(f"下载失败: {e}")

    return None
```

---

## X平台完整操作流程（2026-02-12实测）

### 发帖完整流程

```
1. 导航到X主页
       ↓
2. 点击"发帖"按钮
       ↓
3. 上传图片（input[type="file"]）
       ↓
4. 输入配文（div[contenteditable="true"]）
       ↓
5. 点击"发帖"按钮发布
       ↓
6. 关闭可能的弹窗
```

### 关键代码

```python
def post_tweet_with_image(driver, caption, image_path):
    """
    发布图文推文（完整版）

    注意事项：
    1. ChromeDriver不支持emoji（BMP外字符）
    2. 使用JavaScript输入文本绕过限制
    3. 不要点击"下载"按钮（会触发系统对话框）
    """
    from selenium.webdriver.common.by import By
    import time

    # 1. 点击发帖按钮
    post_btns = driver.find_elements(By.XPATH, "//span[text()='发帖']/ancestor::button")
    if post_btns:
        post_btns[0].click()
        time.sleep(2)

    # 2. 上传图片
    file_inputs = driver.find_elements(By.XPATH, "//input[@type='file']")
    if file_inputs:
        file_inputs[0].send_keys(image_path)
        time.sleep(3)

    # 3. 输入配文（使用JS避免emoji问题）
    text_areas = driver.find_elements(By.XPATH, "//div[@contenteditable='true']")
    if text_areas:
        driver.execute_script(f"""
            arguments[0].innerText = `{caption}`;
            arguments[0].dispatchEvent(new InputEvent('input', {{ bubbles: true }}));
        """, text_areas[0])

    # 4. 点击发布
    time.sleep(1)
    publish_btns = driver.find_elements(By.XPATH, "//button[@data-testid='tweetButton']")
    if publish_btns:
        publish_btns[0].click()
        time.sleep(3)

    # 5. 关闭弹窗
    close_btns = driver.find_elements(By.XPATH, "//button[@aria-label='关闭']")
    for btn in close_btns:
        try:
            if btn.is_displayed():
                btn.click()
                break
        except:
            pass
```

### 删除帖子流程

```python
def delete_tweets(driver, count=3):
    """
    删除个人主页上的帖子

    关键：
    1. 必须先进入个人主页
    2. 使用JavaScript点击避免元素拦截
    3. 需要"确认删除"
    """
    from selenium.webdriver.common.by import By
    import time

    for i in range(count):
        print(f"删除第 {i+1} 个帖子...")

        # 重新查找帖子（DOM会变化）
        tweets = driver.find_elements(By.XPATH, "//article[@data-testid='tweet']")
        if not tweets:
            break

        tweet = tweets[0]

        # 找到更多按钮（三个点）
        more_btns = tweet.find_elements(By.XPATH, ".//button[@data-testid='caret']")
        if more_btns:
            # 使用JS点击避免拦截
            driver.execute_script("arguments[0].click();", more_btns[0])
            time.sleep(1)

            # 点击删除选项
            delete_items = driver.find_elements(By.XPATH,
                "//div[@role='menuitem']//span[contains(text(), '删除')]")
            if delete_items:
                driver.execute_script("arguments[0].click();", delete_items[0])
                time.sleep(1)

                # 确认删除
                confirm_btns = driver.find_elements(By.XPATH,
                    "//button[@data-testid='confirmationSheetConfirm']")
                if confirm_btns:
                    driver.execute_script("arguments[0].click();", confirm_btns[0])
                    print("✅ 已删除")
                    time.sleep(2)
```

### 更换头像和背景图

```python
def update_profile_images(driver, avatar_path=None, banner_path=None):
    """
    更换头像和背景图

    关键：
    1. 先点击"编辑个人资料"
    2. 第一个file input是背景图，第二个是头像
    3. 需要"应用"或"保存"两次
    """
    from selenium.webdriver.common.by import By
    import time
    import os

    # 1. 进入编辑页面
    driver.get("https://x.com/settings/profile")
    time.sleep(3)

    # 2. 查找文件输入框
    file_inputs = driver.find_elements(By.XPATH, "//input[@type='file']")

    # 3. 上传背景图（第一个输入框）
    if banner_path and file_inputs:
        file_inputs[0].send_keys(os.path.abspath(banner_path))
        time.sleep(2)

        # 第一次保存
        save_btns = driver.find_elements(By.XPATH, "//button[contains(text(), '保存')]")
        if save_btns:
            save_btns[0].click()
            time.sleep(2)

    # 4. 上传头像（第二个输入框）
    if avatar_path and len(file_inputs) >= 2:
        file_inputs[1].send_keys(os.path.abspath(avatar_path))
        time.sleep(2)

        # 第二次保存
        save_btns = driver.find_elements(By.XPATH, "//button[contains(text(), '保存')]")
        if save_btns:
            save_btns[0].click()
            time.sleep(2)

    print("头像和背景图更新完成")
```

### 常见问题

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| ChromeDriver报错BMP字符 | 不支持emoji | 使用JavaScript输入文本 |
| 点击被拦截 | 其他元素覆盖 | 使用`driver.execute_script("arguments[0].click();", elem)` |
| 系统保存对话框 | 点击下载按钮触发 | 用requests直接下载图片URL |
| 找不到删除选项 | 在首页而非个人主页 | 先进入个人主页 |

---

## 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|---------|
| 2026-02-12 | 1.3.0 | 新增：即梦检测改进、X平台完整操作流程、删除帖子、更换头像背景图 |
| 2026-02-12 | 1.2.0 | 新增：下载后立即关闭弹窗流程、多标签页操作代码 |
| 2026-02-12 | 1.1.0 | 新增实测UI交互模式，个人资料设置功能 |
| 2026-02-11 | 1.0.0 | 初始版本，支持即梦图片生成和X平台发布 |
