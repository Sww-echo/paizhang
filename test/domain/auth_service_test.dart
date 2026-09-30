import 'package:flutter_test/flutter_test.dart';

import 'package:paizhang/application/auth_service.dart';
import 'package:paizhang/domain/models.dart';

void main() {
  test('验证码登录会创建并恢复会话', () {
    var id = 0;
    final auth = AuthService(
      clock: () => DateTime(2026, 9, 30, 12),
      idFactory: (prefix) => '$prefix-${id++}',
    );
    final challenge = auth.requestCode(identifier: 'user@example.com');
    final session = auth.verifyCode(
      challengeId: challenge.id,
      code: challenge.verificationCode,
      nickname: 'Sww',
    );

    expect(auth.userForSession(session.token).nickname, 'Sww');
    auth.revokeSession(session.token);
    expect(
      () => auth.userForSession(session.token),
      throwsA(isA<PaizhangException>()),
    );
  });

  test('验证码错误或过期不能登录', () {
    var now = DateTime(2026, 9, 30, 12);
    final auth = AuthService(
      clock: () => now,
      idFactory: (prefix) => '$prefix-1',
    );
    final challenge = auth.requestCode(identifier: '13800138000');

    expect(
      () => auth.verifyCode(
        challengeId: challenge.id,
        code: '000000',
        nickname: 'Sww',
      ),
      throwsA(isA<PaizhangException>()),
    );

    now = now.add(const Duration(minutes: 6));
    expect(
      () => auth.verifyCode(
        challengeId: challenge.id,
        code: challenge.verificationCode,
        nickname: 'Sww',
      ),
      throwsA(isA<PaizhangException>()),
    );
  });
}
