# 牌账（Paizhang）

Flutter 客户端，使用 Supabase Auth、PostgreSQL、Realtime 和 Drift 本地缓存。

## 本地开发

未提供 Supabase 配置时，应用和测试仍可启动；接入真实 Supabase 时传入：

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

数据库迁移位于 `supabase/migrations/20260930120000_initial_schema.sql`。当前会话需要绑定 Supabase 项目或安装 Supabase CLI 后才能执行远程迁移。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
