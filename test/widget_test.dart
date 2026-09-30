import 'package:flutter_test/flutter_test.dart';

import 'package:paizhang/main.dart';

void main() {
  testWidgets('牌账首页展示核心入口', (WidgetTester tester) async {
    await tester.pumpWidget(const PaizhangApp());

    expect(find.text('牌账'), findsOneWidget);
    expect(find.text('创建房间'), findsOneWidget);
    expect(find.text('加入房间'), findsOneWidget);
    expect(find.text('周三晚间掼蛋'), findsOneWidget);
  });

  testWidgets('可以切换到房间和个人中心', (WidgetTester tester) async {
    await tester.pumpWidget(const PaizhangApp());

    await tester.tap(find.text('房间'));
    await tester.pumpAndSettle();
    expect(find.text('我的房间'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('个人资料'), findsOneWidget);
  });
}
