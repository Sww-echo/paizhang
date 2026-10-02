import 'package:flutter_test/flutter_test.dart';

import 'package:paizhang/domain/invite_service.dart';

void main() {
  test('可以使用自定义域名生成 Web 分享链接', () {
    const service = InviteService(webBaseUrl: 'https://example.com/');

    expect(
      service.createWebLink('ab/c+d'),
      'https://example.com/join/ab%2Fc%2Bd',
    );
  });

  test('可以解析 Web 分享链接并还原编码后的 Token', () {
    const service = InviteService(webBaseUrl: 'https://example.com');
    final link = service.createWebLink('ab/c+d');

    expect(service.extractToken(link), 'ab/c+d');
  });

  test('可以解析 paizhang 自定义协议链接', () {
    const service = InviteService();
    final link = service.createShareLink('ab/c+d');

    expect(service.extractToken(link), 'ab/c+d');
  });

  test('可以解析 Flutter Web hash 路由分享链接', () {
    const service = InviteService();

    expect(
      service.extractToken('https://example.com/#/join/ab%2Fc%2Bd'),
      'ab/c+d',
    );
  });

  test('空输入和普通邀请码不会被误判为分享链接', () {
    const service = InviteService();

    expect(service.extractToken(''), isNull);
    expect(service.extractToken('  '), isNull);
    expect(service.extractToken('ABC123'), isNull);
    expect(service.extractToken('https://example.com/join'), isNull);
  });

  test('非法 URI 编码不会让扫码解析抛异常', () {
    const service = InviteService();

    expect(service.extractToken('https://example.com/join/%ZZ'), isNull);
  });
}
