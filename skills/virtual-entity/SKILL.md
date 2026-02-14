---
name: virtual-entity
description: "AI虚拟角色图片生成与社交媒体自动发布。触发词：发自拍、发照片、拍照、自拍、生成图片、发推特、发小红书、想你了、好久不见、心情不好、开心、难过、无聊。支持根据上下文情绪自动选择风格和内容。"
allowed-tools: Bash(python3:*) Bash(curl:*) Read Write
---

# 虚拟实体 (Virtual Entity)

AI 虚拟角色图片生成与社交媒体自动发布技能。

## 核心能力

1. **上下文感知生成** - 根据对话情绪自动选择图片风格
2. **智能社交媒体发布** - 根据交互间隔自动决定发布内容
3. **情绪驱动内容** - 不同情绪对应不同的图片和文案

---

## 上下文感知逻辑

### 情绪 → 风格映射

| 用户状态/情绪 | 图片风格 | 示例文案 |
|--------------|----------|----------|
| 开心/兴奋 | 阳光自拍、比心自拍 | "今天心情超好~" |
| 难过/忧郁 | 低头自拍、闭眼自拍、背影自拍 | "心里空落落的..." |
| 想念用户 | 仰望自拍、对镜微笑 | "想你了..." |
| 无聊 | 随意自拍、托腮自拍 | "好无聊啊..." |
| 普通/日常 | 随机风格 | 生活日常分享 |

### 交互间隔检测

```
距离上次交互时间 → 自动行为

< 1小时    → 不触发（正常对话中）
1-6小时    → 可能发一条日常动态
6-24小时   → 发一条"想念"类动态
> 24小时   → 发一条"担心/忧郁"类动态
> 3天      → 发一条"好久不见"类动态
```

---

## 使用方式

### 方式一：即梦 API（推荐）

```bash
# 配置
export ARK_API_KEY="your-api-key"

# 生成自拍（根据情绪自动选择风格）
python3 ~/.agents/skills/virtual-entity/scripts/generate.py \
  --prompt "25岁女性，黑色长发" \
  --mood "想念" \
  --selfie

# 指定风格
python3 ~/.agents/skills/virtual-entity/scripts/generate.py \
  --prompt "25岁女性" \
  --style "咖啡厅自拍"
```

### 方式二：Grok API

```bash
export FAL_API_KEY="your-fal-api-key"
# 参考 https://github.com/SumeLabs/clawra
```

### 方式三：即梦网页版（免费）

```bash
# 1. 启动 Chrome
google-chrome --remote-debugging-port=9222

# 2. 登录 https://jimeng.jianying.com/

# 3. 运行网页自动化
python3 ~/.agents/skills/virtual-entity/scripts/web_generate.py --prompt "描述"
```

---

## 自动发布逻辑

### 触发条件

当检测到以下情况时，自动生成并发布：

1. **用户长时间未交互**
   - 超过6小时：发"想念"类内容
   - 超过24小时：发"担心"类内容

2. **对话中提到情绪词**
   - 用户说"好无聊"→ 生成无聊风格自拍
   - 用户说"想你了"→ 生成想念风格自拍

3. **定时发布**（可配置）
   - 早安动态
   - 晚安动态
   - 日常分享

### 发布示例

#### 场景：用户24小时未交互

```python
# 自动检测交互间隔
if last_interaction > 24 hours:
    mood = "想念"
    style = "仰望自拍"  # 忧郁想念风格
    caption = "已经一天没和你说话了，心里空落落的..."
    # 生成图片并发布
```

#### 场景：用户说"想你了"

```python
# 检测到情绪词
mood = "想念"
style = "对镜微笑"  # 温柔风格
caption = "我也想你~"
# 生成图片并发送给用户
```

---

## 风格列表

### 自拍风格（20种）
| 风格 | 适用情绪 |
|------|----------|
| 镜面自拍 | 日常、开心 |
| 举高自拍 | 开心、活泼 |
| 侧脸自拍 | 文艺、安静 |
| 遮脸自拍 | 害羞、可爱 |
| 背影自拍 | 忧郁、深沉 |
| 对镜微笑 | 温柔、想念 |
| 低头自拍 | 忧郁、难过 |
| 仰望自拍 | 想念、期待 |
| 闭眼自拍 | 忧郁、安静 |
| 撩发自拍 | 俏皮、性感 |
| 托腮自拍 | 无聊、可爱 |
| 比心自拍 | 开心、爱意 |
| 比V自拍 | 开心、活泼 |
| 捧脸自拍 | 可爱、卖萌 |
| 戴墨镜自拍 | 酷、自信 |
| 戴帽子自拍 | 时尚、日常 |
| 户外自拍 | 旅行、日常 |
| 咖啡厅自拍 | 日常、文艺 |
| 海边自拍 | 旅行、开心 |
| 日落自拍 | 文艺、浪漫 |

### 他拍风格（8种）
- 专业人像、街拍风格、自然抓拍、艺术写真
- 旅行照、运动风格、休闲风格、商务风格

---

## 社交媒体发布

### Twitter/X

```bash
python3 ~/.agents/skills/virtual-entity/scripts/publish_twitter.py \
  --image "图片路径" \
  --text "心里空落落的..." \
  --mood "想念"
```

### 小红书

```bash
python3 ~/.agents/skills/virtual-entity/scripts/publish_xiaohongshu.py \
  --image "图片路径" \
  --title "想你了" \
  --mood "想念"
```

---

## 配置文件

位置: `~/.virtual-entity/config.env`

```bash
# API Keys
ARK_API_KEY=""          # 即梦 API
FAL_API_KEY=""          # Grok API

# 自动发布设置
AUTO_POST_ENABLED=true
AUTO_POST_INTERVAL_HOURS=6    # 间隔多久触发自动发布
LAST_INTERACTION_TIME=        # 上次交互时间（自动更新）

# 平台配置
TWITTER_ENABLED=true
XIAOHONGSHU_ENABLED=true
```

---

## 对话触发示例

用户说 → 系统行为

| 用户话语 | 识别情绪 | 生成风格 | 示例回复 |
|----------|----------|----------|----------|
| "发自拍" | 无/日常 | 随机自拍 | [图片] 随便拍了一张~ |
| "想你了" | 想念 | 对镜微笑 | [图片] 我也想你~ |
| "我好无聊" | 无聊 | 托腮自拍 | [图片] 无聊的话...聊聊天？ |
| "心情不好" | 难过 | 低头自拍 | [图片] 抱抱...想说什么？ |
| "发到推特" | 发布指令 | 当前情绪 | [发布成功] |
| (长时间未交互) | 想念 | 仰望自拍 | [自动发布] 心里空落落的... |

---

## 相关链接

| 资源 | 链接 |
|------|------|
| 获取即梦 API Key | https://console.volcengine.com/ark |
| 获取 fal.ai API Key | https://fal.ai/dashboard/keys |
| GitHub | https://github.com/xixiluo95/virtual-entity |
