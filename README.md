# 牌账（Paizhang）

Flutter 客户端，使用 Supabase Auth、PostgreSQL、Realtime 和 Drift 本地缓存。

## 本地开发

未提供 Supabase 配置时，测试仍可启动，Web 会显示配置提示页，不会伪装成可操作的静态房间数据。接入真实 Supabase 时传入项目 URL 和 publishable key：

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

Web 端的 Drift 本地缓存依赖 `web/sqlite3.wasm` 和 `web/drift_worker.js`，这两个运行时文件已随项目提交。

数据库迁移按文件名顺序位于 `supabase/migrations/`。已连接的 Supabase 项目需要先执行全部迁移，再启动客户端；远程执行可使用 Supabase MCP，其他环境可使用 Supabase CLI。

## 验证

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub
```

Web 运行时必须同时提供 `SUPABASE_URL` 和 `SUPABASE_PUBLISHABLE_KEY`；publishable key 可以放在前端，禁止把 service-role key 编译进客户端。真实联调至少验证邮箱登录、创建/加入房间、点击成员头像录入转换、关闭投票、回合冲突处理和历史记录权限。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
