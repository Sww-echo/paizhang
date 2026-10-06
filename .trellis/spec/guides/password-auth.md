# 密码认证交互边界

- 邮箱密码注册直接使用 Supabase Auth，不通过管理员密钥绕过邮箱确认。免验证码注册要求托管项目允许注册并关闭 Confirm email；本地 `config.toml` 不会自动修改托管设置。
- 登录或注册收到匹配当前提交邮箱的有效会话时，在表单销毁前完成系统自动填充保存，不等待后续资料同步。失败、取消或其他账号建立会话不得保存当前表单的密码。
- 认证请求可能已被服务端处理但客户端没有收到结果。网络中断时提示结果未确认，不宣称注册成功，也不自动重复注册。

回归入口：`test/presentation/auth_pages_test.dart`、`test/application/supabase_auth_service_test.dart`、`test/infrastructure/auth_http_client_test.dart`。本地替身不能替代托管 Auth 配置和真机密码保存验收。
