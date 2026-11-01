import 'dart:async';

import 'package:http/http.dart' as http;

/// Bounds how long Supabase auth requests may take and aborts the underlying
/// request, so a late response cannot create a session after the UI gave up.
///
/// Only `/auth/v1/` requests are affected; every other request is passed to
/// [inner] untouched. The timeout covers both the response headers and an idle
/// response body, and the caller is released even if the inner client ignores
/// the abort trigger.
class AuthHttpClient extends http.BaseClient {
  AuthHttpClient(
    this.inner, {
    this.timeout = const Duration(seconds: 20),
    bool Function(Uri url)? isAuthRequest,
  }) : _isAuthRequest = isAuthRequest ?? defaultIsAuthRequest;

  final http.Client inner;
  final Duration timeout;
  final bool Function(Uri url) _isAuthRequest;

  static bool defaultIsAuthRequest(Uri url) =>
      url.path.contains('/auth/v1/') || url.path.endsWith('/auth/v1');

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!_isAuthRequest(request.url)) return inner.send(request);
    final abortSignal = Completer<void>();
    void abort() {
      if (!abortSignal.isCompleted) abortSignal.complete();
    }

    final abortable = _abortable(request, abortSignal.future);
    final timedOut = Completer<http.StreamedResponse>();
    final timer = Timer(timeout, () {
      abort();
      if (!timedOut.isCompleted) {
        timedOut.completeError(_timeoutError(request.url, '请求超时'));
      }
    });
    final pending = inner.send(abortable);
    // The abandoned response is intentionally discarded: a session created by a
    // late response must not leak into the app after the timeout.
    unawaited(pending.then<void>((_) {}, onError: (Object _) {}));
    return Future.any<http.StreamedResponse>([pending, timedOut.future])
        .then((response) => _bounded(response, request, abort))
        .whenComplete(timer.cancel);
  }

  http.StreamedResponse _bounded(
    http.StreamedResponse response,
    http.BaseRequest request,
    void Function() abort,
  ) {
    return http.StreamedResponse(
      response.stream.timeout(
        timeout,
        onTimeout: (sink) {
          abort();
          sink.addError(_timeoutError(request.url, '响应超时'));
          sink.close();
        },
      ),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  http.ClientException _timeoutError(Uri url, String reason) =>
      http.ClientException('认证$reason，请检查网络后重试', url);

  http.BaseRequest _abortable(
    http.BaseRequest request,
    Future<void> abortSignal,
  ) {
    // Rebuild Request, including an existing AbortableRequest, so this client
    // owns the abort trigger used by its timeout policy.
    if (request is http.Request) {
      return http.AbortableRequest(
          request.method,
          request.url,
          abortTrigger: abortSignal,
        )
        ..encoding = request.encoding
        ..persistentConnection = request.persistentConnection
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..headers.addAll(request.headers)
        ..bodyBytes = request.bodyBytes;
    }
    return request;
  }

  @override
  void close() => inner.close();
}
