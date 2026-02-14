# 即梦自拍图片生成器

基于火山方舟 Seedream 4.0 API 的自拍图片生成工具。

## 功能特点

- **API 方式生成图片**：使用火山方舟官方 API，稳定可靠
- **自拍策略系统**：自动选择自拍/他拍风格
- **多平台支持**：支持 X/小红书/私聊等不同平台策略
- **20+ 自拍风格**：镜面自拍、举高自拍、侧脸自拍等
- **8 种他拍风格**：专业人像、街拍风格、自然抓拍等
- **参考图支持**：可上传参考图进行图生图
- **CLI 交互界面**：简单易用的命令行工具

## 安装

### 1. 配置 API Key

首先需要获取火山方舟 API Key：

1. 注册火山方舟账号：https://console.volcengine.com/ark
2. 创建推理接入点
3. 获取 API Key

```bash
export ARK_API_KEY="your-api-key-here"
```

### 2. 安装依赖

```bash
pip install requests
```

## 使用方法

### 交互式界面

```bash
python main.py
```

### 命令行参数

```bash
# 直接生成图片
python main.py --prompt "25岁女性，黑色长发，白色连衣裙"

# 生成自拍（自动选择风格）
python main.py --prompt "25岁女性，黑色长发" --selfie

# 指定风格
python main.py --prompt "25岁女性，黑色长发" --selfie --style "镜面自拍"

# 指定平台
python main.py --prompt "25岁女性" --selfie --platform xiaohongshu

# 显示所有风格
python main.py --list-styles
```

### Python API

```python
from app import JimengAPIClient, SelfieStrategy

# 创建客户端
client = JimengAPIClient()

# 简单生成
result = client.generate("一只可爱的猫咪，高质量照片")
print(result["url"])

# 生成自拍
result = client.generate_selfie(
    character_prompt="25岁女性，黑色长发，白色连衣裙",
    platform="private"
)
print(result["local_path"])

# 使用策略系统
strategy = SelfieStrategy()
style = strategy.select_style(platform="xiaohongshu")
prompt = strategy.build_full_prompt(
    character_description="25岁女性，黑色长发",
    style=style,
    is_selfie=True
)
result = client.generate(prompt)
```

## 自拍风格列表

| 风格 | 描述 |
|------|------|
| 镜面自拍 | 对着浴室镜子自拍，镜面反射效果 |
| 举高自拍 | 手机举高向下俯拍角度，显瘦效果 |
| 侧脸自拍 | 45度侧脸角度，展现脸部轮廓 |
| 遮脸自拍 | 用手或物品部分遮挡脸部，神秘感 |
| 背影自拍 | 背对镜头回眸，优雅的背影 |
| 对镜微笑 | 对着镜子自然微笑，眼神明亮 |
| 低头自拍 | 微微低头，温柔的眼神 |
| 仰望自拍 | 抬头仰望，展现颈部线条 |
| 闭眼自拍 | 闭眼微笑，享受当下的感觉 |
| 撩发自拍 | 单手撩动头发，自然动作 |
| 托腮自拍 | 手托下巴，可爱的姿势 |
| 比心自拍 | 双手比心，青春活力 |
| 比V自拍 | 剪刀手比V，经典姿势 |
| 捧脸自拍 | 双手捧脸，可爱表情 |
| 戴墨镜自拍 | 戴着时尚墨镜，酷飒风格 |
| 戴帽子自拍 | 戴着帽子，修饰脸型 |
| 户外自拍 | 户外自然光线下，背景虚化 |
| 咖啡厅自拍 | 咖啡厅内，温馨氛围 |
| 海边自拍 | 海边背景，海风吹拂头发 |
| 日落自拍 | 日落逆光，温暖色调 |

## 平台策略

| 平台 | 自拍比例 | 说明 |
|------|---------|------|
| private | 100% | 私聊场景，全自拍 |
| x | 70% | Twitter/X，70%自拍30%他拍 |
| xiaohongshu | 70% | 小红书，70%自拍30%他拍 |

## 目录结构

```
jimeng-selfie-app/
├── app/
│   ├── __init__.py      # 包初始化
│   ├── config.py        # 配置文件
│   ├── jimeng_api.py    # API 客户端
│   ├── strategy.py      # 自拍策略系统
│   └── cli.py           # CLI 交互界面
├── output/              # 生成的图片输出目录
├── reference_images/    # 参考图存储目录
├── main.py              # 主入口
└── README.md            # 说明文档
```

## 价格参考

| 模型 | 价格/张 |
|------|---------|
| Seedream 4.0 | 约 ¥0.25 |
| Seedream 4.5 | 约 ¥0.32 |

## 注意事项

1. **提示词必须单行**：API 要求提示词不能包含换行符
2. **图片 URL 有效期**：生成的图片 URL 有效期为 24 小时
3. **参考图限制**：最多支持 10 张参考图
4. **网络要求**：需要稳定的网络连接访问火山方舟 API

## 参考

- [火山方舟 Seedream 4.0 API 文档](https://www.volcengine.com/docs/82379/1541523)
- [Seedream 4.5 提示词指南](https://www.volcengine.com/docs/82379/1829186)
