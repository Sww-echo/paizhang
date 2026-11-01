# 交给下游 Agent 的提示词 · 牌账 App 新拟态（C）

**怎么用**：把下面「提示词正文」整段复制粘贴给要执行实现的 agent（Claude Code / Codex / Cursor 均可）。它自包含：含全部 token 数值、代码骨架、改造顺序与验收命令，不需要它自己推算任何颜色。

**配套文件**（提示词里已指明，agent 需自行阅读）：

- `docs/design/c-neumorphic-spec.md` — 完整设计规范（原则 / 组件矩阵 / 逐屏 UX / 落地映射）
- `docs/design/tokens.json` — **唯一权威数值源**
- `docs/prototypes/c-soft-neumorphic/01-home.png` … `05-settlement.png` — 视觉基准图

---

## 【以下是提示词正文，从下一行开始整段复制】

你是一名 Flutter UI 工程师。任务是给 `/Users/leeee/project/paizhang`（牌局记分 App「牌账」）落地一套**新拟态（Soft Neumorphic）**主题，替换现有扁平主题。这是纯视觉与交互手感改造，**不改任何业务逻辑**。

### 0. 先读，再动手

按顺序读，读完再写第一行代码：

1. `docs/design/c-neumorphic-spec.md` —— 设计规范，全部约束在上面的 §1–§10。
2. `docs/design/tokens.json` —— 颜色 / 阴影 / 圆角 / 间距 / 字阶 / 动效的**唯一权威数值**。规范文档里的数字若与它冲突，以 JSON 为准。
3. `lib/presentation/design.dart` —— 现有 token 中心，你的改造主要落在这个文件。
4. `docs/prototypes/c-soft-neumorphic/` 下的 5 张 PNG —— 视觉目标。

### 1. 硬约束（违反任何一条即视为失败）

1. **不改业务逻辑**：不改数据模型、不改 Supabase 调用、不改路由语义、不改文案。
2. **不加依赖**：`pubspec.yaml` 一行都不改。不许引入 `flutter_neumorphic` 或任何第三方阴影/主题包 —— 自己写。
3. **公开 API 不破坏**：`PzColors` 字段名、`PzButton` / `PzBoard` / `PzRadius` 等现有构造函数参数保持兼容，只允许**新增可选参数**。
4. **双主题都必须成立**：亮色 + 暗色都要能看，暗色**不许**照搬亮色的双阴影参数（见 §4.4 暗色降级）。
5. **对比度红线**：`docs/design/tokens.json` 的 `contrastContract` 里每一对都必须 ≥ `4.5:1`。已实测通过（亮色最低 4.51，暗色最低 5.18），**你不许手改任何色值**；如需改动，必须重新计算并说明。
6. **阴影只能在 token 层定义**：业务文件里禁止出现 `BoxShadow(` 字面量。
7. **禁用 `elevation:` / `Material` 默认抬升**：会和 `PzShadow` 形成双光源。
8. **禁用 glassmorphism / 模糊 / 渐变装饰**：新拟态是纯色 + 光影，`BackdropFilter` 一律不用。
9. **禁用描边分区**：删掉所有 `Border.all`，分区靠 `sunken` + 阴影；唯一例外是 focus 环。
10. **不破坏既有测试**：`flutter test` 必须全绿。

### 2. 数值（照抄，不要重新设计）

**亮色**：`bg #E9EEEC` / `surface #EDF2F0` / `sunken #E2E8E5` / `hair #DCE3E0` / `border #D5DEDA` / `fg #1E2A26` / `muted #4E5C56` / `subtle #5D6A65` / `brand #387261` / `brandInk #26584A` / `onBrand #FFFFFF` / `hero #2A4A41` / `heroInk #EAF2EF` / `heroSub #A9C1B8` / `tint #D6E3DD` / `tintInk #1F4438` / `win #A2472F` / `winTint #EFDCD6` / `winInk #7A2F1E` / `lose #3A6890` / `loseTint #DCE5EC` / `loseInk #223F57` / `warn #8A5A16` / `warnTint #F3E5CE` / `warnInk #6B440F` / `focus #26584A` / `scrim #1E2A2652`

**暗色**：`bg #141A18` / `surface #19201E` / `sunken #0F1413` / `hair #242C2A` / `border #2C3532` / `fg #E8EDEB` / `muted #8E9C97` / `subtle #85938E` / `brand #6FBFA5` / `brandInk #8FD8BE` / `onBrand #0B100E` / `hero #0F1716` / `heroInk #E8EDEB` / `heroSub #8E9C97` / `tint #1E2F29` / `tintInk #8FD8BE` / `win #E08A72` / `winTint #33211C` / `winInk #E8A48F` / `lose #8AB4DA` / `loseTint #1B2733` / `loseInk #9CC4E4` / `warn #E0B070` / `warnTint #33280F` / `warnInk #E8C38C` / `focus #9AD9C2` / `scrim #0000007A`

**圆角**：`chip 999` / `xs 12` / `sm 16` / `md 20` / `lg 28` / `xl 32`。
**间距**：4 / 8 / 12 / 16 / 20 / 24 / 32；页边 20，卡内 16，卡间距 16，行高 min 56，命中区 ≥ 44。

### 3. 第一步：在 `design.dart` 加阴影 token

光源恒在左上。偏移 : 模糊 = 1 : 2.2。亮色直接用 `PzColors` 里的 `bg`/`surface` 关系推导，**按下面字面量写死即可**：

```dart
/// 新拟态阴影层级。唯一允许出现 BoxShadow 的地方。
abstract final class PzShadow {
  static const List<BoxShadow> flat = <BoxShadow>[];

  static const List<BoxShadow> raise1 = <BoxShadow>[
    BoxShadow(offset: Offset(3, 3), blurRadius: 7, color: Color(0xFFCFD8D4)),
    BoxShadow(offset: Offset(-3, -3), blurRadius: 7, color: Color(0xFFFFFFFF)),
  ];
  static const List<BoxShadow> raise2 = <BoxShadow>[
    BoxShadow(offset: Offset(6, 6), blurRadius: 14, color: Color(0xFFC9D2CD)),
    BoxShadow(offset: Offset(-6, -6), blurRadius: 14, color: Color(0xFFFFFFFF)),
  ];
  static const List<BoxShadow> raise3 = <BoxShadow>[
    BoxShadow(offset: Offset(10, 10), blurRadius: 26, color: Color(0xFFC2CDC7)),
    BoxShadow(offset: Offset(-8, -8), blurRadius: 20, color: Color(0xFFFFFFFF)),
  ];
  static const List<BoxShadow> sink1 = <BoxShadow>[
    BoxShadow(offset: Offset(2, 2), blurRadius: 5, color: Color(0xFFC8D1CD), blurStyle: BlurStyle.inner),
    BoxShadow(offset: Offset(-2, -2), blurRadius: 5, color: Color(0xFFFFFFFF), blurStyle: BlurStyle.inner),
  ];
  static const List<BoxShadow> sink2 = <BoxShadow>[
    BoxShadow(offset: Offset(4, 4), blurRadius: 9, color: Color(0xFFC6D0CB), blurStyle: BlurStyle.inner),
    BoxShadow(offset: Offset(-4, -4), blurRadius: 9, color: Color(0xFFFFFFFF), blurStyle: BlurStyle.inner),
  ];
  static const List<BoxShadow> pressed = <BoxShadow>[
    BoxShadow(offset: Offset(2, 2), blurRadius: 6, color: Color(0xFFC4CEC9), blurStyle: BlurStyle.inner),
    BoxShadow(offset: Offset(-1, -1), blurRadius: 4, color: Color(0xFFFFFFFF), blurStyle: BlurStyle.inner),
  ];

  // BoxShadow 没有 `inset` 参数：内阴影一律 blurStyle: BlurStyle.inner。
  // 暗色：偏移/模糊/blurStyle 与亮色完全一致，仅换这两个颜色。
  // raise1 & raise2 暗影 0xFF080C0B、高光 0x14FFFFFF
  // raise3          暗影 0xFF070B0A、高光 0x17FFFFFF
  // sink1 & sink2   暗影 0xFF070B0A、高光 0x0AFFFFFF
  // pressed         暗影 0xFF070B0A、高光 0x10FFFFFF
  static List<BoxShadow> of(PzDepth d, Brightness b) { /* 见下 */ }
}

enum PzDepth { flat, raise1, raise2, raise3, sink1, sink2, pressed }
```

`of()` 用 `switch` 返回亮/暗两套 list；把两组 `const` 都定义成字段，**不要在 `build()` 里新建 list**（长列表会掉帧）。

### 4. 改造顺序（每步单独 commit，每步都要能编译 + 截图）

| 步 | 动作 | 验收 |
|---|---|---|
| 1 | `PzColors.light` / `PzColors.dark` 按上面两行色值整体替换 | `flutter analyze` 干净；截图已换色调 |
| 2 | 新增 `PzShadow` + `PzDepth` + `of()` | 同上 |
| 3 | `PzRadius`：`chip→999`、新增 `xs=12`、`sm→16`、`md→20`、新增 `lg=28` | 圆角肉眼可见变大 |
| 4 | `PzBoard` 挂 `raise2`、删 `Border.all`、padding 16、radius 20 | 卡片浮起 |
| 5 | `PzButton` 按压三件套：阴影 `raise2→pressed` + `AnimatedScale(0.98)` + `120ms` | 按下有"陷进去"感 |
| 6 | chips / segmented 选中反相（选中 `brand` 实底 + `pressed` 阴影） | 选中态醒目 |
| 7 | 输入框 / 金额槽：`sunken` 底 + `sink2` + 聚焦 `focus` 2px 外环 offset 2 | 输入区"凹下" |
| 8 | 暗色逐屏比对（`hero` 卡、toast、sheet 遮罩） | 暗色不糊平 |

**优先级**：如果只能做一部分，做完 1–4 就已经是完整可发布的新拟态观感，5–8 是手感补完。

### 5. 按压态实现骨架（步 5）

```dart
// 不要用 InkWell（水波纹在无描边同色表皮上很脏）
GestureDetector(
  onTapDown: (_) => setState(() => _down = true),
  onTapUp: (_) => setState(() => _down = false),
  onTapCancel: () => setState(() => _down = false),
  onTap: widget.onPressed,
  child: AnimatedScale(
    scale: _down ? 0.98 : 1.0,
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOutQuad,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutQuad,
      decoration: BoxDecoration(
        color: widget.primary ? c.brand : c.surface,
        borderRadius: BorderRadius.circular(PzRadius.sm),
        boxShadow: _down ? PzDepth.pressed.shadows(b) : PzDepth.raise2.shadows(b),
      ),
      child: ...,
    ),
  ),
)
```

`PzTheme._build` 里加 `splashFactory: NoSplash.splashFactory`、`elevation: 0`、`cardTheme: CardThemeData(elevation: 0)`。

### 6. 自检命令（必须逐条跑，把输出贴进报告）

```bash
cd /Users/leeee/project/paizhang
flutter analyze
flutter test
# 必须为 0：残留的 Material 抬升
grep -rc "elevation:" lib/ | awk -F: '{s+=$2} END {print "elevation:", s+0}'
# 必须为 0：描边分区
grep -rc "Border.all" lib/ | awk -F: '{s+=$2} END {print "border.all:", s+0}'
# 必须 >= 7：阴影集中在 token 层
grep -c "BoxShadow" lib/presentation/design.dart
# 必须为 0：业务文件里的裸阴影
grep -rn "BoxShadow(" lib/ --include=*.dart | grep -v "design.dart" | wc -l
# 必须为 0：业务文件里的裸色值
grep -rn "Color(0x" lib/ --include=*.dart | grep -v "design.dart" | wc -l
```

### 7. 报告格式

按步汇报，每步给：改动文件 + 行数、`flutter analyze` 结论、一张截图路径。最后给一张表：

| 验收项 | 命令/方法 | 结果 |
|---|---|---|
| analyze | `flutter analyze` | |
| 测试 | `flutter test` | |
| elevation 清零 | grep | |
| 描边清零 | grep | |
| 阴影集中度 | grep | |
| 亮色 5 屏 | 截图 | |
| 暗色 5 屏 | 截图 | |
| 1.3x 字号不裁切 | 真机/模拟器 | |

**不许**在没跑命令的情况下声称通过。如果某条验收没过，如实写"未通过 + 原因"，不要改验收标准。

## 【提示词正文结束】

---

### 使用提示

- 这套提示词刻意把**数值全部内联**，下游 agent 即使不读规范文档也能落地；但读 `spec.md` 的 §5 组件矩阵能让它少走弯路，建议一开始就让它读。
- 若下游 agent 只做视觉不做代码，把「§2 数值 + §3 阴影骨架 + §5 按压骨架」三段单独发过去即可，其余可省略。
- 想让它顺带产出原型图，追加一句：「改完后用 `flutter test --update-goldens` 或截图脚本输出 5 屏亮/暗共 10 张 PNG 到 `docs/prototypes/c-soft-neumorphic-v2/`」。
