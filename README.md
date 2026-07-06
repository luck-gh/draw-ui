# draw-ui - AI UI 设计 Skill

一个通用的 AI UI 设计 skill,用于根据自然语言生成 UI 设计稿,并辅助把生成的 UI 截图还原成 HTML/CSS。优先使用运行环境内置的图像生成能力；需要本地脚本化输出时,可通过 ZenMux API 调用 **GPT Image 2**

---

## 能做什么

- 根据自然语言描述生成高质量 UI 设计稿
- 通过参考图锁定多页面之间的导航栏,侧边栏等框架一致性
- 使用经过验证的提示词写法,如类比式或清单式,提高设计质量
- 自动处理 GPT Image 2 `edit_image` API 的常见细节,包括串行执行和重试
- 指导 HTML 还原流程,包括素材策略,浏览器截图对比,以及 logo 和插画的去背景规则

## 使用要求

- 一个支持 skills 协议的 AI Agent,例如 Claude Code,Cursor 等
- 如果使用脚本生成图片,需要配置 **ZenMux API key**:可设置为 `ZENMUX_API_KEY` 环境变量,或写入 `.env.local`,也可以放在 `~/.config/see/api_key`
- 可选的自定义中转端点:将 `DRAW_BASE_URL` 设置为任意兼容 Google GenAI 图片接口的 base URL；默认值为 `https://zenmux.ai/api/vertex-ai`
- Python 3,首次运行时会自动安装 `google-genai`

## 安装

```bash
npx skills add luck-gh/draw-ui
```

也可以手动克隆:

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/luck-gh/draw-ui ~/.claude/skills/draw-ui
```

## 使用方式

可以用类似下面的话触发:

> 帮我设计一个 Dashboard 页面  
> Design a user profile screen  
> 出图,产品详情页

Agent 通常会先问几个简短问题,例如页面要解决什么问题,是否有参考截图,是否需要保持多页面一致,然后再开始生成

### 通过命令行手动使用

```bash
# 不使用参考图
scripts/ask_draw.sh --type wide --name "dashboard" --prompt "..."

# Windows PowerShell
scripts/ask_draw.ps1 -Type wide -Name "dashboard" -Prompt "..."

# 使用参考图,锁定侧边栏/导航栏一致性
scripts/ask_draw.sh \
  --frame /path/to/sidebar-reference.png \
  --type wide \
  --name "dashboard" \
  --prompt "..."

# Windows PowerShell
scripts/ask_draw.ps1 `
  -Frame /path/to/sidebar-reference.png `
  -Type wide `
  -Name "dashboard" `
  -Prompt "..."
```

### 画面比例选项

| Bash `--type` / PowerShell `-Type` | 比例 | 适用场景 |
|----------|-------|----------|
| `wide` | 16:9 | 桌面应用界面,默认选项 |
| `classic` | 4:3 | Dashboard,数据密集型布局 |
| `square` | 1:1 | 卡片,弹窗 |
| `portrait` | 3:4 | 移动端页面 |

## 核心概念

**参考图策略**

参考图会限制 AI 复制什么。如果截图的主体内容区已经有较完整的内容,AI 往往会模仿该布局,这会降低重新设计内容区的自由度

最佳做法是使用"干净框架":截图中只保留侧边栏,导航栏等页面框架,内容区尽量留空。这样 AI 可以保持外层 chrome 一致,同时自由设计主体内容

**提示词写法**

不要把提示词写成像素,列数,间距这类布局规格。更好的方式是描述页面背后的业务目标,并采用下面两种方式之一:

- **类比式**:例如"像是在阅读一首热门歌曲背后的乐谱。感觉像 Notion 的安静克制,加上音乐制作人的批注。"这种写法更适合追求创意质量
- **清单式**:例如"页面展示:用户名,30 天趋势图,带状态徽标的活跃活动列表。"这种写法最适合保证信息准确

尽量使用真实示例数据,而不是占位描述。比如 `"2.3M views"` 会比 `"show view count"` 更容易生成真实可信的界面

**HTML 还原**

把生成的设计稿或截图还原成 HTML/CSS 时,要把工作拆成代码和素材两部分:

- 用 HTML/CSS/SVG 构建布局,卡片,按钮,文字,筛选器和普通线性图标
- 对品牌 logo,空状态插画,玻璃质感/3D 视觉,复杂渐变等难以纯代码实现的细节,单独生成图片素材；截图裁切只作为 image-to-image 重绘参考,不应直接作为最终素材,除非原图已经足够高清且背景干净
- 不要把大插画,logo 和小图标混在同一张 sprite sheet 里；大插画素材应单独生成
- 对供应商 logo 行,深色 wordmark,小型深色图标,建议先生成大尺寸纯白背景源图,再保守去除白底；这样可以避免绿色毛边,并保护细笔画
- 对彩色插画和产品视觉,优先使用绿幕或真实透明输出；白底抠图可能会破坏白色卡片和高光
- 如果确实需要图标 sprite sheet,要保证机器可裁切:纯白背景,精确 4x4 网格,无边框,无文字标签,无阴影,无重叠,每个图标都居中并留出足够边距

这样可以让 HTML 保持清爽,同时保留图像生成最擅长的视觉细节

## 许可证

MIT
