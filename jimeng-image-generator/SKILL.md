# 即梦图片生成 Skill

AI图片自动创作技能，OpenClaw可自主生成创意提示词并创作图片。

## 功能

- 自主生成创意提示词（风景/人物/动物/奇幻/艺术五大主题）
- 支持参考图功能（使用之前生成的图片作为参考）
- 自动下载并保存图片到指定目录
- Cookie持久化，无需重复登录

## ⚠️ 重要注意事项（2026-02-13发现）

### 提示词不能有换行符！
**问题**：即梦输入框中，换行符（Enter/回车）会触发**立即生成**，导致只发送了第一行文字。

**解决方案**：提示词必须是**单行格式**，用逗号或句号分隔不同部分，不能使用`\n`换行。

```python
# ❌ 错误示例（会触发立即生成）
prompt = """【角色设定】
一位25岁的亚洲女性...
【服装要求】
白色短款运动背心..."""

# ✅ 正确示例（单行格式）
prompt = "一位25岁的亚洲女性，鹅蛋脸型，杏眼双眼皮，深棕色瞳孔，头发盘成低发髻，白色短款紧身运动背心，黑色五分紧身裤，赤脚站立，完全正面对着镜头..."
```

### 发送按钮需要用JavaScript点击
普通`.click()`有时无效，需要用`driver.execute_script("arguments[0].click();", btn)`

### 参考图上传后要等待
上传参考图后需要等待2-3秒让图片加载完成

### 多参考图上传（2026-02-13突破）
即梦支持上传**多张参考图**来保持角色一致性！

**方法**：连续多次使用同一个`file_input.send_keys()`上传不同图片

```python
# 参考图列表
reference_paths = [
    "/path/to/正面头像.webp",
    "/path/to/侧面头像.webp",
    "/path/to/背面头像.webp",
    "/path/to/正面全身照.webp"
]

# 连续上传多张参考图
file_input = driver.find_element(By.XPATH, "//input[@type='file']")
for ref_path in reference_paths:
    file_input.send_keys(os.path.abspath(ref_path))
    time.sleep(2)  # 每次上传后等待2秒

# 验证：检查blob图片数量
ref_imgs = driver.find_elements(By.XPATH, "//img[contains(@src, 'blob')]")
print(f"已上传 {len(ref_imgs)} 张参考图")
```

**应用场景**：
- 生成全身三视图时，上传面部三视图+已确认的正面全身照
- 确保生成的侧面/背面图与正面图保持面部和身材一致

---

## 前置条件

1. Chrome浏览器运行在调试端口9222：
   ```bash
   google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug
   ```

2. Cookie已保存（首次需要手动登录即梦）

## 使用方法

### 基本用法

```python
# 在OpenClaw中调用
from skills.jimeng_image_generator import generate_image

# 自主创作（随机主题）
image_path = generate_image()

# 指定主题创作
image_path = generate_image(theme="风景")

# 使用参考图创作
image_path = generate_image(use_reference=True)

# 指定主题+参考图
image_path = generate_image(theme="人物", use_reference=True)
```

### 命令行使用

```bash
# 随机主题创作
python3 /home/xixil/.openclaw/workspace/jimeng_creative.py

# 指定主题
python3 /home/xixil/.openclaw/workspace/jimeng_creative.py --theme 风景

# 使用参考图
python3 /home/xixil/.openclaw/workspace/jimeng_creative.py --reference

# 组合使用
python3 /home/xixil/.openclaw/workspace/jimeng_creative.py -t 奇幻 -r
```

## 创意主题

| 主题 | 说明 | 示例提示词 |
|------|------|-----------|
| 风景 | 自然风光 | 壮丽的雪山日出，金色阳光洒在雪峰上，云海翻涌 |
| 人物 | 人物肖像 | 优雅的古风女子，手持团扇，庭院深深 |
| 动物 | 动物世界 | 可爱的橘猫在阳光下打盹，温馨治愈 |
| 奇幻 | 奇幻场景 | 浮空岛屿上的魔法城堡，瀑布倾泻，飞龙盘旋 |
| 艺术 | 艺术风格 | 水墨山水画风格，意境深远，留白得当 |

## 输出位置

- 图片保存目录：`/home/xixil/图片/`
- 截图保存目录：`/home/xixil/.openclaw/workspace/screenshots/`
- Cookie保存位置：`/home/xixil/.openclaw/credentials/jimeng_cookies.json`

## 工作流程（2026-02-13更新）

```
1. 连接Chrome (CDP端口9222)
       ↓
2. 加载Cookie（自动登录）
       ↓
3. 访问即梦网站
       ↓
4. [可选] 上传参考图
       ↓
5. 检查输入框是否有其他文字（有→清空输入框）
       ↓
6. 输入提示词并发送
   └─ 检查是否发送成功
   └─ 没有发送成功则再次点击发送按钮（最多重试3次）
       ↓
7. 等待图片生成（最多2分钟）
       ↓
8. 自动下载并保存图片
       ↓
9. 清理工作：
   └─ 检查输入框是否仍有其他文字（有→清空输入框）
   └─ 检查是否有参考图片（有→删除图片）
```

### 详细步骤说明

```python
# 步骤1: 检查并清空输入框
def check_and_clear_input():
    """检查输入框是否有其他文字，有则清空"""
    current_text = textarea.get_attribute("value")
    if current_text and current_text.strip():
        textarea.clear()  # 清空
        print("✅ 输入框已清空")

# 步骤2: 输入提示词
def input_prompt(prompt):
    """输入提示词"""
    textarea.send_keys(prompt)
    # 验证输入是否成功
    actual = textarea.get_attribute("value")
    if actual == prompt:
        print("✅ 提示词已输入")

# 步骤3: 发送提示词（带重试）
def send_prompt(max_retries=3):
    """发送提示词，检查是否成功，失败则重试"""
    for attempt in range(max_retries):
        send_btn.click()
        # 检查是否发送成功
        remaining = textarea.get_attribute("value")
        if not remaining or not remaining.strip():
            print("✅ 发送成功")
            return True
    return False

# 步骤4: 生成后清理
def cleanup_after_generation():
    """生成完成后的清理工作"""
    # 清空输入框
    check_and_clear_after_send()
    # 删除参考图片
    check_and_remove_reference_image()
```

## 注意事项

1. **会员弹窗**：如果出现会员购买弹窗，脚本会自动关闭
2. **生成时间**：每次生成4张图，需要等待约30-60秒
3. **下载位置**：图片先下载到`/tmp/playwright-artifacts-*/`，然后移动到图片目录
4. **参考图**：会自动使用最新生成的图片作为参考图
5. **生成检测**：使用"已为您生成"文本提示检测，比URL比较更可靠
6. **高清下载**：点开预览后下载高清版，避免下载缩略图
7. **清空输入框**：每次填写提示词并开始生成之后，必须删除输入框内的文字，保证干净
8. **提示词验证**：输入提示词后，必须验证实际输入内容是否与期望一致

---

## 生成状态检测（2026-02-12改进）

### 问题分析

| 问题 | 原因 | 改进方案 |
|------|------|---------|
| 生成完成检测延迟 | 检测间隔3秒太长 | 缩短到1秒 |
| URL比较失效 | 页面导航后URL集合变化 | 使用文本提示检测 |
| 下载的是缩略图 | 直接下载img src | 点开预览后下载高清版 |

### 改进的检测代码

```python
def wait_for_generation(driver, max_wait=60):
    """
    等待图片生成完成（改进版）

    关键改进：
    1. 检测间隔缩短到1秒
    2. 使用"已为您生成"文本提示
    3. 更可靠的完成检测
    """
    from selenium.webdriver.common.by import By
    import time

    start_time = time.time()

    while time.time() - start_time < max_wait:
        elapsed = int(time.time() - start_time)

        # 检测"已为您生成"文本提示
        hints = driver.find_elements(By.XPATH, "//*[contains(text(), '已为您生')]")
        visible_hints = [h for h in hints if h.is_displayed()]

        if visible_hints:
            print(f"[{elapsed}s] ✅ 检测到生成完成")
            return True

        if elapsed % 5 == 0:  # 每5秒打印一次状态
            print(f"[{elapsed}s] 等待生成...")

        time.sleep(1)  # 缩短间隔到1秒

    return False
```

### 下载高清图片

```python
def download_hd_images(driver, save_dir="/home/xixil/图片", count=4):
    """
    下载高清图片（非缩略图）

    关键：
    1. 高清图尺寸通常>=500
    2. 使用requests直接下载避免系统对话框
    """
    import requests
    from datetime import datetime

    headers = {
        'User-Agent': 'Mozilla/5.0',
        'Referer': 'https://jimeng.jianying.com/'
    }

    imgs = driver.find_elements(By.XPATH, "//img[contains(@src, 'tos-cn')]")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    downloaded = 0

    for img in imgs:
        try:
            size = img.size
            src = img.get_attribute("src")

            if size['width'] >= 180 and src:
                response = requests.get(src, headers=headers, timeout=30)

                if response.status_code == 200:
                    filepath = f"{save_dir}/即梦生成_{timestamp}_{downloaded+1}.webp"
                    with open(filepath, 'wb') as f:
                        f.write(response.content)

                    downloaded += 1
                    print(f"已下载: {filepath}")

                    if downloaded >= count:
                        break
        except Exception as e:
            print(f"下载失败: {e}")

    return downloaded
```

### 真实感人像提示词

```python
# 生成真实感女孩的提示词模板
REALISTIC_PORTRAIT_PROMPT = """超写实真人照片，一位年轻女孩的真实肖像，自然光线下的面部细节，真实的皮肤纹理和毛孔，自然的眼部细节和睫毛，真实的头发丝缕，柔和的自然光照射，专业人像摄影，8K超高清，照片级真实感，无AI痕迹，无过度美化，自然妆容，真实的肤色和光影"""

# 图书馆场景提示词
LIBRARY_SCENE_PROMPT = """超写实真人照片，一位年轻女孩坐在安静的图书馆里专心看书，自然光线从窗户洒入，真实的皮肤纹理和毛孔细节，自然的头发丝缕，穿着简约舒适的服装，书架背景，柔和的阅读灯光，专业人像摄影，8K超高清，照片级真实感，自然不造作的表情，专注的阅读姿态"""

# 背景图提示词（横版）
BANNER_PROMPT = """梦幻日落天空，渐变色彩从橙色到紫色，柔和的云层，宁静优美的自然风光，适合作为社交媒体封面背景，16:9横版构图，高清摄影质感，温暖治愈的氛围"""
```

## 错误处理

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| 未登录 | Cookie过期 | 重新运行登录脚本 |
| 连接失败 | Chrome未启动 | 启动Chrome调试模式 |
| 生成超时 | 网络或服务问题 | 增加等待时间或重试 |
| 下载失败 | 权限或空间问题 | 检查目录权限 |

## 集成到OpenClaw

将此Skill添加到OpenClaw的技能列表中，即可让AI助手自主创作图片：

```json
{
  "name": "jimeng-image-generator",
  "description": "AI图片自动创作，支持多种主题和参考图",
  "command": "python3 /home/xixil/.openclaw/workspace/jimeng_creative.py"
}
```

## 示例对话

```
用户：帮我创作一张风景图
OpenClaw：好的，我来为您创作一张风景图。
[调用jimeng-image-generator skill]
创意提示词：壮丽的雪山日出，金色阳光洒在雪峰上，云海翻涌，电影级光效
图片已生成并保存：/home/xixil/图片/即梦_风景_20260211_234500.png

用户：用这张图作为参考，创作一张奇幻主题的图
OpenClaw：好的，我将使用刚才生成的图片作为参考，创作奇幻主题。
[调用jimeng-image-generator skill with reference]
创意提示词：浮空岛屿上的魔法城堡，瀑布倾泻，飞龙盘旋，梦幻朦胧
图片已生成并保存：/home/xixil/图片/即梦_奇幻_20260211_234600.png
```

---

## 角色模板系统（2026-02-12更新 v2.0）

### 概述

角色模板系统用于生成**一致性高、逼真度高**的角色照片。通过定义角色档案和场景模板，可以批量生成同一角色在不同场景下的照片。

### 角色档案位置

```
/home/xixil/图片/角色档案_西娅.md
```

### 使用方法

```python
# 生成角色场景图
from skills.jimeng_image_generator import generate_character_scene

# 指定角色和场景（26种场景可选）
image_path = generate_character_scene(
    character="西娅",
    scene="cafe_alone"  # 见下方场景列表
)

# 使用参考图保持一致性
image_path = generate_character_scene(
    character="西娅",
    scene="street_walking",
    use_reference=True,
    reference_path="/home/xixil/图片/西娅_基准图.png"
)

# 生成三视图
image_path = generate_character_scene(
    character="西娅",
    scene="front_view"  # front_view/side_view/back_view
)
```

### 可用场景列表（26种）

| 类别 | 场景代码 | 描述 |
|------|---------|------|
| **工作** | `office_desk` | 办公室伏案工作 |
| | `office_window` | 办公室窗边思考 |
| | `meeting` | 会议室开会 |
| | `pantry` | 茶水间休息 |
| **餐饮** | `cafe_alone` | 咖啡店独处 |
| | `cafe_work` | 咖啡店工作 |
| | `restaurant_solo` | 餐厅独食 |
| | `bar` | 酒吧 |
| **居家** | `home_morning` | 家中晨起 |
| | `home_sofa` | 沙发追剧 |
| | `home_kitchen` | 厨房做饭 |
| | `home_bathroom` | 浴室镜前 |
| **户外** | `street_walking` | 街头行走 |
| | `subway` | 地铁站 |
| | `supermarket` | 超市购物 |
| | `park` | 公园 |
| | `beach` | 海边 |
| **社交** | `gallery` | 艺术展 |
| | `cinema` | 电影院 |
| | `karaoke` | KTV |
| **运动** | `gym` | 健身房 |
| | `yoga` | 瑜伽馆 |
| | `swimming` | 游泳馆 |
| **文化** | `bookstore` | 书店 |
| | `library` | 图书馆 |
| **三视图** | `front_view` | 正面视图 |
| | `side_view` | 侧面视图 |
| | `back_view` | 背面视图 |

---

## 自拍风格提示词（2026-02-13新增，重要！）

### 核心原则

**三视图制作完成后，所有后续照片都必须是自拍风格，不是他拍！**

自拍风格让角色更有"存在感"，像是角色自己在记录生活，而不是被别人拍摄。

### 自拍 vs 他拍 对比

| 特征 | 自拍风格 ✅ | 他拍风格 ❌ |
|------|-----------|-----------|
| 视角 | 第一人称/手持手机视角 | 第三人称/旁观者视角 |
| 构图 | 稍微仰角或平视，手臂可能在画面边缘 | 完整全身照，专业构图 |
| 表情 | 自然、随意、可能有点歪头 | 刻意摆拍、正式 |
| 氛围 | 生活化、随手拍的感觉 | 摄影棚、专业拍摄感 |
| 手部 | 可能看到一只手拿手机 | 手通常不在画面中 |

---

## 女生自拍姿势大全

### 1. 镜面自拍（全身展示）
```python
SELFIE_MIRROR_GIRL = """
镜面自拍，对着全身镜拍摄，
一只手拿手机遮住半边脸，另一只手自然垂下或比手势，
手机挡住部分脸部，眼睛看向手机屏幕，
全身都在镜子里，身材比例自然，
浴室镜子或试衣间，有生活气息
"""
```

### 2. 举高自拍（显脸小）
```python
SELFIE_HIGH_ANGLE_GIRL = """
举高自拍，手机在头顶斜上方45度，
经典的显脸小角度，下巴微收，
眼睛直视镜头，甜美微笑或可爱表情，
背景虚化，聚焦脸部，少女感十足
"""
```

### 3. 侧脸自拍（文艺气质）
```python
SELFIE_SIDE_GIRL = """
侧脸自拍，手机在侧前方，
展示优美的侧颜线条，眼神望向别处，
若有所思的感觉，文艺气质，
背景可以是窗边、咖啡店或书店
"""
```

### 4. 手比爱心自拍
```python
SELFIE_HEART_HAND = """
手比爱心自拍，双手在脸旁比出爱心，
可能比半颗心或全颗心，
表情可爱甜美，眨眼或微笑，
韩国女生流行的自拍手势
"""
```

### 5. 猫爪手势自拍（秀美甲）
```python
SELFIE_CAT_PAW = """
猫爪手势自拍，手在脸旁做猫爪状，
像小猫一样可爱，可能露出指甲展示美甲，
表情俏皮，嘟嘴或卖萌，
日系少女风格
"""
```

### 6. 撩头发自拍
```python
SELFIE_HAIR_FLIP = """
撩头发自拍，一只手轻撩头发，
展示颈部线条，气质优雅，
眼神可能看向镜头或望向一边，
自然不做作的动作
"""
```

### 7. 背影自拍（展示穿搭）
```python
SELFIE_BACK_VIEW_GIRL = """
背影自拍，背对镜子拍摄，
展示穿搭和发型，可能回头看镜头，
一手拿手机一手叉腰，时尚博主姿势，
全身构图，服装细节清晰
"""
```

### 8. 趴着自拍（慵懒可爱）
```python
SELFIE_LYING_GIRL = """
趴着自拍，趴在床上或沙发上，
手机与脸平视，双手撑着下巴，
表情慵懒可爱，可能歪头，
家居服或睡衣，温馨氛围
"""
```

### 9. 喝饮料自拍
```python
SELFIE_DRINK_GIRL = """
喝饮料自拍，一手拿奶茶或咖啡一手拿手机，
吸管可能叼在嘴里，
表情自然可爱，生活化场景，
街头或咖啡店背景
"""
```

### 10. 戴墨镜自拍
```python
SELFIE_SUNGLASSES_GIRL = """
戴墨镜自拍，时尚酷感，
可能把墨镜架在头顶或戴着，
表情自信或神秘，
户外阳光明媚的场景
"""
```

---

## 男生自拍姿势大全

### 1. 对镜自拍（最流行）
```python
SELFIE_MIRROR_BOY = """
对镜自拍，对着镜子拍，
整理好仪容，拿手机按下快门，
可以拍半身做表情，也可以拍全身穿搭，
害羞的话把手机挡在脸前，神秘感十足，
只要有镜子就能用
"""
```

### 2. 撑脸自拍（显脸小）
```python
SELFIE_CHIN_REST_BOY = """
撑脸自拍，手撑在下巴或脸颊旁，
看起来脸变小了，表情自然放松，
慵懒或思考的感觉，
这个姿势男生女生都适用
"""
```

### 3. 仰角自拍（五官立体）
```python
SELFIE_HIGH_ANGLE_BOY = """
仰角自拍，手机拿高往下拍，
脸会有显瘦效果，山根变得挺拔，
五官瞬间立体，不信试试看，
男生必会的自拍角度
"""
```

### 4. 配件自拍（增加造型感）
```python
SELFIE_PROPS_BOY = """
配件自拍，手里拿着东西，
可以是咖啡杯、墨镜、帽子、耳机等，
增加造型感，照片更有灵魂，
避免单纯面对镜头的尴尬
"""
```

### 5. 帽T自拍（酷帅可爱）
```python
SELFIE_HOODIE_BOY = """
帽T自拍，把帽子戴起来，
平拍、仰拍、俯拍都有不同感觉，
搭配表情，又酷又可爱，
所有男生都要会的自拍方式
"""
```

### 6. 搞怪自拍（自然有趣）
```python
SELFIE_FUNNY_BOY = """
搞怪自拍，不一定要单一表情，
嘟嘴、皱眉、吐舌头等淘气动作，
散发出自然的氛围，
让女生觉得你很可爱
"""
```

### 7. 趴着自拍（家居男友感）
```python
SELFIE_LYING_BOY = """
趴着自拍，趴在床上或沙发上，
手机与脸平视，多样表情，
家居男友氛围感，
手臂稍微挤到脸，可爱度上升
"""
```

### 8. 反镜头对镜自拍（三重效果）
```python
SELFIE_TRIPLE_MIRROR = """
反镜头对镜自拍，前镜头面向镜子，
拍出有三个自己的特殊效果，
适合喜欢不同风格的男生，
半身穿搭也很适合
"""
```

### 9. 抓衣领自拍（酷帅感）
```python
SELFIE_COLLAR_GRAB = """
抓衣领自拍，一手抓着衣领，
酷帅有型，眼神自信，
像模特一样的感觉，
简单动作瞬间提升气质
"""
```

### 10. 肌肉自拍（展示身材）
```python
SELFIE_MUSCLE_BOY = """
肌肉自拍，展示健身成果，
自信的姿势，凸显身材优点，
看起来超性感，男人味十足，
健身房镜子前或运动后
"""
```

---

## 通用自拍场景模板

### 咖啡店自拍
```python
SELFIE_CAFE = """
咖啡店自拍，一手拿咖啡一手拿手机，
对着咖啡店镜子或窗边拍，
穿着时尚休闲，表情自然随意，
背景有咖啡店装饰，生活化朋友圈感
"""
```

### 办公室/工作自拍
```python
SELFIE_OFFICE = """
办公室工位自拍，累了抬头拍一张，
背景是电脑屏幕和文件，有点乱，
表情略带疲惫但还是有笑容，
工作间隙发的动态感
"""
```

### 街头逛街自拍
```python
SELFIE_STREET = """
街头自拍，边走边拍，
背景是商店橱窗和行人，
穿着时尚，可能提着购物袋，
阳光明媚的好心情
"""
```

### 健身房自拍
```python
SELFIE_GYM = """
健身房镜子前自拍，运动后，
额头有汗珠，脸微红，
穿着运动服，展示身材线条，
背景有健身器材
"""
```

### 居家自拍
```python
SELFIE_HOME = """
居家自拍，穿着舒适的家居服，
坐在沙发或床上，随意姿势，
素颜或淡妆，头发可能扎起来，
温馨的居家氛围
"""
```

### 浴室自拍
```python
SELFIE_BATHROOM = """
浴室镜前自拍，刚洗完脸或护肤后，
头发扎起来，脸上可能有水珠，
素颜状态，皮肤真实质感，
浴室背景，毛巾和护肤品可见
"""
```

### 海边度假自拍
```python
SELFIE_BEACH = """
海边度假自拍，戴着墨镜或帽子，
可能比剪刀手或撩头发，
背景是大海和天空，阳光灿烂，
度假好心情溢出屏幕
"""
```

### 书店/图书馆自拍
```python
SELFIE_BOOKSTORE = """
书店自拍，手里拿着一本书，
文艺气质，若有所思的表情，
背景是书架和书籍，
安静的文化氛围
"""
```

### 和宠物自拍
```python
SELFIE_WITH_PET = """
和宠物自拍，抱着猫猫或狗狗，
宠物可能舔脸或看镜头，
表情温暖有爱，
女生看到绝对融化
"""
```

### 睡前自拍
```python
SELFIE_BEDTIME = """
睡前自拍，穿着睡衣，
头发有点乱，素颜或淡妆，
躺在床上或靠在床头，慵懒感，
卧室背景，柔和的灯光
"""
```

### 运动后自拍
```python
SELFIE_POST_WORKOUT = """
运动后自拍，额头有汗珠，
脸微微泛红，气色好，
健身房镜子前或户外背景，
运动服装，活力满满
"""
```

### 吃饭自拍
```python
SELFIE_EATING = """
吃饭自拍，嘴边可能有食物，
一手拿餐具一手拿手机，
餐桌上摆着食物，生活化场景，
可能有点搞怪的表情
"""
```

---

## AI 自拍提示词参考（来自 Midjourney）

以下提示词来自 [OpenArt](https://openart.ai/blog/post/midjourney-prompts-for-selfie)：

| 场景 | 英文提示词 | 中文翻译 |
|------|-----------|---------|
| 自然光女生 | Hyper-realistic selfie of a young woman in natural light, minimal makeup, casual attire, Instagram-ready | 自然光下的超写实女生自拍，淡妆，休闲装，Instagram风格 |
| 胡子男生 | Realistic selfie of a man with a beard, wearing glasses, in a cozy indoor setting, warm lighting | 戴眼镜有胡子的男生自拍，温馨室内，暖光 |
| 潮发女生 | High-definition selfie of a woman with vibrant hair color, trendy outfit, urban background | 发色鲜艳的女生高清自拍，潮流穿搭，城市背景 |
| 微笑特写 | Realistic close-up selfie of a smiling woman, clear skin, natural makeup, outdoor setting | 户外微笑女生特写自拍，清透肌肤，自然妆容 |
| 职场男士 | Realistic selfie of a man in a suit, professional look, office background, confident expression | 穿西装的职场男士自拍，办公室背景，自信表情 |
| 海边女生 | Realistic selfie of a woman in a summer dress, beach background, golden hour lighting | 穿夏裙的女生自拍，海边背景，黄金时刻光线 |
| 情侣自拍 | Realistic selfie of a couple, happy expressions, casual clothing, park setting | 情侣自拍，开心表情，休闲装，公园场景 |
| 雀斑女生 | Realistic selfie of a woman with freckles, minimal makeup, natural light, garden background | 有雀斑的女生自拍，淡妆，自然光，花园背景 |
| 戴帽男生 | Realistic selfie of a man with a hat, casual attire, cityscape background, evening light | 戴帽子的男生自拍，休闲装，城市背景，傍晚光线 |
| 看书女生 | Realistic selfie of a woman with glasses, reading a book, cozy indoor setting, warm tones | 戴眼镜看书的女生自拍，温馨室内，暖色调 |
| 和狗自拍 | Realistic selfie of a man with a dog, outdoor park setting, sunny day | 男生和狗的自拍，户外公园，阳光明媚 |
| 健身女生 | Realistic selfie of a woman in workout clothes, gym background, energetic vibe | 穿运动服的女生自拍，健身房背景，活力感 |
| 弹吉他男生 | Realistic selfie of a man with a guitar, casual attire, home studio background | 弹吉他的男生自拍，休闲装，家庭录音室背景 |
| 喝咖啡女生 | Realistic selfie of a woman with a coffee cup, cafe background, relaxed atmosphere | 喝咖啡的女生自拍，咖啡店背景，轻松氛围 |
| 滑板男生 | Realistic selfie of a man with a skateboard, urban street background, youthful energy | 拿滑板的男生自拍，城市街头背景，青春活力 |

---

## 自拍风格强制要求

**生成任何角色场景图时，必须包含以下自拍关键词之一：**

```
必需选项（选一）：
1. "自拍视角" + "手持手机"
2. "镜面自拍" + "对着镜子"
3. "举高自拍" + "手机在上方"
4. "侧脸自拍" + "手机在侧边"
5. "对镜自拍" + "镜子反射"
```

**禁止使用以下他拍关键词：**
```
❌ "专业人像摄影"
❌ "摄影师视角"
❌ "旁观者角度"
❌ "完整构图"
❌ "摆拍姿势"
❌ "被拍摄"
```

---

## 真实感优化关键词（重要！）

### 问题诊断与解决方案

| 问题 | 原因 | 解决关键词 |
|------|------|-----------|
| 朦胧感/边缘虚化 | AI倾向添加柔焦效果 | 锐利清晰、边缘锐利、无虚化、f/5.6光圈 |
| 皮肤太完美 | AI过度美化 | 可见毛孔、肤色不均、眼下暗沉、不是瓷娃娃 |
| 环境太干净 | AI生成"样板间"效果 | 地面灰尘、桌面杂物、水渍、生活痕迹 |
| 表情狰狞 | AI不懂自然表情 | 发呆走神、嘴角放松、眼神柔和、不瞪眼 |
| 光线太完美 | AI用影棚光 | 自然日光、明暗过渡、有阴影、非专业打光 |

### 真实感增强词（每次必用）

```python
REALISM_ENHANCERS = """
【清晰度】
锐利清晰的对焦，边缘清晰锐利，无虚化无朦胧感，
高解析度细节，主体背景都清晰，f/5.6中等景深

【皮肤真实】
真实的皮肤纹理，可见的毛孔，轻微肤色不均，
眼下有轻微暗沉，T区有自然油光，不是瓷娃娃

【表情自然】
自然放松的面部表情，嘴角自然下垂或微微上扬，
眼神柔和不发直，眉毛自然舒展，像被偷拍的自然状态

【环境真实】
环境有生活痕迹，地面有灰尘或污渍，
物体有使用痕迹，不是样板间

【光线自然】
自然日光或室内灯光，有明暗过渡和阴影，
非专业影棚打光，光线有层次感
"""
```

---

## 角色模板代码

```python
# 角色定义（西娅）
CHARACTER_TEMPLATES = {
    "西娅": {
        "name": "西娅",
        "age": 25,
        "height": "168cm",

        # 外貌特征（每次必用）
        "appearance": """一位25岁的亚洲女性，鹅蛋脸，杏眼双眼皮，深棕色瞳孔，及肩黑色长发，白皙肤色，脸上完全没有痣，手臂上有几个小雀斑，膝盖有轻微疤痕，身高168cm，身材纤细匀称，气质优雅知性""",

        # 26种场景模板
        "scenes": {
            # === 工作场景 ===
            "office_desk": {
                "description": "开放式办公室，工位上堆着文件和办公用品",
                "clothing": "白色衬衫，黑色西装外套，戴细框眼镜",
                "pose": "低头看文件或电脑屏幕，手扶额头，专注但略带疲惫",
                "expression": "自然的皱眉，不狰狞，专注工作状态",
                "environment": "桌面有咖啡杯、便利贴、散落的笔，键盘有灰尘",
                "lighting": "头顶日光灯，屏幕反光，非完美光线"
            },

            "office_window": {
                "description": "办公室落地窗前，窗外是城市天际线",
                "clothing": "解开一颗扣子的衬衫，脱掉外套搭在椅背上",
                "pose": "双手抱胸，望向窗外，侧身站立",
                "expression": "发呆走神，眼神空洞，嘴巴微张",
                "environment": "玻璃上有轻微污渍，窗框有灰尘",
                "lighting": "下午阳光斜射，脸部有明暗对比"
            },

            "meeting": {
                "description": "会议室，投影仪投出模糊的图表",
                "clothing": "正式西装套装，笔记本摊开",
                "pose": "坐在会议椅上，手托下巴，做笔记",
                "expression": "认真听讲，偶尔点头，微倦但不狰狞",
                "environment": "桌面有水杯和笔，椅子皮革有磨损痕迹",
                "lighting": "投影仪蓝光+日光灯混合，色温不均"
            },

            "pantry": {
                "description": "公司茶水间，咖啡机、微波炉",
                "clothing": "脱掉外套，只穿衬衫，袖子卷起",
                "pose": "靠在柜台边，手里拿着咖啡杯",
                "expression": "放松，嘴角自然下垂，发呆",
                "environment": "台面有咖啡渍，水槽有未洗的杯子",
                "lighting": "日光灯，有阴影"
            },

            # === 餐饮场景 ===
            "cafe_alone": {
                "description": "街角咖啡店，靠窗位置，窗外是行人",
                "clothing": "米色针织开衫，白色内搭",
                "pose": "双手捧着咖啡杯，低头看手机或发呆",
                "expression": "无聊发呆，眼神涣散，嘴巴自然闭合",
                "environment": "桌面有咖啡渍，杯垫有水痕，窗玻璃有反光",
                "lighting": "午后阳光透过玻璃，有斑驳光影"
            },

            "cafe_work": {
                "description": "咖啡店角落，笔记本电脑，咖啡杯",
                "clothing": "休闲通勤装，针织衫+阔腿裤",
                "pose": "低头打字，一只手托腮",
                "expression": "专注但疲惫，眉头微皱，自然不狰狞",
                "environment": "桌面杂乱，有笔记本、手机、耳机线缠绕",
                "lighting": "室内灯光+窗外自然光混合"
            },

            "restaurant_solo": {
                "description": "中档餐厅，一人桌，对面是空椅子",
                "clothing": "简约连衣裙，小外套",
                "pose": "正在吃饭，筷子或叉子送到嘴边",
                "expression": "自然的咀嚼表情，不刻意，放松",
                "environment": "桌上有餐巾纸团，盘子有酱汁痕迹",
                "lighting": "暖色调室内灯光，有阴影"
            },

            "bar": {
                "description": "昏暗的酒吧，霓虹灯光",
                "clothing": "黑色小礼服，高跟鞋",
                "pose": "坐在吧台边，手持鸡尾酒杯",
                "expression": "微醺，眼神迷离，嘴角微微上扬",
                "environment": "吧台有水渍，背景有人影晃动",
                "lighting": "昏暗霓虹，脸部有彩色反光"
            },

            # === 居家场景 ===
            "home_morning": {
                "description": "卧室，乱糟糟的被子，床头柜有闹钟和手机",
                "clothing": "丝绸睡衣，头发微乱，素颜或淡妆",
                "pose": "坐在床边，揉眼睛，打哈欠",
                "expression": "刚睡醒，眼睛半睁，迷茫",
                "environment": "床头有书本、眼镜、发圈，被子没叠好",
                "lighting": "早晨阳光透过窗帘，有灰尘飘浮"
            },

            "home_sofa": {
                "description": "客厅沙发，电视亮着，茶几上有零食",
                "clothing": "宽松T恤，运动短裤，光脚",
                "pose": "蜷缩在沙发角落，抱着抱枕",
                "expression": "看着电视，嘴角自然的表情，不刻意",
                "environment": "茶几上有零食袋、遥控器、水杯，沙发有褶皱",
                "lighting": "电视蓝光+台灯暖光混合"
            },

            "home_kitchen": {
                "description": "厨房，灶台上有锅，台面有食材",
                "clothing": "家居服，头发扎起",
                "pose": "在切菜或搅拌，动作自然",
                "expression": "专注但不紧张，嘴角放松",
                "environment": "台面有面粉或酱汁痕迹，水槽有碗",
                "lighting": "厨房顶灯，窗户有自然光"
            },

            "home_bathroom": {
                "description": "浴室，镜子前，洗漱台上有护肤品",
                "clothing": "浴袍，头发湿漉漉，脸上可能有面膜",
                "pose": "对着镜子，正在护肤或化妆",
                "expression": "认真端详自己，微皱眉或放松",
                "environment": "镜面有水珠，台面有护肤品瓶子，毛巾有褶皱",
                "lighting": "浴室顶灯，侧光"
            },

            # === 户外场景 ===
            "street_walking": {
                "description": "城市商业区街道，人行道",
                "clothing": "驼色风衣，牛仔裤，运动鞋",
                "pose": "自然行走，一只脚刚迈出，手臂自然摆动",
                "expression": "看手机或望向前方，不看向镜头，走神状态",
                "environment": "地面有污渍和落叶，背景有行人、车辆",
                "lighting": "自然日光，有阴影"
            },

            "subway": {
                "description": "地铁站台，有等车的乘客",
                "clothing": "通勤装，背着帆布包",
                "pose": "站着看手机，或靠着柱子",
                "expression": "无聊，目光呆滞，等车的无奈",
                "environment": "地面有黑色污渍，墙上有广告，有垃圾桶",
                "lighting": "日光灯，有阴影"
            },

            "supermarket": {
                "description": "超市货架间，推着购物车",
                "clothing": "休闲装，运动鞋，扎马尾",
                "pose": "推着购物车，伸手拿货架上的商品",
                "expression": "认真挑选，微皱眉，对比商品",
                "environment": "货架有商品，地面有污渍，购物车有灰尘",
                "lighting": "超市日光灯，明亮但有阴影"
            },

            "park": {
                "description": "城市公园，长椅，有树荫",
                "clothing": "休闲连衣裙，平底鞋",
                "pose": "坐在长椅上，翘着二郎腿，看手机",
                "expression": "放松，偶尔抬头看周围",
                "environment": "长椅有划痕，地面有落叶和尘土",
                "lighting": "树荫下的斑驳阳光"
            },

            "beach": {
                "description": "沙滩，海浪，远处有人",
                "clothing": "沙滩长裙或泳衣外搭罩衫，太阳镜",
                "pose": "赤脚站在沙滩上，裙摆被风吹起",
                "expression": "望向大海，微眯眼（阳光刺眼）",
                "environment": "沙滩有脚印，海水有泡沫",
                "lighting": "强烈阳光，有高光和阴影"
            },

            # === 社交场景 ===
            "gallery": {
                "description": "艺术画廊，墙上挂着画",
                "clothing": "文艺风格，衬衫+长裙",
                "pose": "站在画作前，微微侧身观赏",
                "expression": "认真看画，若有所思",
                "environment": "地面有磨损痕迹，画框有灰尘",
                "lighting": "画廊射灯，有明暗对比"
            },

            "cinema": {
                "description": "电影院座位，屏幕亮着",
                "clothing": "休闲装，手里拿着爆米花",
                "pose": "坐在座位上，身体略微后仰",
                "expression": "看电影，被剧情吸引或无聊",
                "environment": "座位有磨损，地面有爆米花渣",
                "lighting": "屏幕光线，昏暗环境"
            },

            "karaoke": {
                "description": "KTV包厢，霓虹灯光，麦克风",
                "clothing": "时尚休闲装，可能化了妆",
                "pose": "坐在沙发上，拿着麦克风，或唱歌",
                "expression": "投入唱歌，或疲惫地坐着",
                "environment": "桌面有酒瓶、果盘，沙发有褶皱",
                "lighting": "霓虹灯光，有阴影"
            },

            # === 运动场景 ===
            "gym": {
                "description": "健身房，器械区",
                "clothing": "瑜伽裤，运动内衣，运动外套",
                "pose": "在跑步机上，或做拉伸动作",
                "expression": "专注或疲惫，额头有汗珠",
                "environment": "器械有汗渍，地面有灰尘",
                "lighting": "健身房日光灯，有阴影"
            },

            "yoga": {
                "description": "瑜伽馆，瑜伽垫，镜子墙",
                "clothing": "瑜伽服，扎马尾或散发",
                "pose": "瑜伽姿势，如树式或下犬式",
                "expression": "专注，呼吸均匀，闭眼或睁眼",
                "environment": "瑜伽垫有褶皱，镜子有手印",
                "lighting": "柔和自然光，有阴影"
            },

            "swimming": {
                "description": "室内游泳馆，泳池边",
                "clothing": "泳衣，泳帽，可能有泳镜",
                "pose": "坐在泳池边，或站在水里",
                "expression": "放松，可能有水珠在脸上",
                "environment": "池边有水渍，瓷砖有磨损",
                "lighting": "游泳馆灯光，水面反光"
            },

            # === 文化场景 ===
            "bookstore": {
                "description": "文艺书店，书架林立",
                "clothing": "棉麻衬衫，长裙，平底鞋",
                "pose": "站在书架前翻看书，或蹲在地上找书",
                "expression": "认真看书，或若有所思",
                "environment": "书架有灰尘，地面有书掉落，书页有折痕",
                "lighting": "温暖的阅读灯光，有阴影"
            },

            "library": {
                "description": "大学图书馆，自习区",
                "clothing": "休闲装，可能戴着耳机",
                "pose": "坐在桌前，摊开书本和笔记本",
                "expression": "认真学习，偶尔发呆",
                "environment": "桌面有书本、笔、水杯，椅子有磨损",
                "lighting": "图书馆灯光，窗边有自然光"
            },

            # === 三视图 ===
            "front_view": {
                "description": "纯白色或浅灰色背景，无杂物",
                "clothing": "白色短款紧身运动背心（露出腰部），黑色五分紧身裤，赤脚",
                "pose": "正面站立，双手自然垂于身体两侧，双脚并拢",
                "expression": "自然放松，直视镜头",
                "environment": "纯白背景，便于抠图和建模参考",
                "lighting": "均匀光线，无阴影",
                "special": "全身可见，从头到脚完整，比例准确，适合3D建模参考，脸上无痣"
            },

            "side_view": {
                "description": "纯白色或浅灰色背景，无杂物",
                "clothing": "白色短款紧身运动背心（露出腰部），黑色五分紧身裤，赤脚",
                "pose": "标准90度正侧面，身体完全侧对镜头，只能看到一只眼睛，看不到另一只眼睛，可以看到半个后脑勺，双手自然下垂",
                "expression": "自然放松，平视前方",
                "environment": "纯白背景，便于抠图和建模参考",
                "lighting": "均匀光线，无阴影",
                "special": "全身可见，标准90度正侧面，只能看到一只眼睛，适合3D建模参考，脸上无痣"
            },

            "back_view": {
                "description": "纯白色或浅灰色背景，无杂物",
                "clothing": "白色短款紧身运动背心（露出腰部），黑色五分紧身裤，赤脚",
                "pose": "完全背对镜头站立，双手自然垂于身体两侧",
                "expression": "头部自然正对前方",
                "environment": "纯白背景，便于抠图和建模参考",
                "lighting": "均匀光线，无阴影",
                "special": "全身可见，背面轮廓清晰，适合3D建模参考，脸上无痣"
            },

            # === 人头三视图（头部特写）===
            "head_front": {
                "description": "纯白色背景，头部正面特写",
                "clothing": "白色短款紧身运动背心",
                "pose": "头部正对镜头，从头顶到锁骨",
                "expression": "自然放松，直视镜头",
                "environment": "纯白背景",
                "lighting": "均匀光线",
                "special": "头部特写，脸上无痣，五官清晰"
            },

            "head_side": {
                "description": "纯白色背景，头部90度正侧面特写",
                "clothing": "白色短款紧身运动背心",
                "pose": "标准90度正侧面，只能看到一只眼睛，看不到另一只眼睛，可以看到半个后脑勺，从头顶到锁骨",
                "expression": "自然放松，平视前方",
                "environment": "纯白背景",
                "lighting": "均匀光线",
                "special": "头部侧面特写，只能看到一只眼睛，脸上无痣"
            },

            "head_back": {
                "description": "纯白色背景，头部背面特写",
                "clothing": "白色短款紧身运动背心",
                "pose": "完全背对镜头，从头顶到肩胛骨",
                "expression": "头部自然正对前方",
                "environment": "纯白背景",
                "lighting": "均匀光线",
                "special": "头部背面特写，可见后颈和耳朵，脸上无痣"
            }
        }
    }
}


def generate_character_prompt(character_name: str, scene_type: str) -> str:
    """
    生成角色场景提示词

    参数:
        character_name: 角色名称（如"西娅"）
        scene_type: 场景类型（见上方26种场景）

    返回:
        完整的提示词字符串
    """
    character = CHARACTER_TEMPLATES.get(character_name)
    if not character:
        raise ValueError(f"未找到角色: {character_name}")

    scene = character["scenes"].get(scene_type)
    if not scene:
        available = list(character["scenes"].keys())
        raise ValueError(f"未找到场景: {scene_type}，可用场景: {available}")

    # 拼接提示词
    prompt = f"""
{character["appearance"]}

场景：{scene["description"]}
服装：{scene["clothing"]}
姿态：{scene["pose"]}
表情：{scene["expression"]}
环境：{scene["environment"]}
光线：{scene["lighting"]}

{REALISM_ENHANCERS}
""".strip()

    return prompt
```

### 一致性保持策略

#### 方法一：使用参考图（推荐）

```
1. 首先使用"office"场景生成一张满意的"定妆照"
2. 将满意的照片保存为角色基准图：/home/xixil/图片/西娅_基准图.png
3. 每次生成新场景时，上传基准图作为参考图
4. 即梦会保持角色的核心外貌特征
```

#### 方法二：固定提示词结构

```
每次生成使用相同的"外貌特征"部分，只修改"场景"部分。
核心特征（必须每次出现）：
- 鹅蛋脸、杏眼双眼皮、深棕色瞳孔
- 及肩黑色长发
- 左脸颊有一颗小痣
- 白皙细腻的肤色
- 气质优雅知性
```

### 场景生成示例

#### 办公室场景
```
一位25岁的亚洲女性，鹅蛋脸，杏眼双眼皮，深棕色瞳孔，
及肩黑色长发，白皙细腻的肤色，左脸颊有一颗小痣，
身高168cm，身材纤细匀称，气质优雅知性，

场景：现代高档办公室
服装：白色衬衫和黑色西装外套，戴细框金边眼镜
姿态：坐在办公桌前看文件，专注的表情
光线：办公室自然光，窗外城市天际线
氛围：专业、干练、优雅

真实照片质感，自然的皮肤纹理和毛孔细节，
真实的光影过渡，非完美打光，
iPhone原相机拍摄质感，无滤镜无美颜，
35mm焦距人像，自然景深，
照片级真实感，超写实人像摄影
```

#### 咖啡店场景
```
一位25岁的亚洲女性，鹅蛋脸，杏眼双眼皮，深棕色瞳孔，
及肩黑色长发，白皙细腻的肤色，左脸颊有一颗小痣，
身高168cm，身材纤细匀称，气质优雅知性，

场景：精致的城市咖啡店，靠窗位置
服装：米色针织开衫，白色连衣裙
姿态：喝咖啡，望向窗外，悠闲的姿态
光线：午后阳光透过玻璃窗
氛围：悠闲、文艺、知性

真实照片质感，自然的皮肤纹理和毛孔细节，
真实的光影过渡，非完美打光，
iPhone原相机拍摄质感，无滤镜无美颜，
35mm焦距人像，自然景深，
照片级真实感，超写实人像摄影
```

#### 街头场景
```
一位25岁的亚洲女性，鹅蛋脸，杏眼双眼皮，深棕色瞳孔，
及肩黑色长发，白皙细腻的肤色，左脸颊有一颗小痣，
身高168cm，身材纤细匀称，气质优雅知性，

场景：城市商业区街道
服装：驼色风衣，黑色连衣裙，短靴
姿态：自然行走，不看镜头，生活化姿态
光线：自然日光
氛围：都市、时尚、自然

真实照片质感，自然的皮肤纹理和毛孔细节，
真实的光影过渡，非完美打光，
iPhone原相机拍摄质感，无滤镜无美颜，
35mm焦距人像，自然景深，
像朋友随手抓拍，不做作不摆拍，
照片级真实感，超写实人像摄影
```

### 角色档案管理

#### 添加新角色

在 `CHARACTER_TEMPLATES` 字典中添加新的角色定义：

```python
CHARACTER_TEMPLATES["新角色名"] = {
    "name": "新角色名",
    "age": 年龄,
    "height": "身高",
    "appearance": "详细的外貌描述...",
    "scenes": {
        "scene_name": {
            "description": "场景描述",
            "clothing": "服装描述",
            "pose": "姿态描述",
            "lighting": "光线描述",
            "mood": "氛围描述"
        },
        # 更多场景...
    }
}
```

#### 添加新场景

在角色的 `scenes` 字典中添加新场景：

```python
CHARACTER_TEMPLATES["西娅"]["scenes"]["新场景"] = {
    "description": "场景描述",
    "clothing": "服装描述",
    "pose": "姿态描述",
    "lighting": "光线描述",
    "mood": "氛围描述"
}
```

### 逼真度优化技巧

#### 1. 皮肤真实感
```
添加以下关键词：
- 自然的皮肤纹理和毛孔细节
- 轻微的肤色不均
- 可能有少量雀斑或小痣
- 真实的眼下轻微暗沉
```

#### 2. 光影真实感
```
避免完美均匀打光，添加：
- 自然日光照射
- 光线有柔和的明暗过渡
- 非完美均匀打光
- 保留真实的阴影
```

#### 3. 拍摄感
```
模拟手机拍摄：
- iPhone原相机拍摄质感
- 无滤镜无美颜
- 像朋友随手抓拍
- 不做作不摆拍
```

#### 4. 摄影参数
```
专业摄影感：
- 35mm焦距人像
- 自然景深
- f/2.8光圈
- 专业人像摄影
```

### 常见问题

| 问题 | 解决方案 |
|------|---------|
| 角色外貌不一致 | 使用参考图功能，每次上传相同的基准图 |
| 照片太假/太完美 | 添加真实感增强词，强调皮肤瑕疵和自然光线 |
| 场景不够真实 | 添加具体的场景细节，如"窗外是城市天际线" |
| 小痣没有体现 | 在提示词开头强调"左脸颊有一颗小痣" |
| 光线太完美 | 添加"非完美均匀打光"、"保留真实的阴影" |

---

## 专业真实人像提示词模板（2026-02-13新增）

### 核心原则

1. **使用摄影术语**：镜头、光圈、光线
2. **强调皮肤质感**：毛孔、纹理、不完美
3. **自然光线**：避免影棚感
4. **具体描述**：避免"漂亮"、"好看"等模糊词

### 真实人像提示词框架

```
【主体描述】（具体客观）
+ 【面部特征】（详细描述）
+ 【皮肤质感】（毛孔、纹理）
+ 【光线效果】（自然光）
+ 【摄影参数】（镜头、光圈）
+ 【分辨率】（8K、超高清）
```

### 头像三视图提示词模板（真人版）

#### 正面头像
```
【摄影风格】
专业人像摄影照片，自然光线，85mm人像镜头

【主体】
25岁亚洲女性，鹅蛋脸型，杏眼，自然双眼皮，深棕色瞳孔

【面部特征详细】
- 脸型：鹅蛋脸，线条柔和流畅
- 眼睛：杏眼，眼型较圆，自然双眼皮，深棕色瞳孔，睫毛自然
- 眉毛：自然眉形，略粗，深棕色
- 鼻子：直鼻，鼻梁挺直，鼻头精致小巧
- 嘴唇：标准唇，唇形饱满，自然红润
- 头发：黑色长发，盘成低发髻，露出完整面部

【皮肤质感】
真实的皮肤纹理，可见的毛孔，轻微肤色不均
眼下有轻微暗沉，T区有自然油光
不是瓷娃娃，是真实的活人皮肤
脸上完全没有痣

【光线】
柔和的自然窗光，侧面打光
有明暗过渡，非平光

【背景】
纯白色背景，简洁干净

【画质】
8K超高清，照片级真实感，无AI痕迹
```

#### 侧面头像（90度）
```
【摄影风格】
专业人像摄影照片，自然光线，85mm人像镜头

【角度要求】
标准90度正侧面，只能看到一只眼睛
可以看到后脑勺轮廓（头发盘起）

【面部特征】
鹅蛋脸侧面轮廓清晰
鼻梁挺直，鼻尖精致
只能看到一只杏眼
耳朵完整露出

【头发】
黑色长发盘成低发髻，露出后脑勺轮廓

【皮肤质感】
真实的皮肤纹理，可见的毛孔
脸上完全没有痣

【光线】
柔和的自然侧光，轮廓光

【背景】
纯白色背景

【画质】
8K超高清，照片级真实感
```

### 全身三视图提示词模板（真人版）

#### 正面全身
```
【摄影风格】
专业摄影棚照片，全身照，均匀照明

【主体】
25岁亚洲女性全身正面照，从头顶到脚底完整可见

【身材】
身高168cm，身材纤细匀称

【面部特征】（详细描述）
鹅蛋脸，杏眼，自然双眼皮，深棕色瞳孔
直鼻，鼻梁挺直
标准唇，自然红润
脸上完全没有痣
头发盘成低发髻

【服装 - 素体】
白色紧身背心（短款，露出腰部）
黑色紧身短裤（五分裤）
赤脚

【皮肤特征】
右上臂外侧有3-4个浅褐色小雀斑（直径2-3mm）
右膝盖正中央有长约1cm的浅白色横向疤痕
手肘有轻微色素沉着

【姿态】
正面站立，双手自然垂于身体两侧
双脚并拢，直视镜头
自然放松

【背景】
纯白色背景

【画质】
8K超高清，照片级真实感
```

#### 侧面全身（90度）
```
【摄影风格】
专业摄影棚照片，全身照，均匀照明

【角度要求】
标准90度正侧面，只能看到一只眼睛
可以看到后脑勺轮廓

【主体】
25岁亚洲女性全身侧面照，从头顶到脚底完整可见

【身材】
身高168cm，身材纤细匀称

【面部特征】
侧面轮廓清晰，鼻梁挺直
只能看到一只杏眼
头发盘成低发髻
脸上完全没有痣

【服装 - 素体】
白色紧身背心（短款，露出腰部）
黑色紧身短裤（五分裤）
赤脚

【皮肤特征】
右侧可见手臂雀斑
右膝盖疤痕

【姿态】
完全侧身站立，双手自然下垂
双脚并拢

【背景】
纯白色背景

【画质】
8K超高清，照片级真实感
```

### 身体瑕疵特写提示词模板

#### 手臂雀斑特写
```
【摄影风格】
医疗摄影风格，特写镜头，均匀照明

【部位】
女性右上臂外侧特写

【瑕疵详细描述】
3-4个浅褐色小雀斑
每个直径约2-3毫米
圆形或椭圆形
散落在上臂外侧中段，间距约1-2厘米

【皮肤质感】
白皙肤色，真实的皮肤纹理
可见毛孔

【背景】
纯白色背景

【画质】
高清特写，适合作为参考图
```

#### 膝盖疤痕特写
```
【摄影风格】
医疗摄影风格，特写镜头，均匀照明

【部位】
女性右膝盖正面特写

【瑕疵详细描述】
右膝盖正中央
细长的横向疤痕
长约1厘米，宽约2-3毫米
浅白色，比周围皮肤略浅

【皮肤质感】
白皙肤色，真实的皮肤纹理

【背景】
纯白色背景

【画质】
高清特写，适合作为参考图
```

---

## 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|---------|
| 2026-02-13 | 1.4.0 | 新增专业真实人像提示词模板，改进三视图提示词 |
| 2026-02-12 | 1.3.0 | 新增角色模板系统，支持一致性角色生成 |
| 2026-02-12 | 1.2.0 | 新增生成状态检测改进、高清下载功能 |
| 2026-02-11 | 1.0.0 | 初始版本 |
