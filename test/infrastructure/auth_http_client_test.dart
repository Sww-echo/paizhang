import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:paizhang/infrastructure/backend/auth_http_client.dart';

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  handler;
  http.BaseRequest? lastRequest;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    lastRequest = request;
    return handler(request);
  }

  @override
  void close() {
    closed = true;
    super.close();
  }
}

http.StreamedResponse _ok(String body, {int status = 200}) =>
    http.StreamedResponse(Stream.value(body.codeUnits), status);

void main() {
  test('认证请求超时后释放调用方并中止底层请求', () async {
    final hanging = Completer<http.StreamedResponse>();
    final inner = _FakeClient((_) => hanging.future);
    final client = AuthHttpClient(
      inner,
      timeout: const Duration(milliseconds: 30),
    );
    final request = http.Request(
      'POST',
      Uri.parse('https://example.supabase.co/auth/v1/token'),
    );

    await expectLater(
      client.send(request),
      throwsA(
        isA<http.ClientException>().having(
          (e) => e.message,
          'message',
          contains('超时'),
        ),
      ),
    );
    expect(inner.lastRequest, isA<http.AbortableRequest>());
    expect((inner.lastRequest! as http.Request).body, request.body);
    // A late response must not surface to the caller.
    hanging.complete(_ok('late'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });

  test('非认证请求原样透传且不设置超时', () async {
    final inner = _FakeClient((_) async => _ok('pong'));
    final client = AuthHttpClient(
      inner,
      timeout: const Duration(milliseconds: 30),
    );
    final request = http.Request(
      'GET',
      Uri.parse('https://example.supabase.co/rest/v1/rooms'),
    );

    final response = await client.send(request);
    expect(await response.stream.bytesToString(), 'pong');
    expect(identical(inner.lastRequest, request), isTrue);
    expect(inner.lastRequest, isNot(isA<http.AbortableRequest>()));
  });

  test('认证请求响应体长时间无数据也会超时', () async {
    final controller = StreamController<List<int>>();
    addTearDown(controller.close);
    final inner = _FakeClient(
      (_) async => http.StreamedResponse(controller.stream, 200),
    );
    final client = AuthHttpClient(
      inner,
      timeout: const Duration(milliseconds: 30),
    );

    final response = await client.send(
      http.Request(
        'GET',
        Uri.parse('https://example.supabase.co/auth/v1/user'),
      ),
    );
    await expectLater(
      response.stream.bytesToString(),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('认证请求正常返回时保留状态码、响应头与内容', () async {
    final inner = _FakeClient(
      (_) async => http.StreamedResponse(
        Stream.value('{"ok":true}'.codeUnits),
        201,
        headers: {'content-type': 'application/json'},
      ),
    );
    final client = AuthHttpClient(inner, timeout: const Duration(seconds: 5));

    final response = await client.send(
      http.Request(
        'POST',
        Uri.parse('https://example.supabase.co/auth/v1/signup'),
      ),
    );
    expect(response.statusCode, 201);
    expect(response.headers['content-type'], 'application/json');
    expect(await response.stream.bytesToString(), '{"ok":true}');
  });

  test('超时计时器不会在正常完成后触发，close 会关闭底层客户端', () async {
    final inner = _FakeClient((_) async => _ok('done'));
    final client = AuthHttpClient(
      inner,
      timeout: const Duration(milliseconds: 20),
    );
    final response = await client.send(
      http.Request(
        'POST',
        Uri.parse('https://example.supabase.co/auth/v1/token'),
      ),
    );
    expect(await response.stream.bytesToString(), 'done');
    await Future<void>.delayed(const Duration(milliseconds: 40));
    client.close();
    expect(inner.closed, isTrue);
  });

  test('默认仅拦截 auth 路径', () {
    expect(
      AuthHttpClient.defaultIsAuthRequest(
        Uri.parse('https://x.supabase.co/auth/v1/token'),
      ),
      isTrue,
    );
    expect(
      AuthHttpClient.defaultIsAuthRequest(
        Uri.parse('https://x.supabase.co/rest/v1/rooms'),
      ),
      isFalse,
    );
  });
}
