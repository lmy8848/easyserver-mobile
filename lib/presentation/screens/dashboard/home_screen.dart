import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_toast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_state.dart';
import '../../providers/notification_provider.dart';
import './dashboard_tab.dart';
import '../containers/containers_tab.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // provider 层操作反馈（容器启停等）通过全局 Toast 弹出
      AppToast.bind(ScaffoldMessenger.of(context));
    });
    // 通知轮询：未读角标 + 新通知 SnackBar（SSE 适合 Web 常连接，移动端轮询更省电）
    ref.read(notificationProvider.notifier).startPolling(onNew: (item) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${item.title}: ${item.message}'),
              duration: const Duration(seconds: 3)),
        );
      }
    });
  }

  @override
  void dispose() {
    ref.read(notificationProvider.notifier).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(['仪表盘', '容器', '服务', '终端', '文件'][_currentIndex]),
        actions: [
          if (authState.sessionExpiring)
            const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.wifi_off, size: 16, color: Colors.orange)),
          IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.push('/qr-login'),
              tooltip: '扫码登录'),
          IconButton(
            icon: Badge(
              isLabelVisible: ref
                  .watch(notificationProvider.select((s) => s.unreadCount > 0)),
              label: Text(
                  '${ref.watch(notificationProvider.select((s) => s.unreadCount))}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: '通知中心',
            onPressed: () => context.push('/notifications'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'settings':
                  context.push('/profile');
                case 'about':
                  showAboutDialog(
                      context: context,
                      applicationName: 'EasyServer',
                      applicationVersion: '1.0.0',
                      children: [const Text('EasyServer 移动端管理面板')]);
                case 'logout':
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('退出登录'),
                      content: const Text('确定要退出登录吗？'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('取消')),
                        FilledButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ref.read(authStateProvider.notifier).logout();
                              context.go('/login');
                            },
                            child: const Text('退出')),
                      ],
                    ),
                  );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                      leading: Icon(Icons.settings), title: Text('设置'))),
              const PopupMenuItem(
                  value: 'about',
                  child: ListTile(
                      leading: Icon(Icons.info_outline), title: Text('关于'))),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                      leading: Icon(Icons.logout), title: Text('退出登录'))),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardTab(),
          ContainersTab(),
          ServicesTab(),
          TerminalTab(),
          FilesTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          // 广播可见性：IndexedStack 常驻各 tab，仪表盘等据此懒加载/停刷
          ref.read(homeTabProvider.notifier).state = i;
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: '仪表盘'),
          NavigationDestination(
              icon: Icon(Icons.view_in_ar_outlined),
              selectedIcon: Icon(Icons.view_in_ar),
              label: '容器'),
          NavigationDestination(
              icon: Icon(Icons.miscellaneous_services_outlined),
              selectedIcon: Icon(Icons.miscellaneous_services),
              label: '服务'),
          NavigationDestination(
              icon: Icon(Icons.terminal_outlined),
              selectedIcon: Icon(Icons.terminal),
              label: '终端'),
          NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: '文件'),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                      radius: 24,
                      child: Text(authState.user?.username.isNotEmpty == true
                          ? authState.user!.username[0].toUpperCase()
                          : 'U')),
                  const SizedBox(height: 8),
                  Text(authState.user?.username ?? '用户',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(authState.user?.role ?? '',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            _drawerItem(Icons.monitor_heart, '服务器概览', () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            }),
            _drawerItem(Icons.miscellaneous_services, '服务管理', () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            }),
            _drawerItem(Icons.terminal, '终端', () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            }),
            _drawerItem(Icons.folder, '文件管理', () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            }),
            _drawerItem(Icons.lan_outlined, '局域网传文件', () {
              Navigator.pop(context);
              context.push('/lanshare');
            }),
            const Divider(),
            _drawerItem(Icons.manage_accounts, '账户与安全', () {
              Navigator.pop(context);
              context.push('/profile');
            }),
            _drawerItem(Icons.dns, '服务器配置', () {
              Navigator.pop(context);
              context.push('/setup');
            }),
            _drawerItem(Icons.qr_code_scanner, '扫码登录', () {
              Navigator.pop(context);
              context.push('/qr-login');
            }),
            const Divider(),
            _drawerItem(Icons.logout, '退出登录', () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('退出登录'),
                  content: const Text('确定要退出登录吗？'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消')),
                    FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(authStateProvider.notifier).logout();
                          context.go('/login');
                        },
                        child: const Text('退出')),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
