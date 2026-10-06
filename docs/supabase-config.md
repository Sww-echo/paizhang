# Supabase 配置

本文档记录牌账项目当前使用的 Supabase 配置。客户端配置通过 Flutter 的
`--dart-define` 注入，仓库中不使用 `.env` 文件。

## 远端项目

- Project ref：`fjybuishsuvpgwxjxolt`
- API URL：`https://fjybuishsuvpgwxjxolt.supabase.co`
- 客户端使用的 publishable key：
  `sb_publishable_gcmAFG7-qUOCnNabgp-imw_SXGXryXy`

Supabase MCP 已绑定到该项目。MCP 服务地址为：

```text
https://mcp.supabase.com/mcp?project_ref=fjybuishsuvpgwxjxolt&features=docs%2Caccount%2Cdatabase%2Cdebugging%2Cdevelopment%2Cfunctions%2Cbranching
```

远端还存在一把名为 `default` 的 publishable key：
`sb_publishable_JafRru1qOQcJ70ozjS3Iig_mEJ_AcEu`。当前客户端不使用该 key，
如需轮换密钥，应统一修改启动参数或部署环境变量。

## 客户端启动参数

必须同时提供以下两个参数：

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://fjybuishsuvpgwxjxolt.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_gcmAFG7-qUOCnNabgp-imw_SXGXryXy
```

Android、Web 和其他 Flutter 构建目标都使用相同的两个参数。代码读取位置：
`lib/infrastructure/backend/supabase_bootstrap.dart`。

## Auth

当前客户端使用以下认证能力：

- 邮箱 + 密码登录
- 邮箱 + 密码直接注册
- 可选的邮箱验证码登录
- 可选的手机号验证码登录
- 用户昵称、头像信息同步到 Auth metadata 和 `public.profiles`

托管项目需要在 Supabase Dashboard → Authentication → Sign In / Providers →
Email 中确认：

- Email provider：开启
- Allow new users to sign up：开启
- Confirm email：关闭

关闭 `Confirm email` 是直接账号密码注册能够立即建立会话的前提。手机号登录
还需要开启 Phone provider，并配置短信服务商；如果没有配置，客户端会提示改用
邮箱登录。

## Storage

头像使用 Storage bucket `avatars`：

- 公开 bucket：是
- 单文件上限：`2MB`
- 允许格式：`image/jpeg`、`image/png`、`image/webp`
- 文件路径：`<user-id>/<random-uuid>.<extension>`
- 上传、修改和删除：仅允许当前用户操作自己的目录

对应迁移：
`supabase/migrations/20261002120000_interaction_completion.sql`。

## Realtime

房间同步订阅以下 `public` 表：

- `rooms`
- `room_members`
- `game_sessions`
- `rounds`
- `score_changes`
- `room_close_proposals`
- `room_close_votes`
- `profiles`

## 本地 Supabase

配置文件：`supabase/config.toml`。

| 配置项 | 当前值 |
| --- | --- |
| project_id | `paizhang-local` |
| API 端口 | `54321` |
| 数据库端口 | `54322` |
| Shadow DB 端口 | `54320` |
| PostgreSQL 主版本 | `17` |
| API schema | `public`, `graphql_public` |
| API 最大返回行数 | `1000` |
| Realtime | 开启 |
| Storage | 开启 |
| Storage 默认文件上限 | `50MiB` |
| Studio | 关闭 |
| Inbucket | 关闭 |
| Auth | 开启 |
| Auth site URL | `http://127.0.0.1:3000` |
| Auth JWT 有效期 | `3600` 秒 |
| Auth 注册 | 开启 |
| 本地邮箱确认 | 关闭 |

## 安全要求

- `publishable key` 可以出现在 Web、Android 等客户端，但权限必须由 RLS、RPC
  和 Storage policy 控制。
- 禁止把 `service_role` key、数据库密码或其他管理员凭据放进客户端、文档或 Git。
- 当前仓库没有提交 `.env` 文件；生产构建应通过 CI/CD 或本地安全环境注入参数。
- 远端 Auth Dashboard 的设置不会被本地 `supabase/config.toml` 自动修改。
- 修改远端配置或轮换 key 后，需要同步更新 Web、Android 和其他部署环境的启动参数。
