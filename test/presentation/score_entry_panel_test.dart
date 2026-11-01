import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/presentation/presentation_helpers.dart';
import 'package:paizhang/presentation/score_entry_panel.dart';

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

List<ScoreChange>? saved;
String? savedNote;
bool failSave = false;

Future<void> _open(
  WidgetTester tester, {
  required ScoreEntryMode mode,
  ScoringMode scoring = ScoringMode.points,
  ScoreDraftStore? drafts,
}) async {
  saved = null;
  savedNote = null;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => ScoreEntryPanel(
                mode: mode,
                actorId: ownerId,
                roomId: 'room-1',
                roomName: '测试房间',
                members: _members(),
                profiles: _profiles,
                scoringMode: scoring,
                sessions: [
                  ScoreEntrySession(
                    id: 'session-1',
                    name: '第一场',
                    nextRoundNumber: 13,
                    totals: const {ownerId: 30, memberId: 10, thirdId: 0},
                  ),
                ],
                initialSessionId: 'session-1',
                drafts: drafts ?? ScoreDraftStore(),
                onSave: (sessionId, changes) async {
                  if (failSave) {
                    throw const AppError(AppErrorKind.forbidden, '当前牌局不允许写入');
                  }
                  saved = changes;
                },
                onSaveWithNote: (sessionId, changes, note) async {
                  if (failSave) {
                    throw const AppError(AppErrorKind.forbidden, '当前牌局不允许写入');
                  }
                  saved = changes;
                  savedNote = note;
                },
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

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, String userId, String amount) async {
  await _tapVisible(tester, find.byKey(ValueKey('recipient-$userId')));
  await tester.enterText(
    find.byKey(ValueKey('transfer-amount-$userId')),
    amount,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => failSave = false);

  testWidgets('多人转分：勾选两人、核对并一次保存为一条记录', (tester) async {
    await _open(tester, mode: ScoreEntryMode.multi);
    await _select(tester, memberId, '10');
    await _select(tester, thirdId, '20');
    expect(find.text('30 分'), findsOneWidget);
    expect(find.textContaining('房主 −30 · 成员 +10 · 牌友三 +20'), findsOneWidget);

    await _tapVisible(tester, find.text('核对'));
    expect(find.text('核对本回合'), findsOneWidget);
    await _tapVisible(tester, find.text('确认保存'));

    expect(saved, isNotNull);
    expect(
      {for (final change in saved!) change.playerId: change.value},
      {ownerId: -30, memberId: 10, thirdId: 20},
    );
  });

  testWidgets('取消勾选保留金额，重新勾选可恢复', (tester) async {
    await _open(tester, mode: ScoreEntryMode.multi);
    await _select(tester, memberId, '10');
    await _tapVisible(tester, find.byKey(ValueKey('recipient-$memberId')));
    expect(find.text('未选择'), findsWidgets);
    expect(
      tester
          .widget<TextField>(find.byKey(ValueKey('transfer-amount-$memberId')))
          .controller!
          .text,
      '10',
    );
    await _tapVisible(tester, find.byKey(ValueKey('recipient-$memberId')));
    expect(find.text('10 分'), findsOneWidget);
  });

  testWidgets('未选择接收人或金额无效时不能核对', (tester) async {
    await _open(tester, mode: ScoreEntryMode.multi);
    final review = find.widgetWithText(FilledButton, '核对');
    expect(tester.widget<FilledButton>(review).onPressed, isNull);

    await _select(tester, memberId, '0');
    expect(find.textContaining('请输入大于 0 的有效整数金额'), findsOneWidget);
    expect(tester.widget<FilledButton>(review).onPressed, isNull);
  });

  testWidgets('整局金额模式平摊余数后核对保存', (tester) async {
    await _open(tester, mode: ScoreEntryMode.full, scoring: ScoringMode.money);
    await tester.enterText(find.byKey(ValueKey('full-$thirdId')), '50');
    await tester.pumpAndSettle();
    // 还剩两位未填：自动补齐不生效，需要平摊。
    await _tapVisible(tester, find.text('平摊给未填成员'));
    expect(find.textContaining('平摊明细：房主 −25，成员 −25'), findsOneWidget);
    expect(find.text('0 · 已平账'), findsOneWidget);

    await _tapVisible(tester, find.text('核对'));
    await _tapVisible(tester, find.text('确认保存'));
    expect(
      {for (final change in saved!) change.playerId: change.value},
      {ownerId: -25, memberId: -25, thirdId: 50},
    );
  });

  testWidgets('自动补齐最后一位未填成员，手动修改后不再被覆盖', (tester) async {
    await _open(tester, mode: ScoreEntryMode.full, scoring: ScoringMode.money);
    await tester.enterText(find.byKey(ValueKey('full-$ownerId')), '40');
    await tester.enterText(find.byKey(ValueKey('full-$memberId')), '10');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(ValueKey('full-$thirdId')))
          .controller!
          .text,
      '-50',
    );
    expect(find.textContaining('自动补齐 −50'), findsOneWidget);

    await tester.enterText(find.byKey(ValueKey('full-$thirdId')), '-30');
    await tester.pumpAndSettle();
    expect(find.textContaining('手动值，不自动覆盖'), findsNWidgets(3));
    expect(find.text('+20 · 金额模式还需分配 −20'), findsOneWidget);
  });

  testWidgets('整局录入保存备注', (tester) async {
    await _open(tester, mode: ScoreEntryMode.full, scoring: ScoringMode.money);
    await tester.enterText(find.byKey(ValueKey('full-$ownerId')), '40');
    await tester.enterText(find.byKey(ValueKey('full-$memberId')), '10');
    await tester.enterText(find.byKey(const ValueKey('round-note')), '晚局补记');
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('核对'));
    await _tapVisible(tester, find.text('确认保存'));
    expect(savedNote, '晚局补记');
  });

  testWidgets('提交失败保留输入并显示原因，不关闭面板', (tester) async {
    await _open(tester, mode: ScoreEntryMode.full, scoring: ScoringMode.money);
    await tester.enterText(find.byKey(ValueKey('full-$thirdId')), '50');
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('平摊给未填成员'));
    failSave = true;
    await _tapVisible(tester, find.text('核对'));
    await _tapVisible(tester, find.text('确认保存'));
    expect(find.byType(ScoreEntryPanel), findsOneWidget);
    expect(find.text('当前牌局不允许写入'), findsOneWidget);
  });

  testWidgets('关闭面板保留草稿，重新打开可恢复', (tester) async {
    final drafts = ScoreDraftStore();
    await _open(tester, mode: ScoreEntryMode.full, drafts: drafts);
    await tester.enterText(find.byKey(ValueKey('full-$thirdId')), '50');
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('返回记分台'));
    expect(find.byType(ScoreEntryPanel), findsNothing);

    await _open(tester, mode: ScoreEntryMode.full, drafts: drafts);
    expect(
      tester
          .widget<TextField>(find.byKey(ValueKey('full-$thirdId')))
          .controller!
          .text,
      '50',
    );
  });

  test('平摊按固定加入顺序分配整数余数', () {
    expect(pzSplitAmount(-50, 3), [-17, -17, -16]);
    expect(pzSplitAmount(50, 3), [17, 17, 16]);
    expect(pzSplitAmount(-2, 4), [-1, -1, 0, 0]);
    expect(pzSplitAmount(0, 3), [0, 0, 0]);
  });
}
