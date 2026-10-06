import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paizhang/application/supabase_auth_service.dart';
import 'package:paizhang/domain/models.dart' show PaizhangException;
import 'package:paizhang/infrastructure/backend/supabase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/fakes.dart';

class _MemoryAuthStorage extends GotrueAsyncStorage {
  final values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

class _Profiles extends FakeRoomRepository {
  final nicknames = <String>[];

  @override
  Future<void> ensureCurrentUserProfile({
    required String nickname,
    String? avatarKey,
    String? avatarUrl,
    bool clearAvatar = false,
    bool replaceAvatar = false,
  }) async {
    nicknames.add(nickname);
  }
}

Map<String, Object?> _user() => {
  'id': ownerId,
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': 'player@example.com',
  'created_at': '2026-10-05T00:00:00Z',
  'app_metadata': {'provider': 'email'},
  'user_metadata': {'nickname': '玩家'},
};

Map<String, Object?> _session() {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
  return {
    'access_token':
        '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({'sub': ownerId, 'exp': expiresAt, 'role': 'authenticated'})}.dGVzdA',
    'refresh_token': 'test-refresh-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': _user(),
  };
}

void main() {
  late SupabaseClient client;
  late SupabaseAuthService service;
  late _Profiles profiles;
  late List<http.Request> requests;
  late Object response;
  var status = 200;
  var networkFailure = false;

  setUp(() {
    requests = [];
    profiles = _Profiles();
    response = _session();
    status = 200;
    networkFailure = false;
    client = SupabaseClient(
      'https://auth-test.invalid',
      'test-publishable-key',
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: _MemoryAuthStorage(),
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (networkFailure) throw http.ClientException('offline');
        return http.Response(
          jsonEncode(response),
          status,
          headers: {
            'content-type': 'application/json',
            'x-supabase-api-version': '2024-01-01',
          },
          request: request,
        );
      }),
    );
    service = SupabaseAuthService(
      authRepository: SupabaseAuthRepository(client),
      roomRepository: profiles,
    );
  });
  tearDown(() => client.dispose());

  test('正式注册调用 signup，规范邮箱昵称但保留原密码，不请求验证码', () async {
    final user = await service.registerWithPassword(
      email: ' Player@Example.com ',
      password: ' Password123 ',
      nickname: ' 玩家 ',
    );
    expect(user.id, ownerId);
    expect(user.nickname, '玩家');
    expect(client.auth.currentSession, isNotNull);
    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/auth/v1/signup');
    final body = jsonDecode(requests.single.body) as Map;
    expect(body['email'], 'player@example.com');
    expect(body['password'], ' Password123 ');
    expect(body['data'], {'nickname': '玩家'});
    expect(profiles.nicknames, ['玩家']);
  });

  test('仅返回用户但无 session 时不冒充免验证注册成功', () async {
    response = _user();
    await expectLater(
      service.registerWithPassword(
        email: 'player@example.com',
        password: 'Password123',
        nickname: '玩家',
      ),
      throwsA(
        isA<PaizhangException>().having(
          (e) => e.message,
          'message',
          contains('注册未建立登录会话'),
        ),
      ),
    );
    expect(profiles.nicknames, isEmpty);
    expect(client.auth.currentSession, isNull);
    expect(service.currentUser, isNull);
  });

  test('确认开启时的混淆重复账号响应不会被宣称为新账号成功', () async {
    response = {..._user(), 'identities': []};
    await expectLater(
      service.registerWithPassword(
        email: 'player@example.com',
        password: 'Password123',
        nickname: '玩家',
      ),
      throwsA(
        isA<PaizhangException>().having(
          (e) => e.message,
          'message',
          isNot(contains('注册成功')),
        ),
      ),
    );
    expect(profiles.nicknames, isEmpty);
    expect(client.auth.currentSession, isNull);
  });

  for (final value in [
    (email: '', password: 'Password123', nickname: '玩家'),
    (email: 'not-email', password: 'Password123', nickname: '玩家'),
    (email: 'a@example.com', password: '12345', nickname: '玩家'),
    (email: 'a@example.com', password: 'Password123', nickname: ' '),
    (email: 'a@example.com', password: 'Password123', nickname: '名' * 41),
  ]) {
    test(
      '注册拒绝无效输入 ${value.email}/${value.nickname.length}/${value.password.length}',
      () async {
        await expectLater(
          service.registerWithPassword(
            email: value.email,
            password: value.password,
            nickname: value.nickname,
          ),
          throwsA(isA<PaizhangException>()),
        );
        expect(requests, isEmpty);
      },
    );
  }

  for (final error in {
    'email_exists': '该账号已注册',
    'user_already_exists': '该账号已注册',
    'signup_disabled': '未开放账号注册',
    'weak_password': '密码强度不足',
  }.entries) {
    test('注册将 ${error.key} 映射为可操作提示', () async {
      status = 422;
      response = {'msg': 'auth error', 'code': error.key};
      await expectLater(
        service.registerWithPassword(
          email: 'player@example.com',
          password: 'Password123',
          nickname: '玩家',
        ),
        throwsA(
          isA<PaizhangException>().having(
            (e) => e.message,
            'message',
            contains(error.value),
          ),
        ),
      );
      expect(profiles.nicknames, isEmpty);
      expect(client.auth.currentSession, isNull);
    });
  }

  test('注册网络失败保留未登录状态，可再次提交成功', () async {
    networkFailure = true;
    await expectLater(
      service.registerWithPassword(
        email: 'player@example.com',
        password: 'Password123',
        nickname: '玩家',
      ),
      throwsA(
        isA<PaizhangException>().having(
          (e) => e.message,
          'message',
          contains('注册结果未确认'),
        ),
      ),
    );
    expect(client.auth.currentSession, isNull);
    expect(profiles.nicknames, isEmpty);
    networkFailure = false;
    final user = await service.registerWithPassword(
      email: 'player@example.com',
      password: 'Password123',
      nickname: '玩家',
    );
    expect(user.id, ownerId);
    expect(profiles.nicknames, ['玩家']);
  });

  test('密码登录直接请求 password grant 并建立会话，不调用 OTP', () async {
    await service.signInWithPassword(
      email: ' Player@Example.com ',
      password: ' Password123 ',
    );
    expect(requests, hasLength(1));
    expect(requests.single.url.path, '/auth/v1/token');
    expect(requests.single.url.queryParameters['grant_type'], 'password');
    final body = jsonDecode(requests.single.body) as Map;
    expect(body['email'], 'player@example.com');
    expect(body['password'], ' Password123 ');
    expect(client.auth.currentSession, isNotNull);
    expect(profiles.nicknames, ['玩家']);
  });

  test('密码登录错误不会建立会话或写入资料', () async {
    status = 400;
    response = {'msg': 'invalid login', 'code': 'invalid_credentials'};
    await expectLater(
      service.signInWithPassword(
        email: 'player@example.com',
        password: 'wrong',
      ),
      throwsA(
        isA<PaizhangException>().having(
          (e) => e.message,
          'message',
          contains('账号或密码不正确'),
        ),
      ),
    );
    expect(client.auth.currentSession, isNull);
    expect(profiles.nicknames, isEmpty);
  });
}
