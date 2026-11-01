import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/domain/app_error.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/presentation/transfer_dialog.dart';

void main() {
  ScoreTransferRequest? submitted;
  bool fail = false;

  Future<void> open(WidgetTester tester, {String initialAmount = ''}) async {
    submitted = null;
    final members = [
      RoomMember(
        userId: 'current-user',
        role: RoomRole.owner,
        joinedAt: DateTime(2026, 1, 1),
      ),
      RoomMember(
        userId: 'friend-user',
        role: RoomRole.member,
        joinedAt: DateTime(2026, 1, 1),
      ),
    ];
    final profiles = {
      'current-user': const User(id: 'current-user', nickname: 'Sww'),
      'friend-user': const User(id: 'friend-user', nickname: '好友'),
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => ScoreTransferDialog(
                  actorId: 'current-user',
                  toPlayerId: 'friend-user',
                  members: members,
                  profiles: profiles,
                  totals: const {'current-user': 240, 'friend-user': 80},
                  scoringMode: ScoringMode.points,
                  roomName: '周五夜局',
                  sessionName: '晚场麻将',
                  nextRoundNumber: 13,
                  initialAmount: initialAmount,
                  onSubmit: (request) async {
                    if (fail) {
                      throw const AppError(AppErrorKind.forbidden, '当前房间不允许录入');
                    }
                    submitted = request;
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

  setUp(() => fail = false);

  testWidgets('方向固定为我转给被点击成员，确认后提交一次', (tester) async {
    await open(tester);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('我'), findsOneWidget);
    expect(find.text('好友'), findsOneWidget);
    expect(find.text('转出方固定'), findsOneWidget);
    expect(find.text('接收方固定'), findsOneWidget);
    expect(find.textContaining('预计第 13 回合'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '20');
    await tester.pumpAndSettle();
    expect(find.textContaining('预计累计：Sww +220 · 好友 +100'), findsOneWidget);

    await tester.tap(find.text('确认转分'));
    await tester.pumpAndSettle();

    expect(submitted?.toPlayerId, 'friend-user');
    expect(submitted?.amount, 20);
    expect(find.byType(ScoreTransferDialog), findsNothing);
  });

  testWidgets('常用金额直接填入并保持选中态', (tester) async {
    await open(tester);
    await tester.tap(find.text('50'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '50',
    );
    await tester.tap(find.text('确认转分'));
    await tester.pumpAndSettle();
    expect(submitted?.amount, 50);
  });

  testWidgets('无效金额禁用确认并就地说明', (tester) async {
    await open(tester);
    final button = find.widgetWithText(FilledButton, '确认转分');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '0');
    await tester.pumpAndSettle();
    expect(find.text('请输入大于 0 的有效整数积分'), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '-5');
    await tester.pumpAndSettle();
    expect(find.text('请输入大于 0 的有效整数积分'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '20');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('草稿金额恢复，提交失败保留输入并显示原因', (tester) async {
    await open(tester, initialAmount: '30');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '30',
    );

    fail = true;
    await tester.tap(find.text('确认转分'));
    await tester.pumpAndSettle();
    expect(find.byType(ScoreTransferDialog), findsOneWidget);
    expect(find.text('当前房间不允许录入'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '30',
    );
  });
}
