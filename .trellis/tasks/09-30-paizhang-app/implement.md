# 牌账 MVP 实施计划

## 当前状态

- 需求文档：已完成
- 技术设计：已完成
- Git 远程：已配置并推送
- Flutter/Dart：已安装并可运行 Flutter Web
- Supabase：项目已绑定，迁移、RLS、Realtime 和业务 RPC 已验证
- 当前任务状态：实现中，核心联调切片已完成，MVP 尚未全部完成
- 最新验证：`flutter analyze` 通过，`flutter test` 16 项通过，Web 登录和房间流程已实测
- 最新联调：2026-10-01 使用开发账号完成真实 RPC 创建、修改、软删除回合验证。

## 已实现

### 客户端与基础设施

- Flutter Android/Web 工程和分层目录已建立；当前只实测 Web，未完成 Android/iOS 真机或模拟器验收。
- `User`、`Room`、`RoomMember`、`InviteToken`、`GameSession`、`Round`、`ScoreChange`、`SettlementResult` 等领域模型已建立。
- 已接入 Supabase Flutter、Supabase Auth、PostgreSQL、Realtime 和 Drift SQLite。
- Drift Web 已配置 `web/sqlite3.wasm` 和 `web/drift_worker.js`，解决 Web 白屏问题。
- 已实现 `SUPABASE_URL`、`SUPABASE_PUBLISHABLE_KEY` 的 `--dart-define` 配置读取。

### 账号与房间

- 邮箱 OTP 登录、会话恢复、退出登录和用户资料 upsert 已接通。
- 手机 OTP 调用路径已接通，但 Supabase Phone Provider/SMS 服务尚未配置。
- 已建立两个仅开发环境可用的 Supabase 测试账号，并提供 `PAIZHANG_ENABLE_DEMO_ACCOUNTS=true` 快捷登录入口。
- 房间创建、房间列表、房间详情、邀请码生成、邀请码加入和离开房间的后端能力已接通。
- 房主创建牌局、开始牌局、结束牌局已接通。

### 记分与同步

- 积分、金额、自定义正负分领域模型和结算算法已实现。
- 回合记分、Supabase 幂等 RPC、回合修改/软删除、离线 Sync Queue、失败重试和顺序提交已实现。
- Drift 本地房间/牌局/回合缓存已实现。
- Supabase Realtime 房间刷新和 App 回到前台冲刷队列已接通。
- 重复提交不会重复计分的数据库约束、RPC 和测试已完成。

## 尚未实现或仅部分实现

- 手机号登录：需要在 Supabase `Authentication → Providers → Phone` 配置 SMS 服务商和发送凭据。
- 邮箱验证流程：当前客户端按六位 OTP 处理；Supabase 邮件模板不能只发送 Magic Link，否则会出现 `otp_expired`。
- 邀请方式：当前主要完成邀请码；二维码展示、分享链接落地页、邀请刷新和撤销的完整 UI 尚未完成。
- 成员管理：移除成员、转让房主、仅房主录入开关、普通成员退出房间的完整 UI 尚未完成。
- 记分编辑：远程 RPC 和离线队列已支持历史回合修改、软删除和恢复；编辑、删除、撤销上一局的完整 UI 流程尚未完成。
- 结算展示：领域结算算法已完成，但连接 Supabase 的牌局结算页面、累计排名、最少转账路径展示尚未完成。
- 历史与分享：个人/房间历史、复制结算文字、生成结算图片和系统分享尚未完成。
- 自动化验收：已完成单账号真实 RPC 回合增改删验证；三种入房方式、双客户端 Realtime、真实断网恢复尚未形成端到端测试。
- 发布准备：尚未生成 Android APK/AAB 和 iOS 测试包，也未完成移动端真机验收。
- 生产配置：生产 SMTP、正式域名、隐私政策和测试账号清理尚未完成。

## 当前已知风险

- 开发测试账号仅用于联调；发布构建不得开启 `PAIZHANG_ENABLE_DEMO_ACCOUNTS`。
- 当前 Web 开发服务常用端口为 `8080`，旧 Chrome 标签可能仍指向 `65037`，需要强制刷新或重新打开。
- Realtime 的 rounds/score_changes 订阅目前较宽，后续需要按房间或牌局进一步收窄事件范围。

## Phase 0：开发环境准备

- [x] 安装 Flutter stable 和 Dart SDK
- [x] 配置 Android/Web 开发目标；iOS 工程和真机目标仍待验收
- [ ] 确认 Android/iOS 本地模拟器或真机可运行（Web 已验证）
- [x] 确认 Supabase Auth、PostgreSQL、Realtime 作为线上后端方案

## Phase 1：工程骨架和领域模型

- [x] 创建 Flutter 工程
- [x] 建立 `presentation`、`application`、`domain`、`infrastructure` 分层
- [x] 定义 User、Room、RoomMember、InviteToken、GameSession、Round、ScoreChange、Settlement 模型
- [x] 配置 Navigator、Widget 状态、错误处理和 `--dart-define` 环境配置
- [x] 添加 Drift SQLite 本地存储抽象和 Web 数据库运行时

## Phase 2：账号和房间

- [x] 实现邮箱登录和会话恢复；手机号 Provider 待配置
- [~] 实现创建、查看和退出房间（远程能力已接通，完整操作 UI 待补）
- [~] 实现房主和普通成员权限（RLS/RPC 已有，成员管理 UI 待补）
- [~] 实现二维码、分享链接和邀请码加入（邀请码已接通，二维码/分享 UI 待补）
- [~] 实现邀请失效、刷新和撤销（数据库字段和校验已有，客户端操作待补）

## Phase 3：牌局和同步

- [x] 实现创建、开始和结束牌局
- [~] 实现回合录入、编辑、删除和撤销（远程 RPC、软删除和离线重放已完成，编辑/删除/撤销 UI 待补）
- [x] 实现积分和金额领域模式及金额平衡校验
- [x] 实现本地变更队列和幂等操作 ID
- [x] 接入实时房间事件和本地缓存刷新

## Phase 4：结算和历史

- [x] 实现累计积分算法
- [x] 实现金额平衡校验
- [x] 实现最少转账路径算法
- [ ] 实现个人和房间历史页面
- [ ] 实现结算文字、图片和系统分享

## Phase 5：验收和发布准备

- [x] 覆盖核心领域逻辑、认证和本地数据库测试（16 项）
- [ ] 覆盖三种入房方式的端到端测试
- [~] 验证断网暂存和恢复同步（队列逻辑及真实 RPC 回合增改删已测，真实断网端到端待测）
- [x] 验证重复提交不会重复计分
- [~] 完成错误提示和空状态（已有基础实现，隐私与生产文案待补）
- [ ] 生成 Android 和 iOS 测试包

## 首个可编码切片

Flutter 环境准备完成后，第一批只实现一个纵向切片：

1. 登录后创建房间。
2. 生成邀请码。
3. 另一用户输入邀请码加入。
4. 房主开始一场牌局。
5. 录入一局正负分。
6. 两端看到累计分数。

二维码、分享链接、金额结算和历史统计在这个切片稳定后继续接入，避免一次性铺开所有功能。

## 开源参考边界

- 参考现有项目的交互、领域建模和算法思路。
- 核心业务代码、数据模型、邀请机制和同步逻辑由本项目独立实现。
- 引入第三方依赖前记录许可证、版本和用途。
- 不复制现有项目的品牌、页面文案或大段实现代码。
