# 即梦图片生成 4.0 API 完整集成方案

> 研究日期: 2026-02-13
> 研究员: jimeng-api-researcher
> 文档版本: 1.0

---

## 一、API 基本信息

### 1.1 端点 URL

| 环境 | API 端点 |
|------|---------|
| **火山方舟官方** | `https://ark.cn-beijing.volces.com/api/v3/images/generations` |
| **第三方代理** | `https://api.laozhang.ai/v1/images/generations` |

### 1.2 请求方法

- **Method**: `POST`
- **Content-Type**: `application/json`

### 1.3 认证方式

```http
Authorization: Bearer $ARK_API_KEY
```

**获取 API Key**:
1. 注册火山方舟账号: https://console.volcengine.com/ark
2. 创建推理接入点
3. 获取 API Key 并配置环境变量

```bash
export ARK_API_KEY="your-api-key-here"
```

### 1.4 API 格式

- **兼容性**: OpenAI Image API 兼容格式
- **可用模型**:
  - `doubao-seedream-4-0-250828` (Seedream 4.0)
  - `doubao-seedream-4-5-250xxx` (Seedream 4.5)

---

## 二、请求参数

### 2.1 必填参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `model` | string | 模型名称，如 `doubao-seedream-4-0-250828` |
| `prompt` | string | 图片描述文本（**必须单行，不能有换行符**） |

### 2.2 可选参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `size` | string | `2048x2048` | 图片尺寸 |
| `n` / `num_images` | integer | 1 | 生成图片数量 |
| `response_format` | string | `url` | 响应格式：`url` 或 `b64_json` |
| `watermark` | boolean | false | 是否添加水印 |
| `image` | array/string | - | 参考图片URL（图生图模式） |
| `sequential_image_generation` | string | `disabled` | 顺序生成模式 |
| `stream` | boolean | false | 是否启用流式响应 |
| `seed` | integer | - | 随机种子（可复现结果） |

### 2.3 尺寸参数 (size) 选项

#### 方式1: 分辨率规格

| 宽高比 | 像素尺寸 | 说明 |
|--------|----------|------|
| 1:1 | `1024x1024` | 最小尺寸 |
| 1:1 | `2048x2048` | 默认（推荐） |
| 1:1 | `4096x4096` | 最大尺寸 |
| 16:9 | `2560x1440` | 横版/桌面壁纸 |
| 9:16 | `1440x2560` | 竖版/手机壁纸 |
| 4:3 | `2304x1728` | 横版 |
| 3:4 | `1728x2304` | 竖版 |
| 3:2 | `2496x1664` | 横版 |
| 2:3 | `1664x2496` | 竖版 |
| 21:9 | `3024x1296` | 超宽横版 |

#### 方式2: 规格代号

- `2K` - 2048像素（推荐）
- `4K` - 更高分辨率

**像素范围**: 1024-4096

### 2.4 输出格式 (response_format) 选项

| 格式 | 说明 |
|------|------|
| `url` | 返回图片URL（推荐，24小时有效） |
| `b64_json` | 返回Base64编码的图片数据 |

---

## 三、响应格式

### 3.1 成功响应

```json
{
  "created": 1726051200,
  "data": [
    {
      "url": "https://example.com/generated_image.jpg",
      "revised_prompt": "..."
    }
  ],
  "usage": {
    "generated_images": 1
  }
}
```

**字段说明**:

| 字段 | 类型 | 说明 |
|------|------|------|
| `created` | integer | 创建时间戳（Unix时间） |
| `data` | array | 图片数据数组 |
| `data[].url` | string | 图片URL（24小时有效） |
| `data[].revised_prompt` | string | 优化后的提示词（可选） |
| `usage.generated_images` | integer | 生成的图片数量 |

### 3.2 错误响应

```json
{
  "error": {
    "message": "错误描述信息",
    "type": "invalid_request_error",
    "code": "invalid_api_key"
  }
}
```

### 3.3 流式响应 (Seedream 4.0/4.5 支持)

当 `stream: true` 时，服务器会持续返回数据：

```
data: {"created": 1726051200, "data": [...]}
data: [DONE]
```

---

## 四、调用示例

### 4.1 Python - 文生图

```python
import requests
import os

def generate_image(prompt, output_dir="."):
    """生成图片并保存到本地"""
    API_KEY = os.environ.get("ARK_API_KEY")
    API_URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }

    payload = {
        "model": "doubao-seedream-4-0-250828",
        "prompt": prompt,  # 必须单行！
        "response_format": "url",
        "size": "2048x2048",
        "watermark": False
    }

    response = requests.post(API_URL, headers=headers, json=payload, timeout=60)
    result = response.json()

    # 获取图片URL
    image_url = result["data"][0]["url"]

    # 下载图片
    img_response = requests.get(image_url, timeout=30)
    with open("output.jpg", "wb") as f:
        f.write(img_response.content)

    return "output.jpg"
```

### 4.2 Python - 图生图（多参考图融合）

```python
def generate_with_reference(prompt, reference_images, output_dir="."):
    """基于参考图生成新图片"""
    API_KEY = os.environ.get("ARK_API_KEY")
    API_URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}"
    }

    # reference_images 可以是单张URL或URL数组（最多10张）
    payload = {
        "model": "doubao-seedream-4-0-250828",
        "prompt": prompt,
        "image": reference_images,  # 支持多张参考图
        "sequential_image_generation": "disabled",
        "response_format": "url",
        "size": "2K",
        "stream": False,
        "watermark": False
    }

    response = requests.post(API_URL, headers=headers, json=payload, timeout=60)
    result = response.json()

    return result["data"][0]["url"]
```

### 4.3 Curl 示例

```bash
# 文生图
curl -X POST https://ark.cn-beijing.volces.com/api/v3/images/generations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ARK_API_KEY" \
  -d '{
    "model": "doubao-seedream-4-0-250828",
    "prompt": "一位25岁的亚洲女性，鹅蛋脸型，杏眼双眼皮，深棕色瞳孔，头发盘成低发髻，白色短款紧身运动背心，黑色五分紧身裤",
    "response_format": "url",
    "size": "2048x2048",
    "watermark": false
  }'
```

---

## 五、与现有技能的兼容性分析

### 5.1 现有技能架构

**文件**: `/home/xixil/.claude/skills/jimeng-image-generator/SKILL.md`

**当前实现方式**: 浏览器自动化 (Selenium/Playwright)

**核心功能**:
- 连接 Chrome CDP 端口 9222
- 自动化操作 jimeng.jianying.com 网站
- Cookie 持久化
- 多参考图上传
- 自动下载生成的图片

### 5.2 API 方式 vs 浏览器自动化对比

| 维度 | 浏览器自动化 | API 方式 |
|------|-------------|---------|
| **稳定性** | 依赖网页结构，易失效 | API 稳定，有官方支持 |
| **速度** | 较慢（需加载网页） | 快速（直接HTTP请求） |
| **成本** | 免费（使用网页版） | 按次计费（$0.035-$0.045/张） |
| **多参考图** | 支持（网页上传） | 支持（image数组参数） |
| **流式响应** | 不支持 | 支持（4.0/4.5） |
| **登录要求** | 需要 Cookie | 仅需 API Key |
| **维护成本** | 高（网页变化需更新） | 低（API稳定） |
| **批量生成** | 困难 | 容易（程序化调用） |

### 5.3 兼容性建议

**推荐方案**: **API 方式作为主要方法，浏览器自动化作为备用/降级方案**

```python
class JimengImageGenerator:
    def __init__(self, use_api=True):
        self.use_api = use_api
        self.api_key = os.environ.get("ARK_API_KEY")

    def generate(self, prompt, reference_images=None):
        if self.use_api and self.api_key:
            try:
                return self._generate_via_api(prompt, reference_images)
            except Exception as e:
                print(f"API 调用失败: {e}")
                print("降级到浏览器自动化方式...")
                return self._generate_via_browser(prompt, reference_images)
        else:
            return self._generate_via_browser(prompt, reference_images)
```

### 5.4 现有代码适配要点

1. **提示词格式**: 保持单行格式（API 和网页版都要求）
2. **参考图**: API 使用 URL 数组，需先将本地图片上传到图床
3. **图片保存**: API 返回 URL，需额外下载步骤
4. **错误处理**: 添加 API 错误码处理

---

## 六、集成实现建议

### 6.1 新增 API 模块

建议在现有 skill 中新增 `jimeng_api_generator.py`:

```
/home/xixil/.claude/skills/jimeng-image-generator/
├── SKILL.md                      # 技能文档
├── jimeng_creative.py            # 浏览器自动化方式
├── jimeng_api_generator.py       # 新增: API 方式
└── jimeng_unified.py             # 新增: 统一接口
```

### 6.2 配置文件

```json
// ~/.claude/skills/jimeng-image-generator/config.json
{
  "api": {
    "enabled": true,
    "base_url": "https://ark.cn-beijing.volces.com/api/v3",
    "model": "doubao-seedream-4-0-250828",
    "default_size": "2048x2048",
    "timeout": 60
  },
  "browser": {
    "enabled": true,
    "cdp_port": 9222,
    "fallback": true
  },
  "output": {
    "directory": "/home/xixil/图片/"
  }
}
```

### 6.3 统一接口设计

```python
# jimeng_unified.py
def generate_image(
    prompt: str,
    reference_images: list = None,
    size: str = "2048x2048",
    watermark: bool = False,
    method: str = "auto"  # "api", "browser", "auto"
) -> str:
    """
    统一图片生成接口

    参数:
        prompt: 图片描述（必须单行）
        reference_images: 参考图URL列表（最多10张）
        size: 图片尺寸
        watermark: 是否添加水印
        method: 生成方式

    返回:
        生成图片的本地路径
    """
    pass
```

---

## 七、价格参考

| 模型 | 价格/张 | 说明 |
|------|---------|------|
| Seedream 4.0 | $0.035 | 约 ¥0.25 |
| Seedream 4.5 | $0.045 | 约 ¥0.32 |

**第三方代理可能有折扣**（如老张API约65%折扣）

---

## 八、参考资料

- [Seedream 4.5 API 参考官方文档](https://www.volcengine.com/docs/82379/1541523)
- [Seedream 4.0-4.5 提示词指南](https://www.volcengine.com/docs/82379/1829186)
- [Seedream 4.5 SDK 示例教程](https://www.volcengine.com/docs/82379/1824121)
- [火山方舟流式响应文档](https://www.volcengine.com/docs/82379/1824137)
- [ImageGenerations API文档](https://api.volcengine.com/api-docs/view?action=ImageGenerations&version=2024-01-01&serviceCode=ark)
- [老张API - SeeDream文档](https://docs.laozhang.ai/api-capabilities/seedream-image)
- [CSDN - Seedream 4.0 API封装实践](https://blog.csdn.net/weixin_45870110/article/details/154148363)

---

## 九、总结

1. **API 方式优势明显**: 更稳定、更快速、更易维护
2. **兼容现有技能**: 可以作为主要方式，浏览器自动化作为降级方案
3. **成本可控**: 每张图约 ¥0.25-0.32
4. **功能完整**: 支持多参考图、流式响应等高级功能
5. **建议行动**:
   - 申请火山方舟 API Key
   - 新增 API 模块到现有 skill
   - 实现统一接口，支持自动降级

---

*报告完成于 2026-02-13*
