# C · 新拟态（Soft Neumorphic）设计规范

> 版本 v1.0 · 适用 `牌账` Flutter 客户端 · 全部色值经 WCAG 2.1 实测（脚本 `wcag.py`，见文末附录）
> 视觉参考：[compare-a-c.html](../prototypes/compare-a-c.html)（切到 `C · 新拟态`）
> 机器可读 token：`tokens.json`（同目录）

---

## 0. 一句话定位

**「牌桌上的硅胶记分牌」**——一整面柔和同色表面，元素靠光影浮起或压入，全屏只有数字是高对比焦点。

## 1. 设计原则（五条硬规则）

| # | 原则 | 必须 | 禁止 |
|---|---|---|---|
| P1 | **表面同色，光影分区** | `surface` 与 `bg` 明度差 ≤ 4%，分区靠阴影 | 用 1px 描边或大色差分块来表达层级 |
| P2 | **光影只表达"能不能动"** | 凸起 = 可点，凹陷 = 可填 | 装饰性阴影、纯为了好看的投影 |
| P3 | **数字优先** | 金额/分数用等宽 tabular，符号（`+ −`）+ 字重是第一编码，颜色是第二编码 | 只靠红/蓝区分正负 |
| P4 | **柔和 ≠ 低对比** | 正文与功能色 ≥ 4.5:1，标题 ≥ 7:1 | 为了"柔"把文字压到 AA 以下；阴影差值不算进对比 |
| P5 | **一层光影 = 一级层级** | 最多 4 级：page → card → float → overlay | 卡片套卡片套卡片，阴影叠加超过 2 层 |

> 与 A 暖纸的关系：**保留** A 的信息架构、文案、等宽数字体系、`+ −` 双编码；**替换** A 的分组手段（1px 描边 → 双阴影）与圆角（16 → 20）。

## 2. 色彩 token

### 2.1 亮色（基准底 `bg #E9EEEC`）

| Token | Hex | 用途 | 对 bg 实测 | 门槛 |
|---|---|---|---|---|
| `bg` | `#E9EEEC` | 页面底 | — | — |
| `surface` | `#EDF2F0` | 凸起面（卡片、按钮、chip） | — | 与 bg 明度差 1.7% |
| `sunken` | `#E2E8E5` | 凹陷面（输入框、meter 轨道） | — | 与 bg 明度差 4.4% |
| `fg` | `#1E2A26` | 主文字 | **12.66** | ≥ 4.5 |
| `muted` | `#4E5C56` | 次级文字、说明 | **5.99** | ≥ 4.5 |
| `subtle` | `#5D6A65` | 三级文字、时间戳、单位 | **4.82** | ≥ 4.5 |
| `brand` | `#387261` | 品牌、主按钮底、链接文字 | **4.78** | ≥ 4.5 |
| `brandInk` | `#26584A` | 品牌色字压在浅底上时的深版 | **6.95** | ≥ 4.5 |
| `hero` | `#2A4A41` | 结算主块底（深墨绿） | 白字 **9.75** | ≥ 4.5 |
| `heroInk` | `#EAF2EF` | hero 上主文字 | **8.56** | ≥ 4.5 |
| `heroSub` | `#A9C1B8` | hero 上副文字 | **5.11** | ≥ 4.5 |
| `win` | `#A2472F` | 正分 / 收钱 | **5.15** | ≥ 4.5 |
| `lose` | `#3A6890` | 负分 / 付钱 | **5.03** | ≥ 4.5 |
| `warn` | `#8A5A16` | 警示文字 | **5.04** | ≥ 4.5 |
| `focus` | `#26584A` | 焦点环 | **6.95** | ≥ 3.0 |
| `hair` | `#DCE3E0` | 分隔线（非文字） | 1.15 | 不承担对比 |

### 2.2 浅底深字家族（pill / chip 选中态 / 提示条）

| 底色 Token | Hex | 配字 Token | Hex | 实测 |
|---|---|---|---|---|
| `tint` | `#D6E3DD` | `tintInk` | `#1F4438` | **8.18** |
| `winTint` | `#EFDCD6` | `winInk` | `#7A2F1E` | **7.05** |
| `loseTint` | `#DCE5EC` | `loseInk` | `#223F57` | **8.59** |
| `warnTint` | `#F3E5CE` | `warnInk` | `#6B440F` | **6.88** |

> 铁律：浅底必须配对应 `*Ink`，不许直接拿 `brand`/`win` 当字色压在 `*Tint` 上（会掉到 4.2–4.3）。

### 2.3 暗色（基准底 `bg #141A18`）

| Token | Hex | 对 bg 实测 |
|---|---|---|
| `bg` | `#141A18` | — |
| `surface` | `#19201E` | — |
| `sunken` | `#0F1413` | — |
| `fg` | `#E8EDEB` | **14.90** |
| `muted` | `#8E9C97` | **6.17** |
| `subtle` | `#85938E` | **5.51** |
| `brand` | `#6FBFA5` | **8.12** |
| `onBrand` | `#0B100E` | 压 brand **8.83** |
| `hero` | `#0F1716` | 白字 **15.98** |
| `win` | `#E08A72` | **6.76** |
| `lose` | `#8AB4DA` | **8.08** |
| `warn` | `#E0B070` | **8.91** |
| `tint` / `tintInk` | `#1E2F29` / `#8FD8BE` | **8.52** |
| `winTint` / `winInk` | `#33211C` / `#E8A48F` | **7.37** |
| `loseTint` / `loseInk` | `#1B2733` / `#9CC4E4` | **8.25** |
| `focus` | `#9AD9C2` | **10.98** |

> 暗色下新拟态的物理不成立（投影在深底上"看不见"），所以：**暗色用"低对比浮雕"降级方案**——靠 `surface` 与 `bg` 的 1.15:1 色差 + 极弱外阴影 + 1px 内高光（`#FFFFFF` @ 8%）表达层级，绝不强行照搬亮色的双阴影参数。

## 3. 材质（阴影）token

命名 `PzShadow.<level>`，全部 `BoxShadow`，**offset 与 blur 比例固定 1:2.2**。

| Level | 用途 | 亮色（两层） | 暗色（两层 + 边） |
|---|---|---|---|
| `flat` | 页面底、禁用态 | 无 | 无 |
| `raise1` | chip / avatar / 返回键 / 图标钮 | `(3,3,7,#CFD8D4)` + `(-3,-3,7,#FFFFFF)` | `(2,2,5,#0A0F0D)` + `(-2,-2,5,#FFFFFF@5%)` |
| `raise2` | 卡片 / board / 列表卡 | `(6,6,14,#C9D2CD)` + `(-6,-6,14,#FFFFFF)` | `(4,4,10,#080C0B)` + `(-4,-4,10,#FFFFFF@5%)` |
| `raise3` | hero / sheet / dialog / FAB | `(10,10,26,#C2CDC7)` + `(-8,-8,20,#FFFFFF)` | `(6,6,16,#070B0A)` + `(-5,-5,14,#FFFFFF@6%)` |
| `sink1` | meter 轨道、chips 未选、segmented 轨道 | `inset (2,2,5,#C8D1CD)` + `inset (-2,-2,5,#FFFFFF)` | `inset (2,2,4,#0A0F0D)` + `inset (-1,-1,3,#FFFFFF@4%)` |
| `sink2` | 输入框 / 选择器 / 金额槽 | `inset (4,4,9,#C6D0CB)` + `inset (-4,-4,9,#FFFFFF)` | `inset (3,3,6,#080C0B)` + `inset (-2,-2,5,#FFFFFF@5%)` |
| `pressed` | 按压瞬间（凸 → 凹） | `inset (2,2,6,#C4CEC9)` + `inset (-1,-1,4,#FFFFFF)` | `inset (2,2,5,#060A09)` + `inset (-1,-1,3,#FFFFFF@4%)` |

> **记号约定**：`(dx,dy,blur,color)` = `BoxShadow(offset: Offset(dx,dy), blurRadius: blur, color: …)`。
> 行首 `inset` 只是「内阴影」的简写记号 —— Dart 的 `BoxShadow` **没有 `inset` 参数**，落地必须写
> `blurStyle: BlurStyle.inner`（即 `tokens.json` 的 `"blurStyle": "inner"`；外阴影为 `"normal"`）；
> JSON 的 `spread` 对应 Dart 的 `spreadRadius`。

**反模式**
- ❌ 同时保留 `elevation:` 与 `BoxShadow`（Material 会再叠一层，暗色下发灰）
- ❌ 阴影带色相（除品牌极淡 `#2F7D68@6%` 用于 hero 卡，其它一律中性）
- ❌ `raise3` 出现在列表项上（层级通胀，用户读不出"哪里是重点"）
- ❌ 给同一元素同时加描边 + 外阴影（这是 A 暖纸的语言，混用会两头不讨好）

## 4. 形状 / 间距 / 字体

### 4.1 圆角 `PzRadius`

| Token | 值 | 用途 |
|---|---|---|
| `chip` | `999` | chip / pill / badge / 分段滑块 |
| `xs` | `12` | 小按钮、图标钮 |
| `sm` | `16` | 控件、输入框、meter |
| `md` | `20` | 卡片、board、hero |
| `lg` | `28` | 底部 sheet 顶部圆角 |
| `xl` | `32` | dialog |

> 与现状冲突需一并修：现 `PzRadius.chip = 8` 但 `chipAll` 返回 `999`，语义打架。本规范统一 **`chip = 999`，新增 `xs = 12`**。

### 4.2 间距

`4 / 8 / 12 / 16 / 20 / 24 / 32`，页面左右安全边距 **20**，卡片内边距 **16**，卡间距 **16**，行高 **56**（最小 52），触摸目标 ≥ **44**。

### 4.3 字体

| 角色 | 字号 / 行高 | 字重 | 说明 |
|---|---|---|---|
| `heroValue` | 40 / 44 | 800 | 净收金额，等宽 |
| `display` | 40 / 46 | 700 | 金额输入槽，等宽 |
| `h1` | 26 / 33 | 800 | 页面主标题（晚上好，老王） |
| `h2` | 18 / 24 | 800 | 区块标题、角色名 |
| `body` | 15 / 22 | 500 | 正文、按钮文字（按钮用 700） |
| `bodySm` | 13.5 / 20 | 500 | 列表次行 |
| `label` | 11.5 / 16 | 700 | 字段名，字距 `+0.06em` |
| `meta` | 11.5 / 16 | 500 | 时间、单位、辅助说明 |

**数字排版**：一律 `pzMonoStyle()`（`SF Mono`/`Roboto Mono` 等宽 + `tabularFigures` + `letterSpacing: -0.2`），负号用真负号 `U+2212`。金额与单位分离：数字 800/700 字重，`元` 用 `meta` + `subtle`。
### 4.4 材质（阴影）`PzShadow`

新拟态的全部层级信息都压在阴影上，因此**阴影必须是 token，不允许组件内手写**。偏移与模糊比例固定 **1 : 2.2**，光源恒在左上。

| Token | 语义 | Light（两个 `BoxShadow`） | Dark |
|---|---|---|---|
| `flat` | 页面底、分割容器 | 无 | 无 |
| `raise1` | chip、头像、图标钮、次级按钮 | `(3,3,blur 7,#CFD8D4)` + `(-3,-3,7,#FFFFFF)` | `(3,3,7,#080C0B)` + `(-3,-3,7,#FFFFFF14)`（@8%） |
| `raise2` | 卡片、board、房间行 | `(6,6,14,#C9D2CD)` + `(-6,-6,14,#FFFFFF)` | `(6,6,14,#080C0B)` + `(-6,-6,14,#FFFFFF14)`（@8%） |
| `raise3` | hero、底部 sheet、FAB、dialog | `(10,10,26,#C2CDC7)` + `(-8,-8,20,#FFFFFF)` | `(10,10,26,#070B0A)` + `(-8,-8,20,#FFFFFF17)`（@9%） |
| `sink1` | meter 轨道、segmented 容器 | `inset(2,2,5,#C8D1CD)` + `inset(-2,-2,5,#FFFFFF)` | `inset(2,2,5,#070B0A)` + `inset(-2,-2,5,#FFFFFF0A)`（@4%） |
| `sink2` | 输入框、金额槽、选中 chip 凹槽 | `inset(4,4,9,#C6D0CB)` + `inset(-4,-4,9,#FFFFFF)` | `inset(4,4,9,#070B0A)` + `inset(-4,-4,9,#FFFFFF0A)`（@4%） |
| `pressed` | 按压瞬间 | `inset(2,2,6,#C4CEC9)` + `inset(-1,-1,4,#FFFFFF)` | `inset(2,2,6,#070B0A)` + `inset(-1,-1,4,#FFFFFF10)`（@6%） |

**暗色降级**：深底上外阴影不可见，`raise*` 保留极弱外阴影仅作边缘柔化（高光 alpha `0x14`/`0x17`），真正的凸起感靠 `surface` 与 `bg` 的 1.15:1 色差 + 1px 内高光；`sink*` 高光压到 `0x0A`，`pressed` 为 `0x10`。**禁止**把亮色双阴影参数直接搬到暗色。数值以 `docs/design/tokens.json` 为唯一权威。

**反模式（评审直接打回）**：
1. 用 `elevation:` / `Material` 默认抬升 —— 与 `PzShadow` 混用会出现两种光源；
2. 装饰性阴影（无层级含义、纯为"好看"）；
3. 带色相的阴影（除 `brand` 5% 聚焦光晕）；
4. 同屏出现 ≥5 个不同阴影等级 —— 层级超过 4 级就说明信息架构该简化了；
5. 长列表每行 `raise2`（`ListView` 100+ 行每行 2 个 `BoxShadow` 会掉帧）：列表行改用 `raise1` 或 `flat` + `hair` 分隔线。

---

## 5. 组件规格矩阵

> 所有组件**不得**出现 `Border.all` 描边（新拟态靠光影分区）；例外只有两处：`focus` 态 2px 外环，以及头像的 1px 白色高光环。

| 组件 | 尺寸 | 圆角 | 静止 | 按压 / 激活 | 文字 |
|---|---|---|---|---|---|
| **按钮 primary** | h 52，全宽 | `16` | `brand` 实底 + 白字 | `raise2` → `pressed` + scale `0.98` | 白字 700 / `body` |
| **按钮 secondary** | h 52 | `16` | `surface` + `raise1` | → `pressed` + scale `0.98` | `brandInk` 700 |
| **按钮 ghost** | h 44 | `12` | `flat` | → `sink1` | `muted` 600 |
| **chip** | h 38，最小宽 64 | `999` | `surface` + `raise1` | 选中 → `brand` 实底 + 白字 + `pressed` | 未选 `fg` 600 / 选中白 700 |
| **card / board** | 自适应，padding 16 | `20` | `surface` + `raise2` | 可点卡 → `pressed` | — |
| **list row** | min-h 56 | `20`（整行作为卡片时） | `flat` + `hair` 下分隔 | → `sink1` | 主 `h2`，次 `bodySm` `muted` |
| **segmented** | h 36，轨道 padding 3 | `999` 轨道 / `999` 滑块 | 轨道 `sink1` | 滑块 `surface` + `raise1` | 选中 `fg` 700 / 未选 `subtle` 500 |
| **输入框** | h 56 | `16` | `sunken` + `sink2` | 聚焦 → `focus` 2px 外环 + offset 2 | `fg` 500，placeholder `subtle` |
| **金额槽** | h 72，居中对齐 | `16` | `sunken` + `sink2` | 同上 | `display` 40 等宽 700 |
| **头像** | 32 / 40 | `999` | `surface` + `raise1` | — | 首字 600，`brandInk` on `tint` |
| **meter** | h 16，轨道全宽 | `999` | 轨道 `sunken` + `sink1` | 填充 `brand`，无内阴影 | — |
| **badge / pill** | h 20，padding-x 8 | `999` | `tint` 底 | — | `tintInk` 700 / `label` |
| **底部 sheet** | 最大 h 88% | 顶 `28` | `surface` + `raise3` | 拖拽把手 36×4 `border` | — |
| **dialog** | 宽 320 | `32` | `surface` + `raise3` | 遮罩 `#1E2A26`@32% | 标题 `h2` |
| **toast** | h 48 | `16` | `hero` 底 + `raise3` | 3s 自动消失 | `heroInk` 500 |
| **focus 环** | — | — | `focus` 2px，offset 2 | — | 键盘/无障碍必须可见 |
| **disabled** | — | — | `sunken` 底 + `flat`（**无阴影**） | 不响应 | `subtle` + 整控件 `opacity 0.45` |

**关键补充**：
- **按钮按压的三件事要同时发生**：阴影 `raise→pressed`、`scale 0.98`、`120ms` 回弹。只改阴影会显得"软"，只改 scale 会显得"扁"。
- **chip 选中态反向**：从"凸起"变"实色嵌入"，这是新拟态里唯一允许的高饱和色块，也是全屏最醒目的交互确认点。
- **卡片嵌套禁止**：card 内不再放 `raise2` 子卡，改用 `sunken`/`hair` 分区，否则阴影叠阴影会糊成一团。
- **金额槽永远居中且等宽**：输入时数字不要左右跳动。

---

## 6. 动效

| 场景 | 时长 | 曲线 | 行为 |
|---|---|---|---|
| 按压反馈 | 120ms | `easeOutQuad` | `scale 0.98` + 阴影反相 |
| chip / segmented 切换 | 180ms | `easeOutCubic` | 填充色 + 阴影同步过渡 |
| 卡片入场（列表首屏） | 240ms | `easeOutCubic` | `translateY 12 → 0` + `opacity 0 → 1`，逐项延迟 40ms，最多 6 项 |
| 页面切换 | 240ms | `easeInOutCubic` | 淡入 + 轻微上移 |
| 底部 sheet | 320ms | `cubic(0.2, 0, 0, 1)` | 自下而上，遮罩同步淡入 |
| 数字变化 | 220ms | `easeOutCubic` | 旧值淡出 / 新值淡入（滚动数字可选，等宽下不抖动） |
| 金额槽聚焦 | 180ms | `easeOutCubic` | focus 环展开 + 槽内亮度轻微提升 |
| 保存成功 | 240ms | `easeOutBack`（克制，`0.9 → 1`） | 按钮短暂变 `win` 色 + 勾选图标 |

**降级**：`MediaQuery.disableAnimations` 或系统"减弱动态效果"开启时，所有位移/缩放**归零**，仅保留 ≤120ms 的颜色过渡；不允许出现"完全无反馈"。

**触感**：chip 选中、保存成功 → `HapticFeedback.lightImpact()`；结算确认 → `mediumImpact()`。

---

## 7. 无障碍

1. **对比度**：正文与所有功能色 ≥ `4.5:1`（已实测，最低 `4.51:1`）；`focus` 环 ≥ `3:1`；装饰性阴影不计入对比。`subtle` 只能用于辅助信息，**不得**承载唯一语义。
2. **动态字号**：`textScaler` 放大到 `1.3x` 时所有布局不得裁切 —— 关键约束是**行高用 `min-h` 不用固定 `h`**，卡片 padding 允许被文字撑开，金额槽在 `1.3x` 时字号降一级（`40 → 32`）。
3. **命中区**：所有可点元素 ≥ `44×44`，即使视觉只有 32px 头像或 20px badge，用 `SizedBox` 撑开命中区。
4. **语义标签**：金额必须朗读完整语义，`Semantics(label: '老王 收入 128 元')`，不能只读 `+128`；正负号朗读为"收入/支出"。
5. **不只靠颜色**：赢/输同时用 **符号（`+` / `−`）+ 字重 + 颜色** 三重编码，色盲可辨。
6. **焦点顺序**：键盘/TalkBack 遍历顺序 = 视觉顺序；`FocusTraversalGroup` 显式声明。
---

## 8. 逐屏 UX 规格

> 5 屏：首页 → 房间列表 → 记分板 → 记一局 → 结算。文案与信息架构**沿用现有 App**，本规范只改视觉与交互手感，不改业务流。

### S1 · 首页

**目标**：3 秒内让用户回到"上一场还没结算的局"。

| 区 | 内容 | 材质 |
|---|---|---|
| 顶部问候 | `晚上好，老王`（`h1` 800） + `今天也把账记清楚。`（`body` `muted`） | `flat`，边距 20 |
| 主行动 | `创建房间`（primary 全宽 h52）、`加入房间`（secondary 全宽 h52） | primary `brand` 实底；secondary `surface` + `raise1` |
| 进行中的房间 | 区块标题 `进行中的房间`（`h2`） + 卡片：`周五夜局` / `4 人 · 第 7 回合` / 三个头像叠排 + 尾部位次金额 | `raise2` |
| 最近房间 | `全部房间` 入口行 → 跳 S2 | `flat` + `hair` |

**交互**：卡片整块可点（`pressed` 反馈 + `lightImpact`）；下拉刷新；主行动不做滚动吸底（此时内容不需要滚动）。

**状态**：
- *空态*：无进行中房间 → 区块替换为 `sunken` 空槽，文案「还没有开着的局，创建一个吧」，图标 `flat`。
- *加载*：卡片骨架屏用 `sink1` 占位块（不要用灰色方块，会破坏同色表皮）。
- *错误*：网络失败 → 顶部 `warn` 淡色条 + 重试，**不整页报错**（本地缓存仍可展示）。
- *边界*：房间 > 3 个 → 只显示最近 1 个 + 「还有 2 个进行中」。

### S2 · 房间列表

**目标**：快速定位某一场，并看清它是否已结算。

| 区 | 内容 | 材质 |
|---|---|---|
| 顶部 | 返回 + `全部房间`（`h1`） + 搜索/筛选图标钮 | 图标钮 `raise1` 40×40 |
| 分段 | `进行中` / `已结束` | 轨道 `sink1`，滑块 `raise1` |
| 列表 | 每行：房间名（`h2`）+ `4 人 · 第 7 回合`（`bodySm` `muted`）+ 状态 pill + 右侧净额 | 行 `flat` + `hair`；状态 pill 用 `tint` / `winTint` |

**交互**：分段切换 180ms；滑动删除（`winTint` 背景 + 二次确认 dialog）；行点击进 S3。

**状态**：空列表（`sunken` 空槽 + `创建房间` primary）；加载 → 6 行骨架；错误 → 列表区重试。

### S3 · 房间记分板（核心屏）

**目标**：一眼看出谁赢谁输、输赢多少，并进入下一步操作。**这是新拟态的优势屏**——同色卡片 + 光影让 4 个数字成为唯一焦点。

| 区 | 内容 | 材质 |
|---|---|---|
| 顶栏 | 返回 + `周五夜局`（`h2`）+ `房间管理`（ghost 文字钮） | `flat` |
| 房间摘要 | `4 人 · 第 7 回合`（`meta` `subtle`） | `flat` |
| 排名列表 | 4 行：头像 32 + 名字 + 位次 pill + 金额（右，等宽 `h1` 26 800） | 整块一块 `raise2` 卡，内部用 `hair` 分隔（**不嵌套子卡**） |
| 金额着色 | 正 → `win`；负 → `lose`；零 → `subtle` | 同时带 `+` / `−` 符号 |
| 底部操作 | `记一局`（primary，主位） + `多人转分` / `看结算`（secondary 并排） | 底部浮层 `surface` + `raise3`，安全区 padding |

**交互**：行点击 → 该玩家回合明细（`sink2` 展开区，非新页）；底部三按钮 → S4 / 转账 sheet / S5。

**状态**：刚建房间（0 回合）→ 金额全 `0 元` + 空槽提示「记下第一局」；加载 → 4 行骨架；离线 → 顶部 `warn` 条「离线，改动将在恢复后同步」，**仍可记分**（本地优先）。

**边界**：人数 > 6 → 列表滚动，底部操作固定；金额 ≥ 5 位 → 字号自动降一级（26 → 22），不换行、不省略。

### S4 · 记一局（第 8 回合）

**目标**：30 秒内记完一局，且**不可能记错**（转账必须平衡）。

| 区 | 内容 | 材质 |
|---|---|---|
| 标题 | `记一局 · 第 8 回合`（`h1`） | `flat` |
| 方向 | `谁给谁`（`label`）+ 付款人选择器 → 箭头 → 收款人选择器 | 选择器 `sunken` + `sink2`，内部头像 + 名字 |
| 金额 | 大号居中金额槽（`display` 40 等宽） | `sunken` + `sink2` |
| 快捷 | chips `20 40 60 100 200 平摊` | `raise1`，选中 `brand` 实底 + `pressed` |
| 合计 | `本回合合计转出` + 金额 + 右侧 `已平衡` pill（`tint` / 未平衡 `warnTint`） | `raise2` |
| 主按钮 | `保存这一局` | primary，**未平衡时 disabled**（`sunken` + `flat` + `opacity .45`） |

**交互**：点 chips 直接填入金额（180ms 数字过渡）；`平摊` 按人数均分并处理余数（尾差给最后一人，界面标注）；付款人 = 收款人时立即 `warn` 内联提示，不弹窗。

**状态**：金额为空 → 按钮 disabled + 槽内 `subtle` 提示「输入金额」；保存中 → 按钮内联 loading（不遮全屏）；保存失败 → 按钮回弹 + toast「保存失败，已保留草稿」；离开页面有未保存内容 → dialog「放弃这一局？」。

### S5 · 结算与转账

**目标**：给出一句结论（我赚多少）+ 可直接执行的转账清单。

| 区 | 内容 | 材质 |
|---|---|---|
| 结论 | `结算`（`h1`） + `我的净收`（`label`）+ 大号金额（`heroValue` 40 等宽，`win`/`lose` 着色） | hero 卡 `hero` 底 + `raise3`；金额 `heroInk` |
| 有效性 | `7 回合有效 · 已确认结果`（`meta`） + 勾选图标 | `flat` |
| 转账路径 | `建议转账路径`（`h2`）+ 每行 `小李 → 老王 86 元` | `raise2` 卡，行 `hair` |
| 累计排名 | 4 人最终净额 | `raise2` 卡 |
| 底部 | `分享结算图`（primary）+ `完成`（secondary） | 浮层 `raise3` |

**交互**：转账行左右滑动标记"已转"（`sink1` + 勾选，本地状态）；分享 → 生成图片（截图区域不留阴影外的空白，导出时 `bg` 铺满）。

**状态**：无转账（全平）→ 空槽「这局打平，无需转账」；未结算 → 顶部说明「还有 1 回合未确认」+ 主按钮变 `完成结算`；导出失败 → toast。

---

## 9. 落地映射（`lib/presentation/design.dart`）

> 现有文件是单一 token 中心，改造应**只扩不改语义**：`PzColors` 字段名保留，值替换；新增 `PzShadow` / `PzDepth`；`PzRadius` 微调。

| 位置 | 行号（现状） | 动作 |
|---|---|---|
| `PzColors.light` | `:59` | 按 §2 亮色表整体替换（`fg/muted/subtle/brand/brandInk/hero/heroInk/heroSub/tint/tintInk/win/winTint/winInk/lose/loseTint/loseInk/warn/warnTint/warnInk/bg/surface/sunken/hair/border/focus`） |
| `PzColors.dark` | `:85` | 按 §2 暗色表整体替换 |
| `PzRadius` | `:126` | `chip 8 → 999`（与 `chipAll` 一致）、`xs 新增 12`、`sm 12 → 16`、`md 16 → 20`、`lg 新增 28`、`xl 32` |
| 新增 `PzShadow` | — | 7 组 `List<BoxShadow>`：`flat/raise1/raise2/raise3/sink1/sink2/pressed`，按主题取值 |
| 新增 `PzDepth` | — | `enum { flat, raise1, raise2, raise3, sink1, sink2, pressed }` + `extension on PzDepth { List<BoxShadow> shadows(PzColors c) }` |
| `pzMonoStyle` | `:146` | 保持；确认 `fontFeatures: [tabularFigures]` + `letterSpacing: -0.2` |
| `PzButton` | `:202` | 加 `PzDepth` 参数（默认 `raise2`）；`InkWell` → `GestureDetector` + `AnimatedScale(0.98)` + `AnimatedContainer` 切阴影；`splashColor` 置透明 |
| `PzBoard` | `:370`（`BoxDecoration` 在 `:407`） | 挂 `raise2`；移除 `Border.all`；`padding 16`、`radius 20` |
| `PzTheme._build` | `:1160` | `useMaterial3: true`、`splashFactory: NoSplash.splashFactory`、全局 `elevation: 0`、`cardTheme.elevation = 0`、`textTheme` 按 §4.3 |

**组件改造顺序**（每步可独立编译、可截图验收）：

1. **token 层**：`PzColors` 替换 + `PzShadow` + `PzRadius` 调整 → 跑 `flutter analyze`（此时界面已变色但无阴影，属于"现代扁平"过渡态，可发布）
2. **`PzBoard` / 卡片**：挂 `raise2`、去描边 → 全局观感一次成型
3. **`PzButton`**：按压三件套（阴影 + scale + 时长）
4. **chips / segmented**：选中反相
5. **输入框 / 金额槽**：`sunken` + `sink2` + focus 环
6. **meter / badge / avatar**：小件收口
7. **sheet / dialog / toast**：`raise3` + 遮罩
8. **暗色**：换表 + 加内高光，逐屏比对

**迁移风险与对策**：

| 风险 | 对策 |
|---|---|
| 全仓 `BoxShadow` 现为 **0**，引入后长列表掉帧 | 列表行禁用 `raise2`；`RepaintBoundary` 包卡片；`const` 阴影列表缓存到静态字段，不在 `build` 里新建 |
| 现 `elevation:` 8 处与 `PzShadow` 混用 → 双光源 | 全量清零 `elevation:`，改用 `PzDepth` |
| `Border.all` 全仓 5 处（`design.dart` `:407 / :562 / :597 / :938`，`common_widgets.dart` `:309`） | 前 4 处删除，靠光影分区，分隔线改用 `hair` 1px `Container`；`:597` 的 `conflict` 描边改为 `warnTint` 底 + `warnInk` 字（不描边也能表达冲突）；`:309` 是头像白环，**保留**并注释"高光环"，改 1px `#FFFFFF` |
| 暗色阴影不可见 → 界面"糊平" | 按 §4.4 暗色降级：色差 + 内高光，**不照搬**亮色参数 |
| `PzRadius.chip = 8` 与 `chipAll = 999` 语义冲突 | 统一 `chip = 999`，新增 `xs = 12` 承接原 8 的用途 |
| 对比度回退（有人手改色值） | 把 §10 的对比度脚本纳入 CI |

---

## 10. 验收清单

**必须全绿才可合并**：

- [ ] `flutter analyze` 零 error / 零 warning
- [ ] `flutter test` 全通过
- [ ] `grep -rc "elevation:" lib/ | awk -F: '{s+=$2} END {print s}'` → `0`
- [ ] `grep -rn "Border.all" lib/ --include=*.dart | wc -l` → `1`（仅剩 `common_widgets.dart:309` 头像高光环，其余 4 处清零；focus 环一律用 `BoxDecoration.border` 实现）
- [ ] `grep -rc "BoxShadow" lib/presentation/design.dart` → `≥ 7`（阴影集中在 token 层）
- [ ] 除 `design.dart` 外，业务文件**零**硬编码 `Color(0x` / `BoxShadow(`
- [ ] §2 全部颜色对 `bg` / `surface` / `sunken` 三底实测 ≥ `4.5:1`（最低 `4.51`）
- [ ] 5 屏 × 亮/暗 = 10 张截图，与 `docs/prototypes/c-soft-neumorphic/` 视觉一致
- [ ] `textScaler = 1.3` 下 5 屏无裁切、无 `overflow` 报错
- [ ] 开启"减弱动态效果"后无位移动画，仍有颜色反馈
- [ ] TalkBack 遍历金额时朗读「收入 128 元」而非「+128」
- [ ] 按压反馈在真机（60Hz 低端机）无掉帧：`flutter run --profile` 下 `frame_build_time` < 8ms
