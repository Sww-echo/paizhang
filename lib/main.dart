import 'package:flutter/material.dart';

import 'application/app_services.dart';
import 'infrastructure/backend/supabase_bootstrap.dart';
import 'presentation/connected_app.dart';
import 'presentation/design.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabaseConfigured = await SupabaseBootstrap.initializeIfConfigured();
  final services = AppServices.create(supabaseConfigured: supabaseConfigured);
  runApp(PaizhangApp(services: services));
}

class PaizhangApp extends StatelessWidget {
  const PaizhangApp({this.services, super.key});

  final AppServices? services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '牌账',
      debugShowCheckedModeBanner: false,
      theme: PzTheme.light(),
      darkTheme: PzTheme.dark(),
      themeMode: ThemeMode.system,
      home: services == null || !services!.isConfigured
          ? const SupabaseSetupPage()
          : AuthGate(services: services!),
    );
  }
}

class SupabaseSetupPage extends StatelessWidget {
  const SupabaseSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('牌账')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PzBoard(
              dividerBetween: false,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 42,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '尚未连接真实数据服务',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '当前 Web 未配置 Supabase，因此不会显示可操作的房间数据。请使用 SUPABASE_URL 和 SUPABASE_PUBLISHABLE_KEY 重新启动应用。',
                      ),
                      const SizedBox(height: 16),
                      const SelectableText(
                        'flutter run -d web-server \\\n  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \\\n  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
