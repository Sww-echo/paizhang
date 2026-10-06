import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/presentation/multi_score_transfer_dialog.dart';

import '../support/fakes.dart';

const thirdId = 'user-3';

List<RoomMember> _members() => [
  RoomMember(userId: ownerId, role: RoomRole.owner, joinedAt: fixtureDate),
  RoomMember(userId: memberId, role: RoomRole.member, joinedAt: fixtureDate),
  RoomMember(userId: thirdId, role: RoomRole.member, joinedAt: fixtureDate),
];

const _profiles = {
  ownerId: User(id: ownerId, nickname: '房主'),
  memberId: User(id: memberId, nickname: '成员'),
  thirdId: User(id: thirdId, nickname: '牌友三'),
};

Future<void> _open(
  WidgetTester tester,
  Future<void> Function(Map<String, int> amounts) onSubmit,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (_) => MultiScoreTransferDialog(
                actorId: ownerId,
                members: _members(),
                profiles: _profiles,
                scoringMode: ScoringMode.points,
                onSubmit: onSubmit,
              ),
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, String userId, String amount) async {
  await tester.tap(find.byKey(ValueKey('recipient-$userId')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(ValueKey('transfer-amount-$userId')),
    amount,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('选择两位接收人并确认后提交一次批量转分', (tester) async {
    Map<String, int>? submitted;
    await _open(tester, (amounts) async => submitted = amounts);

    expect(find.textContaining('房主'), findsWidgets);
    expect(find.byKey(ValueKey('recipient-$ownerId')), findsNothing);

    await _select(tester, memberId, '10');
    await _select(tester, thirdId, '20');
    expect(find.textContaining('已选 2 人'), findsOneWidget);
    expect(find.textContaining('30'), findsWidgets);

    await tester.tap(find.text('核对并提交'));
    await tester.pumpAndSettle();
    expect(find.text('确认多人转分'), findsOneWidget);
    expect(find.text('成员 +10 积分'), findsOneWidget);
    expect(find.text('牌友三 +20 积分'), findsOneWidget);

    await tester.tap(find.text('确认提交'));
    await tester.pumpAndSettle();
    expect(submitted, {memberId: 10, thirdId: 20});
    expect(find.byType(MultiScoreTransferDialog), findsNothing);
  });

  testWidgets('未选择接收人或金额无效时不提交并提示原因', (tester) async {
    var calls = 0;
    await _open(tester, (amounts) async => calls++);

    await tester.tap(find.text('核对并提交'));
    await tester.pumpAndSettle();
    expect(find.text('请至少选择一位接收人'), findsOneWidget);
    expect(find.text('确认多人转分'), findsNothing);

    await _select(tester, memberId, '0');
    await tester.tap(find.text('核对并提交'));
    await tester.pumpAndSettle();
    expect(find.textContaining('请输入有效的正整数'), findsOneWidget);
    expect(find.text('确认多人转分'), findsNothing);
    expect(calls, 0);
  });

  testWidgets('取消确认不写入，返回后可继续修改', (tester) async {
    var calls = 0;
    await _open(tester, (amounts) async => calls++);
    await _select(tester, memberId, '10');
    await tester.tap(find.text('核对并提交'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('返回修改'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.byType(MultiScoreTransferDialog), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byType(MultiScoreTransferDialog), findsNothing);
    expect(calls, 0);
  });

  testWidgets('提交失败保留输入并显示错误', (tester) async {
    await _open(tester, (amounts) async {
      throw const PaizhangException('当前牌局不允许写入');
    });
    await _select(tester, memberId, '10');
    await tester.tap(find.text('核对并提交'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认提交'));
    await tester.pumpAndSettle();
    expect(find.text('当前牌局不允许写入'), findsOneWidget);
    expect(find.byType(MultiScoreTransferDialog), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(ValueKey('transfer-amount-$memberId')))
          .controller!
          .text,
      '10',
    );
  });
}
