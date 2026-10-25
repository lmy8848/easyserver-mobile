import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../di/providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_settings_provider.dart';

/// 账户与安全：用户信息、两步验证（TOTP）管理、会话管理（踢出）、修改密码。
/// 数据层 API 均已就绪（authRepository），此页完成 UI 接线。
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _totpEnabled = false;
  bool _loadingTotp = true;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadTotpStatus();
    _loadSessions();
  }

  Future<void> _loadTotpStatus() async {
    try {
      final enabled = await ref.read(authRepositoryProvider).getTotpStatus();
      if (mounted)
        setState(() {
          _totpEnabled = enabled;
          _loadingTotp = false;
        });
    } catch (e) {
      if (mounted) setState(() => _loadingTotp = false);
    }
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await ref.read(authRepositoryProvider).getSessions();
      if (mounted) setState(() => _sessions = sessions);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('账户与安全')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── 用户信息 ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      user?.username.isNotEmpty == true
                          ? user!.username[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.username ?? '-',
                          style: theme.textTheme.titleLarge),
                      Text('角色: ${user?.role ?? '-'}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── 两步验证 ──
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('两步验证（TOTP）'),
                  subtitle: Text(
                      _loadingTotp ? '加载中…' : (_totpEnabled ? '已启用' : '未启用')),
                  trailing: _loadingTotp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : FilledButton.tonal(
                          onPressed: _totpEnabled
                              ? _showDisableTotpDialog
                              : _startTotpSetup,
                          child: Text(_totpEnabled ? '禁用' : '启用'),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 会话管理 ──
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.devices),
                  title: Text('登录会话（${_sessions.length}）'),
                  trailing: _sessions.length > 1
                      ? TextButton(
                          onPressed: _kickAllOthers, child: const Text('踢出其他'))
                      : null,
                ),
                if (_sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text('暂无会话数据', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ..._sessions.map((s) {
                    final isCurrent = s['is_current'] == true;
                    final token = (s['token'] as String? ?? '');
                    return ListTile(
                      dense: true,
                      leading: Icon(
                          isCurrent ? Icons.phone_iphone : Icons.devices_other,
                          color: isCurrent ? Colors.green : Colors.grey),
                      title: Text(
                        '${isCurrent ? "本机" : "其他设备"} · ${_clientHint(s['user_agent'] as String?)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${s['ip'] ?? '-'} · ${s['created_at'] ?? '-'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: isCurrent
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.logout, size: 18),
                              tooltip: '踢出',
                              onPressed: () => _kickSession(token),
                            ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 修改密码 / 刷新间隔 / 服务器 / 退出 ──
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('修改密码'),
                  onTap: _showChangePasswordDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('仪表盘刷新间隔'),
                  subtitle:
                      Text(_refreshLabel(ref.watch(dashboardRefreshProvider))),
                  onTap: _showRefreshIntervalDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: const Text('服务器配置'),
                  subtitle:
                      Text(ref.watch(serverConfigProvider)?.host ?? '未配置'),
                  onTap: () => context.push('/setup'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title:
                      const Text('退出登录', style: TextStyle(color: Colors.red)),
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _refreshLabel(int seconds) =>
      seconds <= 0 ? '关闭（手动刷新）' : '每 $seconds 秒';

  Future<void> _showRefreshIntervalDialog() async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('仪表盘自动刷新间隔'),
            ),
            ...DashboardRefreshNotifier.choices.map(
              (s) => ListTile(
                title: Text(_refreshLabel(s)),
                onTap: () => Navigator.of(ctx).pop(s),
              ),
            ),
          ],
        ),
      ),
    );
    if (choice != null) {
      await ref.read(dashboardRefreshProvider.notifier).setInterval(choice);
    }
  }

  String _clientHint(String? ua) {
    if (ua == null) return '未知客户端';
    if (ua.contains('Dart') || ua.contains('dart')) return '移动端';
    if (ua.contains('Mobile')) return '移动浏览器';
    return 'Web 浏览器';
  }

  // ── TOTP 启用：setup 展示密钥 → 输入验证码确认 ──
  Future<void> _startTotpSetup() async {
    try {
      final setup = await ref.read(authRepositoryProvider).setupTotp();
      if (!mounted) return;
      final secret = (setup['secret'] ?? setup['key'] ?? '') as String;
      final otpauth = (setup['otpauth_url'] ?? setup['url'] ?? '') as String;

      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('启用两步验证'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. 在验证器 App 中添加：'),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => Clipboard.setData(
                    ClipboardData(text: otpauth.isNotEmpty ? otpauth : secret)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    otpauth.isNotEmpty ? otpauth : secret,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text('（点击复制）\n2. 输入 6 位验证码确认：'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration:
                    const InputDecoration(hintText: '验证码', counterText: ''),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('确认启用')),
          ],
        ),
      );
      if (ok != true) return;
      final codes = await ref
          .read(authRepositoryProvider)
          .enableTotp(controller.text.trim());
      if (!mounted) return;
      setState(() {
        _totpEnabled = true;
      });
      // 展示一次性备用码（仅此一次可见）
      if (codes.isNotEmpty && mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('备用恢复码'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('请妥善保存（仅显示一次）：'),
                const SizedBox(height: 8),
                ...codes.map((c) =>
                    Text(c, style: const TextStyle(fontFamily: 'monospace'))),
              ],
            ),
            actions: [
              FilledButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('已保存'))
            ],
          ),
        );
      }
    } catch (e) {
      _snack('启用失败: $e');
    }
  }

  Future<void> _showDisableTotpDialog() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('禁用两步验证'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: '登录密码'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认禁用')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).disableTotp(controller.text);
      if (mounted) setState(() => _totpEnabled = false);
      _snack('两步验证已禁用');
    } catch (e) {
      _snack('禁用失败: $e');
    }
  }

  // ── 会话 ──
  Future<void> _kickSession(String token) async {
    try {
      await ref.read(authRepositoryProvider).kickSession(token);
      await _loadSessions();
    } catch (e) {
      _snack('踢出失败: $e');
    }
  }

  Future<void> _kickAllOthers() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('踢出其他会话'),
        content: const Text('将登出除本机外的全部登录会话，确定？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).kickAllOtherSessions();
      await _loadSessions();
      _snack('已踢出其他会话');
    } catch (e) {
      _snack('操作失败: $e');
    }
  }

  // ── 修改密码 ──
  Future<void> _showChangePasswordDialog() async {
    final oldC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: oldC,
                obscureText: true,
                decoration: const InputDecoration(hintText: '当前密码')),
            const SizedBox(height: 8),
            TextField(
                controller: newC,
                obscureText: true,
                decoration: const InputDecoration(hintText: '新密码（≥8 位）')),
            const SizedBox(height: 8),
            TextField(
                controller: confirmC,
                obscureText: true,
                decoration: const InputDecoration(hintText: '确认新密码')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认')),
        ],
      ),
    );
    if (ok != true) return;
    if (newC.text != confirmC.text) {
      _snack('两次输入的新密码不一致');
      return;
    }
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(oldC.text, newC.text);
      _snack('密码已修改');
    } catch (e) {
      _snack('修改失败: $e');
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
