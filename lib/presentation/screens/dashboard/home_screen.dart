import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import './dashboard_tab.dart';
import '../services/services_tab.dart';
import '../terminal/terminal_tab.dart';
import '../files/files_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(['仪表盘', '服务', '终端', '文件'][_currentIndex]),
        actions: [
          if (authState.sessionExpiring)
            const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.wifi_off, size: 16, color: Colors.orange)),
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => context.push('/qr-login'), tooltip: '扫码登录'),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'settings':
                  _showSnack(context, '设置 - 即将推出');
                case 'about':
                  showAboutDialog(context: context, applicationName: 'EasyServer', applicationVersion: '1.0.0', children: [const Text('EasyServer 移动端管理面板')]);
                case 'logout':
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('退出登录'),
                      content: const Text('确定要退出登录吗？'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                        FilledButton(onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authStateProvider.notifier).logout();
                          context.go('/login');
                        }, child: const Text('退出')),
                      ],
                    ),
                  );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('设置'))),
              const PopupMenuItem(value: 'about', child: ListTile(leading: Icon(Icons.info_outline), title: Text('关于'))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('退出登录'))),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardTab(),
          ServicesTab(),
          TerminalTab(),
          FilesTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: '仪表盘'),
          NavigationDestination(icon: Icon(Icons.miscellaneous_services_outlined), selectedIcon: Icon(Icons.miscellaneous_services), label: '服务'),
          NavigationDestination(icon: Icon(Icons.terminal_outlined), selectedIcon: Icon(Icons.terminal), label: '终端'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: '文件'),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(radius: 24, child: Text(authState.user?.username.isNotEmpty == true ? authState.user!.username[0].toUpperCase() : 'U')),
                  const SizedBox(height: 8),
                  Text(authState.user?.username ?? '用户', style: Theme.of(context).textTheme.titleMedium),
                  Text(authState.user?.role ?? '', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            _drawerItem(Icons.monitor_heart, '服务器概览', () { Navigator.pop(context); setState(() => _currentIndex = 0); }),
            _drawerItem(Icons.miscellaneous_services, '服务管理', () { Navigator.pop(context); setState(() => _currentIndex = 1); }),
            _drawerItem(Icons.terminal, '终端', () { Navigator.pop(context); setState(() => _currentIndex = 2); }),
            _drawerItem(Icons.folder, '文件管理', () { Navigator.pop(context); setState(() => _currentIndex = 3); }),
            const Divider(),
            _drawerItem(Icons.dns, '服务器配置', () { Navigator.pop(context); context.push('/setup'); }),
            _drawerItem(Icons.qr_code_scanner, '扫码登录', () { Navigator.pop(context); context.push('/qr-login'); }),
            const Divider(),
            _drawerItem(Icons.logout, '退出登录', () { Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('退出登录'),
                  content: const Text('确定要退出登录吗？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                    FilledButton(onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(authStateProvider.notifier).logout();
                      context.go('/login');
                    }, child: const Text('退出')),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}

