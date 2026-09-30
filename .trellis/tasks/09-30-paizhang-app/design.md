# 牌账 MVP 技术设计

## 1. 设计目标

牌账是一个面向线下牌局的多人记分与结算工具。用户登录后创建或加入房间，在同一房间内记录一场或多场牌局，最后生成易读的积分或金额结算结果。

本阶段优先保证：

- 开房和入房流程足够快。
- 二维码、分享链接、邀请码三种入口统一且安全。
- 多人能够看到同一份牌局状态。
- 分数变化可追溯、可修改、可撤销。
- 断网时不丢失本地记录。

本阶段不实现在线棋牌游戏、聊天、支付和复杂棋牌规则引擎。

## 2. 总体架构

```text
Flutter App
├── Presentation：页面、路由、表单、扫码和分享
├── Application：认证、房间、牌局、结算用例
├── Domain：Room、GameSession、Round、ScoreChange、Settlement
├── Infrastructure：HTTP、WebSocket、SQLite、深链接
└── Sync：本地变更队列、服务端同步、冲突处理

Backend API
├── Auth：验证码登录和会话
├── Rooms：房间、成员、权限
├── Invites：二维码、链接、邀请码 Token
├── Games：牌局、回合、分数变化
├── Settlements：累计输赢和转账路径
└── Realtime：房间和牌局事件推送

PostgreSQL
└── 用户、房间、邀请、成员、牌局、回合、分数变化和操作日志
```

客户端采用本地优先策略：界面先写入 SQLite，再将变更提交服务端；服务端确认后标记同步完成。首版可以要求加入房间和首次加载需要联网，但已经加载的牌局记录允许短暂离线编辑。

## 3. 核心领域模型

### User

- `id`
- `phone` 或 `email`
- `nickname`
- `avatarColor`
- `createdAt`

### Room

- `id`
- `ownerId`
- `name`
- `gameType`
- `scoringMode`
- `status`: `waiting`、`active`、`finished`、`archived`、`dissolved`
- `createdAt`
- `closedAt`

### RoomMember

- `id`
- `roomId`
- `userId`
- `role`: `owner` 或 `member`
- `inputPermission`: `all` 或 `owner_only`
- `status`: `active` 或 `left`
- `joinedAt`
- `leftAt`

### InviteToken

- `id`
- `roomId`
- `tokenHash`
- `kind`: `qr`、`link` 或 `code`
- `expiresAt`
- `revokedAt`
- `createdBy`

二维码、分享链接和邀请码都映射到邀请 Token。服务端只保存 Token 哈希，不保存可直接使用的明文 Token。

### GameSession

- `id`
- `roomId`
- `name`
- `status`: `draft`、`active`、`finished`
- `startedAt`
- `finishedAt`

### Round

- `id`
- `sessionId`
- `roundNumber`
- `note`
- `createdBy`
- `createdAt`
- `updatedAt`

### ScoreChange

- `id`
- `roundId`
- `playerId`
- `points`
- `amount`
- `createdBy`
- `createdAt`
- `updatedAt`
- `deletedAt`

积分和金额不要只保存累计结果。累计结果由回合记录计算得出，便于修改历史局和重算结算。

## 4. 入房流程

### 创建房间

1. 登录用户点击“创建房间”。
2. 输入房间名称，选择游戏类型和计分模式。
3. 服务端创建 `Room` 和房主 `RoomMember`。
4. 服务端生成一组当前有效的邀请 Token。
5. 客户端展示二维码、分享链接和邀请码。

### 扫码或链接加入

1. 用户扫描二维码或打开分享链接。
2. App 解析深链接中的短 Token。
3. 未登录用户先完成登录，登录成功后回到加入确认页。
4. 服务端校验 Token、房间状态、有效期和成员上限。
5. 用户确认后创建 `RoomMember`。

### 邀请码加入

1. 用户在 App 输入 6 位邀请码。
2. 客户端提交邀请码到服务端，不在本地推断房间信息。
3. 服务端返回脱敏的房间预览。
4. 用户确认后加入房间。

### 失效规则

- 房主刷新邀请码后，旧邀请码立即失效。
- 房主撤销邀请后，二维码和分享链接失效。
- 房间解散、归档或达到成员上限后，不能继续加入。
- 邀请 Token 使用随机值，不使用递增房间 ID。

## 5. 权限设计

房主可以：

- 修改房间设置。
- 生成、刷新和撤销邀请。
- 移除成员。
- 开始或结束牌局。
- 修改录入权限。
- 转让房主或解散房间。

普通成员可以：

- 查看成员和当前牌局。
- 录入分数，前提是房间允许成员录入。
- 修改自己创建的记录。
- 查看历史牌局。
- 退出房间。

所有涉及房间权限的操作都由服务端校验，客户端隐藏按钮不能作为安全措施。

## 6. 实时同步

房间进入 `active` 状态后，客户端订阅房间事件：

- `member.joined`
- `member.left`
- `session.started`
- `round.created`
- `round.updated`
- `round.deleted`
- `session.finished`
- `room.updated`

每条本地变更包含：

- `operationId`
- `entityId`
- `entityVersion`
- `createdAt`
- `createdBy`

服务端需要保证 `operationId` 幂等，避免网络重试造成重复记分。

首版冲突策略：

- 不允许两个人同时修改同一条历史记录时静默覆盖。
- 服务端发现版本冲突时返回最新记录和冲突提示。
- 新增不同回合可以自动合并。
- 房主可以在冲突页面选择保留哪一份。

## 7. 结算算法

### 积分模式

对所有未删除的 `ScoreChange` 按玩家聚合：

```text
playerTotal = sum(scoreChange.points)
```

### 金额模式

先检查所有玩家累计金额之和是否为零：

```text
sum(playerTotal.amount) == 0
```

不为零时显示差额和异常提示，不直接生成最终结算。

### 转账路径

1. 将正数玩家放入收款列表。
2. 将负数玩家转为应付款列表。
3. 依次匹配付款方和收款方。
4. 每次取两者绝对值的较小值。
5. 一方归零后移动到下一个玩家。

最终输出：

```text
李四 → 张三：40 元
王五 → 张三：80 元
```

## 8. 客户端页面

### 认证

- 登录页
- 验证码输入页
- 首次登录资料设置页

### 主导航

- 牌局：当前牌局、最近牌局、创建房间
- 房间：我加入的房间和最近房间
- 我的：个人资料、设置、数据导出

### 房间

- 房间首页
- 邀请成员页
- 扫码加入页
- 邀请码加入页
- 成员管理页
- 房间设置页

### 牌局

- 新建牌局页
- 当前记分页
- 录入回合页
- 历史回合页
- 编辑回合页
- 结算页
- 分享结果页

## 9. MVP 开发顺序

### Phase 1：项目骨架和认证

- Flutter 工程
- 服务端工程
- 数据库迁移
- 登录、会话和用户资料
- 基础路由与错误处理

### Phase 2：房间和邀请

- 创建房间
- 房间成员
- 邀请 Token
- 二维码生成与扫描
- 分享链接和深链接
- 邀请码加入

### Phase 3：牌局和同步

- 创建牌局
- 创建、修改、删除回合
- 记录分数变化
- WebSocket 房间事件
- SQLite 本地缓存和重试队列

### Phase 4：结算和历史

- 积分累计
- 金额平衡校验
- 最少转账路径
- 历史牌局
- 结算文字和图片分享

## 10. 验收重点

- 新用户从登录到创建房间不超过 2 分钟。
- 其他用户可以用二维码、链接和邀请码三种方式加入同一房间。
- 多台设备在正常网络下能看到相同回合和累计分数。
- 重复提交同一条记录不会造成重复计分。
- 修改历史记录后，累计分数和结算结果自动重算。
- 房间解散或邀请撤销后，旧入口无法继续加入。
- App 暂时断网时，已经打开的牌局仍可以保存本地记录。
