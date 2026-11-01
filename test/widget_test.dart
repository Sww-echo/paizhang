import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paizhang/main.dart';
import 'package:paizhang/presentation/design.dart';

void main() {
  testWidgets('未配置后端时显示设置说明，不展示静态房间数据', (tester) async {
    await tester.pumpWidget(const PaizhangApp());

    expect(find.text('尚未连接真实数据服务'), findsOneWidget);
    expect(find.text('周三晚间掼蛋'), findsNothing);
    expect(find.text('我的房间'), findsNothing);
  });

  testWidgets('主题使用方案 token，并提供日／夜两套', (tester) async {
    await tester.pumpWidget(const PaizhangApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme!.scaffoldBackgroundColor, PzColors.light.bg);
    expect(app.darkTheme!.scaffoldBackgroundColor, PzColors.dark.bg);
    expect(app.themeMode, ThemeMode.system);
  });
}
