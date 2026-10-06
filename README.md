# 牌账（Paizhang）

Flutter 客户端，使用 Supabase Auth、PostgreSQL、Realtime 和 Drift 本地缓存。

Supabase 配置清单见 [`docs/supabase-config.md`](docs/supabase-config.md)。

## 本地开发

使用 `.flutter-version` 中固定的 Flutter 版本（当前为 3.47.5），避免本机与 CI 的格式化和代码生成结果不同。

```bash
flutter pub get --enforce-lockfile
dart run build_runner build --delete-conflicting-outputs
```

未提供 Supabase 配置时，Web 显示配置提示页，不会伪装成可操作的静态房间数据。接入后端时传入项目 URL 和 publishable key：

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

这两个参数必须同时提供。publishable key 可以放在前端，禁止把 service-role key 编译进客户端。Web 端的 Drift 本地缓存依赖 `web/sqlite3.wasm` 和 `web/drift_worker.js`，这两个运行时文件已随项目提交。

## 邮箱密码注册与登录

登录页默认使用邮箱 + 密码，点击“没有账号？注册”填写邮箱、昵称、密码和确认密码。注册与密码登录都不调用验证码接口；密码至少 6 位，昵称最多 40 个字符。原邮箱/手机验证码入口仍保留为可选方式，需要单独配置邮件/短信服务。

**免验证码注册需要 Supabase 服务端允许直接建立会话：**

- 本地 `supabase/config.toml` 已显式设置 `[auth.email] enable_signup = true` 和 `enable_confirmations = false`。
- 托管项目还需在 Supabase Dashboard → Authentication → Sign In / Providers → Email 中开启邮箱注册并关闭 **Confirm email**；本地配置文件不会修改托管项目。
- 未返回登录 session 时，客户端会提示检查邮箱确认配置，不会宣称已登录或伪造验证状态。重复账号请直接登录，不要反复注册。
- 关闭确认后，邮箱只是用户填写的登录标识，不能当作已验证的真实联系方式。当前没有接入邮件找回密码，请妥善保存密码。
- 严禁通过客户端携带 service-role/admin key 来绕过服务端确认设置；真实项目配置调整需由项目管理员确认。

调试包连接真实后端时同样必须提供上面的两个 `--dart-define`，例如：

```bash
flutter build apk --debug \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
# 指定 adb devices 中的设备，覆盖安装但保留应用数据：
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk
```

## 本地验证与 CI

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub --coverage
python3 -m unittest discover -s tool -p '*_test.py'
flutter build web --no-pub
git diff --check
```

`.github/workflows/ci.yml` 分别执行 Flutter 检查（含 Drift 生成产物一致性）、隔离数据库测试和 Android 未签名验证构建。本地通过不等于 GitHub CI 已运行，也不代表双设备或正式发布验收通过。

## 数据库迁移与隔离测试

迁移按文件名顺序位于 `supabase/migrations/`，不要修改已部署的迁移或在生产库执行测试数据脚本。安装 Docker 和 Supabase CLI（CI 固定为 2.39.2）后，在本项目目录执行：

```bash
supabase start
supabase db reset --local
supabase test db
supabase stop --no-backup
```

`db reset --local` 会清空本项目的本地开发库；仅对可丢弃的测试环境使用。pgTAP 测试位于 `supabase/tests/`，在事务中构造测试账号并回滚，覆盖版本冲突、原始 ACK 幂等重放、账号/权限边界及离开成员的历史访问。它不替代真实 Auth、Realtime 和双客户端联调。

部署前应在独立测试项目按顺序验证全部迁移，再协调客户端升级。`20261004011902_reliability_optimization.sql` 启用带 actorId/baseVersion 的 `upsert_round_with_scores_v2`，旧的无版本写接口会返回 `client_upgrade_required`，因此新旧客户端混用必须安排升级窗口。本仓库的本地验证命令不会自动部署远端迁移；远端操作需要另行确认。

## 离线恢复与冲突

- 待同步操作和缓存按账号隔离。退出不会删除未同步输入，原账号重新登录后可恢复；不会借新账号重放旧账号的数据。
- 旧数据库中无法确定归属的队列保留在隔离区，不自动分配给当前账号或发送。清理本地应用数据会丢失未同步输入，不能将其作为默认修复手段。
- 网络失败进入退避重试；业务拒绝和版本冲突保留输入并显示原因。一个依赖链失败不应阻塞无关房间。
- 冲突时先刷新、核对远端最新值，再显式确认重新提交或放弃本地变化；不能直接把旧输入当成服务器的最新数据。
- 缓存不是授权来源。离线权限只能标为未确认，重连后的服务端校验仍是最终边界。写入返回房间/牌局权限拒绝后会重新鉴权；对账暂时失败则暂停缓存访问，不删除草稿。回合不存在或只有创建者能编辑等单条操作错误不会一律撤销整个房间的访问。

## Android 验证构建与正式发布

需要 JDK 17 和 Android SDK。仅验证编译及合并 Manifest 时：

```bash
PAIZHANG_VERIFY_RELEASE=true flutter build apk --release --no-pub
python3 tool/check_android_manifest.py --expected-application-id com.example.paizhang.verification
```

该 APK 使用 `com.example.paizhang.verification`，**未签名、未配置后端，不可作为正式发布包**。Manifest 脚本检查生成的 release 合并结果，不以源码或 debug Manifest 代替。没有生成产物时脚本必须失败。

正式发布前复制 `android/key.properties.example` 为被 Git 忽略的 `android/key.properties`，填写实际包名和自己的签名配置；也可提供以下环境变量：

- `PAIZHANG_APPLICATION_ID`
- `PAIZHANG_KEYSTORE_PATH`
- `PAIZHANG_KEYSTORE_PASSWORD`
- `PAIZHANG_KEY_ALIAS`
- `PAIZHANG_KEY_PASSWORD`

正式构建时不设置 `PAIZHANG_VERIFY_RELEASE`，并传入后端的两个 `--dart-define`。缺少正式包名或有效签名配置时构建会失败，不会回退到 debug 签名。密钥、密码和本地配置禁止入库。还需核对签名证书、最终包名、release 联网/登录、冷启动邀请深链；HTTPS App Links 需要拥有对应域名并正确配置 `assetlinks.json`，仅有 Manifest 声明并不等于已验证。

## 未替代的人工验收

优化任务与逐项验证记录见 `.trellis/tasks/10-03-paizhang-reliability-optimization/`。至少还需在独立测试环境执行：

1. 同账号双客户端修改同一回合，后提交的旧版本提示冲突；重放相同 operationId 不重复计账。
2. A 离线录入并重启，切换 B 不可见也不提交 A 的待同步数据，切回 A 后恢复。
3. 断网期间远端修改/移除权限，恢复网络或 Realtime 重连后完成对账，拒绝项保留原因。
4. 邮箱登录、邀请失败后重试、点击头像转换、关闭投票，以及离开成员的历史权限。
5. 大历史数据量下真实网络请求数、端到端耗时和本地 SQL 写入量；本地合成数据测试不能代替真机性能结论。
6. 正式签名 release 包在真机上的登录、网络、深链和重启恢复。
