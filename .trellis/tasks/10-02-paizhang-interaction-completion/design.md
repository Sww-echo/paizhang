# 牌账核心逻辑与交互闭环设计

## 实施原则

1. 先补数据库不变量和权限，再接客户端交互；客户端提示不能替代 RLS/RPC。
2. 房间关闭使用独立投票表，票数由服务端按有效成员实时计算，避免客户端快照决定结果。
3. 历史使用专用只读 RPC，不扩大已离开成员的常规房间 RLS。旧成员只能读取离开前的记录，不可读取后续牌局。
4. 头像支持预设 key 和图片上传、替换、删除；文件只能由本人写入，不涉及离线流程。
5. 不改动已确认延期的邀请增强、离线体验、账号删除、数据导出和通知设置。

## 数据与服务端方案

### 牌局

- 增加草稿牌局的开始、取消/删除服务方法和对应 UI。
- 保留现有 `game_sessions` 状态模型；写操作严格限制房主，回合写操作严格限制 active session。
- 结束牌局使用确认弹窗，服务端拒绝非 active session 的结束或重复写入。

### 房间关闭投票

- 新增 `room_close_votes(room_id, user_id, approved, created_at, updated_at)`，主键为 `(room_id, user_id)`。
- 新增 `cast_room_close_vote` RPC：校验当前成员、房间未关闭、没有 active session；写入当前用户票后计算 `approved_count * 2 > active_member_count`，满足即将房间置为 `archived`。
- 新增 `get_room_close_votes` 或通过受 RLS 保护的查询返回当前房间投票。
- 房间关闭投票表加入 Realtime publication。
- 房间读取快照包含投票统计，关闭后仍允许历史读取。

### 历史

- 新增 `has_room_membership` 只用于历史读取策略，保留 `is_room_member` 用于当前写权限。
- 新增 `get_my_room_history` 返回曾加入房间的历史快照，离开后的记录按 `left_at` 截止过滤。
- 历史 RPC 返回昵称/头像，不返回其他用户联系方式；常规房间 RLS 仍要求有效成员。

### 头像

- profiles 增加 nullable `avatar_key`。
- User 模型增加 `avatarKey`，Auth metadata 与 profiles 同步更新。
- 客户端使用固定预设 key 映射 emoji/颜色，缺失时回退首字母。

## 客户端方案

- `ConnectedRoomPage` 根据 room status 和 session status 统一计算 `canManage`、`canRecord`、`canEdit`。
- `_SessionCard` 增加草稿操作、结束确认和只读状态。
- `_RoomManagementDialog` 增加关闭投票卡片；投票后关闭弹窗并刷新快照，Realtime 更新其他客户端。
- `ConnectedHistoryPage` 改用历史房间查询，并标记“当前房间/已离开”。
- `ConnectedProfilePage` 增加头像选择弹窗，成员头像统一复用一个展示组件。
- `SignInPage` 增加倒计时、重新发送和修改账号入口。
- 所有异步写按钮增加页面级 busy 锁，避免重复创建牌局、重复投票和重复结束牌局。

## 分阶段实施

1. Phase 0：创建任务并落盘方案。
2. Phase 1：牌局生命周期和房间状态写权限。
3. Phase 2：关闭房间投票数据库、RPC、快照和 UI。
4. Phase 3：历史查询/RLS 和离开房间状态。
5. Phase 4：头像资料和成员头像展示。
6. Phase 5：验证码重试、成员被移除/房间关闭状态、重复提交防护。
7. Phase 6：测试、格式化、静态分析和 Trellis 记录。

## 补充边界

- 牌局重命名、重新打开、草稿删除均使用服务端状态机和版本校验。
- 关闭与解散投票使用独立提案和选民快照，严格过半；成员变动或新开牌局使提案作废。
- 进行中牌局必须先结束再投票关闭；关闭不可逆，历史永久保留。
- 分数属于净变化而非钱包余额，允许负分；不增加余额不足限制。金额沿用整数单位，不引入支付。
- 已有回合不允许改变房间记分模式；备注和普通回合输入增加显式校验。
