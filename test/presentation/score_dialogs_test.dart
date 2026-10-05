import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paizhang/domain/models.dart';
import 'package:paizhang/presentation/score_dialogs.dart';

void main() {
  testWidgets('头像转换默认锁定当前用户转给被点击成员', (tester) async {
    ScoreTransfer? result;
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
      'current-user': const User(id: 'current-user', nickname: '我'),
      'friend-user': const User(id: 'friend-user', nickname: '好友'),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await showDialog<ScoreTransfer>(
                  context: context,
                  builder: (_) => ScoreTransferDialog(
                    members: members,
                    profiles: profiles,
                    totals: const {'current-user': 30},
                    scoringMode: ScoringMode.points,
                    fromPlayerId: 'current-user',
                    toPlayerId: 'friend-user',
                  ),
                );
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField), findsNothing);
    expect(find.text('我'), findsOneWidget);
    expect(find.text('好友'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('确认转换'));
    await tester.pumpAndSettle();

    expect(result?.fromPlayerId, 'current-user');
    expect(result?.toPlayerId, 'friend-user');
    expect(result?.amount, 12);
  });
}
