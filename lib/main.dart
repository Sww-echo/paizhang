import 'package:flutter/material.dart';

import 'application/app_services.dart';
import 'infrastructure/backend/supabase_bootstrap.dart';
import 'presentation/connected_app.dart';

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
    const ink = Color(0xFF17342F);
    const cream = Color(0xFFF7F4EC);

    return MaterialApp(
      title: '牌账',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF2F7D68),
              brightness: Brightness.light,
            ).copyWith(
              surface: cream,
              onSurface: ink,
              primary: const Color(0xFF2F7D68),
              secondary: const Color(0xFFE7A85B),
            ),
        scaffoldBackgroundColor: cream,
        fontFamily: 'PingFang SC',
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: cream,
          indicatorColor: const Color(0xFFD9E9DF),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ink),
          ),
        ),
      ),
      home: services == null
          ? const HomeShell()
          : services!.isConfigured
          ? AuthGate(services: services!)
          : const SupabaseSetupPage(),
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
            child: Card(
              elevation: 0,
              child: Padding(
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
                      'flutter run -d web-server \\\n+  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \\\n+  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>',
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onAction: _showMessage),
      RoomsPage(onAction: _showMessage),
      ProfilePage(onAction: _showMessage),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: '牌局',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: '房间',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.onAction, super.key});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text(
            '牌账',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              onPressed: () => onAction('通知功能即将上线'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                '晚上好，Sww',
                style: TextStyle(fontSize: 15, color: Color(0xFF6B766F)),
              ),
              const SizedBox(height: 6),
              const Text(
                '今天也把账记清楚。',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              _ActiveGameCard(onAction: onAction),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_rounded,
                      label: '创建房间',
                      primary: true,
                      onPressed: () => onAction('创建房间功能即将接入'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.login_rounded,
                      label: '加入房间',
                      onPressed: () => onAction('支持扫码、链接和邀请码加入'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const _SectionTitle(title: '最近牌局', action: '查看全部'),
              const SizedBox(height: 12),
              _RecentGameTile(
                title: '周三晚间掼蛋',
                subtitle: '4 人 · 12 局 · 今天 21:42',
                result: '+120',
                resultLabel: '积分',
                positive: true,
              ),
              const SizedBox(height: 10),
              _RecentGameTile(
                title: '周末麻将',
                subtitle: '4 人 · 8 局 · 9 月 27 日',
                result: '-80',
                resultLabel: '元',
                positive: false,
              ),
              const SizedBox(height: 30),
              const _SectionTitle(title: '本月战绩'),
              const SizedBox(height: 12),
              _MonthlyStats(onAction: onAction),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ActiveGameCard extends StatelessWidget {
  const _ActiveGameCard({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0xFF1F4D42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E8B74),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '进行中',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_horiz_rounded, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              '周三晚间掼蛋',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '4 位牌友 · 第 6 局',
              style: TextStyle(color: Color(0xFFB9D2C6), fontSize: 13),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '当前领先\n张三  +120',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => onAction('当前牌局即将打开'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE7A85B),
                    foregroundColor: const Color(0xFF3D2A13),
                  ),
                  child: const Text('继续记分'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RoomsPage extends StatelessWidget {
  const RoomsPage({required this.onAction, super.key});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text(
            '我的房间',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_rounded,
                      label: '创建房间',
                      primary: true,
                      onPressed: () => onAction('创建房间功能即将接入'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.qr_code_scanner_rounded,
                      label: '加入房间',
                      onPressed: () => onAction('加入房间支持扫码、链接和邀请码'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _RoomTile(
                name: '周末牌局',
                detail: '4 位成员 · 掼蛋',
                status: '进行中',
                color: const Color(0xFFD9E9DF),
                onTap: () => onAction('正在打开周末牌局'),
              ),
              const SizedBox(height: 12),
              _RoomTile(
                name: '邻里麻将局',
                detail: '4 位成员 · 最近活跃 9 月 27 日',
                status: '已结束',
                color: const Color(0xFFF1E2C8),
                onTap: () => onAction('正在打开邻里麻将局'),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.onAction, super.key});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
      children: [
        const Text(
          '我的',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            CircleAvatar(
              radius: 29,
              backgroundColor: const Color(0xFFBFD9CD),
              child: const Text(
                'S',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F4D42),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sww',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  '已登录 · 数据自动同步',
                  style: TextStyle(color: Color(0xFF6B766F), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 30),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: '个人资料',
                onTap: () => onAction('个人资料功能即将接入'),
              ),
              _SettingsTile(
                icon: Icons.file_download_outlined,
                title: '数据导出',
                onTap: () => onAction('支持导出牌局和结算记录'),
              ),
              _SettingsTile(
                icon: Icons.settings_outlined,
                title: '设置',
                onTap: () => onAction('设置功能即将接入'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: primary
            ? const Color(0xFF2F7D68)
            : const Color(0xFFE8E5DA),
        foregroundColor: primary ? Colors.white : const Color(0xFF17342F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        if (action != null) TextButton(onPressed: () {}, child: Text(action!)),
      ],
    );
  }
}

class _RecentGameTile extends StatelessWidget {
  const _RecentGameTile({
    required this.title,
    required this.subtitle,
    required this.result,
    required this.resultLabel,
    required this.positive,
  });

  final String title;
  final String subtitle;
  final String result;
  final String resultLabel;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final resultColor = positive
        ? const Color(0xFF2F7D68)
        : const Color(0xFFB55D46);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: positive
              ? const Color(0xFFD9E9DF)
              : const Color(0xFFF3DCD3),
          child: Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: resultColor,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              result,
              style: TextStyle(
                color: resultColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              resultLabel,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B766F)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyStats extends StatelessWidget {
  const _MonthlyStats({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本月净积分',
                    style: TextStyle(color: Color(0xFF6B766F), fontSize: 13),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '+240',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2F7D68),
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => onAction('详细战绩即将接入'),
              child: const Text('看详情'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.name,
    required this.detail,
    required this.status,
    required this.color,
    required this.onTap,
  });

  final String name;
  final String detail;
  final String status;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color,
          child: const Icon(Icons.groups_rounded, color: Color(0xFF17342F)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(detail),
        trailing: Text(
          status,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B766F)),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF2F7D68)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
